import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fusetestapp/config/appConfig.dart' as config;
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

class AddPost extends StatefulWidget {

  @override
  _AddPostState createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  final TextEditingController textPost = new TextEditingController();
  final TextEditingController textCameraCaption = new TextEditingController();
  final TextEditingController textGalleryCaption = new TextEditingController();
  File cameraImageFile;
  String cameraImageUrl;
  List<Asset> images = List<Asset>();
  List<String> imageUrls = <String>[];
  String _error = 'No Error Detected';
  bool isLoading = false;

  Future getCameraImage() async {
    setState(() {
      isLoading = true;
    });
    cameraImageFile = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 72);

    if (cameraImageFile != null) {
      setState(() {
        isLoading = false;
      });

      //   // uploadCameraFile(caption);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _clear() {
    setState(() => cameraImageFile = null);
  }

  Future uploadCameraFile(String caption) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference =
        FirebaseStorage.instance.ref().child('StoryImages/Camera/$fileName');
    StorageUploadTask uploadTask = reference.putFile(cameraImageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      cameraImageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        onPostData(cameraImageUrl, 1, caption, null);
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }

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

  void onPostData(String content, int type, String caption, List<String> url) async {

    var rng = new Random();
    var code = rng.nextInt(900000) + 100000;

    // type: 0 = text, 1 = image, 2 = multi image,
    textPost.clear();
    textCameraCaption.clear();
    textGalleryCaption.clear();

    var documentReference = Firestore.instance
        .collection('Stories')
        .document('12')
        .collection('12')
        .document(code.toString());

    Firestore.instance.runTransaction((transaction) async {
      await transaction.set(
        documentReference,
        {
          'userId': '12',
          'postId':code.toString(),
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
      cameraImageFile = null;
      images = [];
      imageUrls = [];
    });
    // getData();
//      Navigator.push(context, MaterialPageRoute(builder: (context) => ViewStory(storyUrl)));
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
    print('camera:$cameraImageFile');
    print('camera2:$images');
    print('length:${images.length}');
    print('text:${textPost.text}');
    return Stack(
      fit: StackFit.expand,
      children: [
        cameraImageFile != null
            ? getCameraPhoto(context)
            : images.length != 0
                ? getGalleryPhoto(context)
                : Container(
                    margin: EdgeInsets.only(bottom: 65),
                    // padding: EdgeInsets.only(bottom: 15),
                    child: SingleChildScrollView(
                      child: Container(
                        // height: config.App(context).appHeight(80),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: TextField(
                            maxLines: null,
                            // expands: true,
                            keyboardType: TextInputType.multiline,
                            style:
                                TextStyle(color: Colors.black, fontSize: 20.0),
                            controller: textPost,
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
                    minWidth: config.App(context).appWidth(40),
                    onPressed: () {
                      validInputs();
                    },
                    // padding: EdgeInsets.symmetric(vertical: 14),
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
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          size: 28,
                          color: Colors.lightBlue,
                        ),
                        onPressed: () {
                          getCameraImage();
                        },
                      ),
                      SizedBox(
                        width: 15,
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
                      ),
                    ],
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

  Widget getCameraPhoto(context) {
    print('I am here');
    return Container(
      margin: EdgeInsets.only(bottom: 65),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              // height: config.App(context).appHeight(80),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: TextField(
                  maxLines: null,
                  // expands: true,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(color: Colors.black, fontSize: 18.0),
                  controller: textCameraCaption,
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
            Container(
              height: config.App(context).appHeight(70),
              margin: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
//                              border: Border.all(width : 10.0,color: Colors.transparent),
                  borderRadius: BorderRadius.circular(0.0),
                  boxShadow: [
                    BoxShadow(
                        color: Color.fromARGB(80, 0, 0, 0),
                        blurRadius: 5.0,
                        offset: Offset(5.0, 5.0))
                  ],
                  image: DecorationImage(
                      fit: BoxFit.cover, image: FileImage(cameraImageFile))),
              width: MediaQuery.of(context).size.width,
              child: Container(
                margin: EdgeInsets.only(top: 5.0, right: 5),
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => _clear(),
                  child: CircleAvatar(
                    radius: 15,
                    child: Icon(
                      Icons.clear,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getGalleryPhoto(context) {
    return Container(
      margin: EdgeInsets.only(bottom: 65),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              // height: config.App(context).appHeight(80),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: TextField(
                  maxLines: null,
                  // expands: true,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(color: Colors.black, fontSize: 18.0),
                  controller: textGalleryCaption,
                  decoration: new InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: "Say Something About Images",
                    hintStyle: TextStyle(color: Colors.grey),
                    contentPadding: EdgeInsets.all(5.0),
                  ),
                  textAlign: TextAlign.start,
                  autofocus: false,
                ),
              ),
            ),
            Container(
                height: config.App(context).appHeight(75),
                child: buildGridView()),
          ],
        ),
      ),
    );
  }

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

    if(cameraImageFile != null){
      setState(() {
        this.isLoading = true;
      });
      uploadCameraFile(textCameraCaption.text);
    }else if(images.length !=0){
      setState(() {
        this.isLoading = true;
      });
      uploadGalleryImages(textGalleryCaption.text);
    }else if(textPost.text.trim()!= ''){
      setState(() {
        this.isLoading = true;
      });
      onPostData(textPost.text, 0, '', null);
    }else{
      Fluttertoast.showToast(msg: 'Nothing to Post');
    }
    //
    // if (textPost.text.trim() != '' && cameraImageFile == null) {
    //   print('I am text');
    //   setState(() {
    //     this.isLoading = true;
    //   });
    //   onPostData(textPost.text, 0, '', null);
    // } else if (cameraImageFile != null && textPost.text.trim() == '') {
    //   print('I am camera');
    //   setState(() {
    //     this.isLoading = true;
    //   });
    //   uploadCameraFile(textCameraCaption.text);
    // } else if (images != [] &&
    //
    //     (cameraImageFile == null && textPost.text.trim() == '')) {
    //   print('I am gallery');
    //   setState(() {
    //     this.isLoading = true;
    //   });
    //   uploadGalleryImages(textGalleryCaption.text);
    // } else {
    //   print('I am nothing');
    //   Fluttertoast.showToast(msg: 'Nothing to Post');
    // }
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = List<Asset>();
    String error = 'No Error Detected';
    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 10,
        // enableCamera: true,
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
    print('images:$images');
  }

  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: images.length == 2 || images.length == 1 ? 1 : 2,
      scrollDirection: Axis.vertical,
      children: List.generate(images.length, (index) {
        Asset asset = images[index];
        return Card(
          child: AssetThumb(
            asset: asset,
            width: 300,
            height: 300,
          ),
        );
      }),
    );
  }

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
