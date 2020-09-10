import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fusetestapp/config/appConfig.dart' as config;
import 'package:multi_image_picker/multi_image_picker.dart';

class AddPost extends StatefulWidget {
  @override
  _AddPostState createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  final TextEditingController textPost = new TextEditingController();
  final TextEditingController textCameraCaption = new TextEditingController();
  final TextEditingController textGalleryCaption = new TextEditingController();
  String cameraImageUrl;
  List<Asset> images = List<Asset>();
  List<String> imageUrls = <String>[];
  String _error = 'No Error Detected';
  bool isLoading = false;

  final FocusNode focusNodeText = new FocusNode();
  final FocusNode focusNodeGalleryCap = new FocusNode();

  //upload Images

  void uploadGalleryImages(String caption) {
    for (var imageFilee in images) {
      print("imagesfiles:$imageFilee");
      postImage(imageFilee).then((downloadUrl) {
        imageUrls.add(downloadUrl.toString());
        if (imageUrls.length == images.length) {
          onPostData('', 2, caption, imageUrls);
        }
      }).catchError((err) {
        print(err);
      });
    }
  }

  void onPostData(
      String content, int type, String caption, List<String> url) async {
    var rng = new Random();
    var code = rng.nextInt(900000) + 100000;

    // type: 0 = text, 1 = image, 2 = multi image,

    textPost.clear();
    textCameraCaption.clear();
    textGalleryCaption.clear();
    focusNodeText.unfocus();
    focusNodeGalleryCap.unfocus();

    var documentReference =
        Firestore.instance.collection('Posts').document(code.toString());

    Firestore.instance.runTransaction((transaction) async {
      await transaction.set(
        documentReference,
        {
          'userId': '12',
          'postId': code.toString(),
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'content': content,
          'caption': caption,
          'type': type,
          'urls': url,
        },
      );
    });
    setState(() {});

    Fluttertoast.showToast(msg: 'Post Uploaded Successfully !!');
    setState(() {
      isLoading = false;
      images = [];
      imageUrls = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
      ),
      body: mainContent(context),
    );
  }

  Widget mainContent(context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        images.length != 0
            ? getGalleryPhoto(context)
            : Container(
                margin: EdgeInsets.only(bottom: 65),
                child: SingleChildScrollView(
                  child: Container(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: TextField(
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(color: Colors.black, fontSize: 20.0),
                        controller: textPost,
                        focusNode: focusNodeText,
                        decoration: new InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintText: "What's on your mind?",
                          hintStyle: TextStyle(color: Colors.grey),
                          contentPadding: EdgeInsets.all(5.0),
                        ),
                        textAlign: TextAlign.start,
                        autofocus: false,
                      ),
                    ),
                  ),
                ),
              ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FlatButton(
                    highlightColor: Colors.green,
                    minWidth: config.App(context).appWidth(40),
                    onPressed: () {
                      validInputs();
                    },
                    color: Colors.lightBlue,
                    shape: StadiumBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Post',
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.photo,
                      size: 28,
                      color: Colors.lightBlue,
                    ),
                    onPressed: () {
                      loadAssets();
                    },
                  )
                ],
              ),
            ),
          ),
        ),
        buildLoading(),
      ],
    );
  }

  Widget getGalleryPhoto(context) {
    return Container(
      margin: EdgeInsets.only(bottom: 65),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: TextField(
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(color: Colors.black, fontSize: 18.0),
                  controller: textGalleryCaption,
                  focusNode: focusNodeGalleryCap,
                  decoration: new InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: "Say Something About Image",
                    hintStyle: TextStyle(color: Colors.grey),
                    contentPadding: EdgeInsets.all(5.0),
                  ),
                  textAlign: TextAlign.start,
                  autofocus: false,
                ),
              ),
            ),
            buildGridView(),
          ],
        ),
      ),
    );
  }

  //Loading Widget
  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.lightBlue)),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  void validInputs() {
    if (images.length != 0) {
      focusNodeGalleryCap.unfocus();
      setState(() {
        this.isLoading = true;
      });
      uploadGalleryImages(textGalleryCaption.text);
    } else if (textPost.text.trim() != '') {
      setState(() {
        this.isLoading = true;
      });
      onPostData(textPost.text, 0, '', null);
    } else {
      Fluttertoast.showToast(msg: 'Nothing to Post');
    }
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = List<Asset>();
    String error = 'No Error Detected';
    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 10,
        enableCamera: true,
        selectedAssets: images,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarColor: "#abcdef",
          actionBarTitle: "Upload Image",
          allViewTitle: "All Photos",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",

        ),
      );
      print(resultList.length);
      print((await resultList[0].getThumbByteData(122, 100)));
      print((await resultList[0].getByteData()));
      print((await resultList[0].metadata));
    } on Exception catch (e) {
      error = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    setState(() {
      images = resultList;
      _error = error;
    });
  }

  //Show Images From Picker
  Widget buildGridView() {
    return Container(
        height: images.length <= 2
            ? config.App(context).appHeight(50)
            : config.App(context).appHeight(75),
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: images.length <= 2 ? 1 : 3,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 0.0),
          itemBuilder: (BuildContext context, int index) {
            Asset asset = images[index];
            return Container(
              margin: EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                      color: Color.fromARGB(80, 0, 0, 0),
                      blurRadius: 5.0,
                      offset: Offset(5.0, 5.0))
                ],
              ),
              child: ClipRRect(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                borderRadius: BorderRadius.circular(20.0),
                child: AssetThumb(
                  asset: asset,
                  width: 300,
                  height: 300,
                ),
              ),
            );
          },
        ));
  }

  // Add Images to Firebase Storage and get ImageUrl Back
  Future<dynamic> postImage(Asset imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask =
        reference.putData((await imageFile.getByteData()).buffer.asUint8List());
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    print(storageTaskSnapshot.ref.getDownloadURL());
    return storageTaskSnapshot.ref.getDownloadURL();
  }
}
