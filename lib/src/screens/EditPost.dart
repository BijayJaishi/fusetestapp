import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:fusetestapp/config/appConfig.dart' as config;

import '../app.dart';
import 'FullPhoto.dart';

class EditPost extends StatefulWidget {
  final type, content, caption, code;
  final urls;

  EditPost(this.type, this.content, this.caption, this.code, this.urls);

  @override
  _EditPostState createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  TextEditingController editTextPost;
  TextEditingController editTextGalleryCaption;

  List<Asset> images = List<Asset>();
  List<String> imageUrls = <String>[];
  String _error = 'No Error Detected';
  bool isLoading = false;
  String galleryCap = '';
  String text = '';
  var picUrls = [];

  final FocusNode focusNodeText = new FocusNode();
  final FocusNode focusNodeGalleryCap = new FocusNode();

  //uploads new images with existing  images

  void uploadGalleryImages(String caption) {
    if (images.isNotEmpty) {
      var allUrl = picUrls;
      for (var imageFilee in images) {
        postImage(imageFilee).then((downloadUrl) {
          allUrl.add(downloadUrl.toString());
          if (allUrl.isNotEmpty) {
            handleUpdateData('', caption, allUrl, 2);
          } else {
            Fluttertoast.showToast(msg: 'Select Some Images');
            setState(() {
              isLoading = false;
            });
          }
        }).catchError((err) {
          print(err);
        });
      }
    } else {
      if (picUrls.isNotEmpty) {
        handleUpdateData('', caption, picUrls, 2);
      } else {
        Fluttertoast.showToast(msg: 'Select Some Images');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  //update post in firebase

  void handleUpdateData(String content, String caption, var url, type) {
    focusNodeText.unfocus();
    focusNodeGalleryCap.unfocus();

    setState(() {
      isLoading = true;
    });

    if (type == 0
        ? content != widget.content
        : (caption != widget.caption ||
            images.isNotEmpty ||
            picUrls.length != widget.urls.length)) {
      Firestore.instance
          .collection('Posts')
          .document(widget.code)
          .updateData({
        'content': content,
        'caption': caption,
        'urls': url,
        'timestamp':DateTime.now().millisecondsSinceEpoch.toString(),

      }).then((data) async {
        setState(() {
          isLoading = false;
        });

        Fluttertoast.showToast(msg: "Update success");
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (BuildContext context) => MyApp()),
                (Route<dynamic> route) => false);
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });

        Fluttertoast.showToast(msg: err.toString());
      });
    } else {
      Fluttertoast.showToast(msg: 'No any changes to Update');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readLocal();
  }

  readLocal() {
    widget.type == 0 && widget.type != 2
        ? text = widget.content ?? ''
         :galleryCap = widget.caption ?? '';
    if (widget.type == 2) {
      picUrls =
          List.generate(widget.urls.length, (index) => widget.urls[index]);
    }

    editTextPost = new TextEditingController(text: text);
    editTextGalleryCaption = new TextEditingController(text: galleryCap);

    // Force refresh input
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Post'),
      ),
      body: mainContent(context),
    );
  }

  Widget mainContent(context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.urls != null && widget.type == 2
            ? getGalleryPhoto(context)
            : text != null
                ? Container(
                    margin: EdgeInsets.only(bottom: 65),
                    child: SingleChildScrollView(
                      child: Container(
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: TextField(
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style:
                                TextStyle(color: Colors.black, fontSize: 20.0),
                            controller: editTextPost,
                            onChanged: (value) {
                              text = value.trim();
                            },
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
                  )
                : Container(
                    child: Center(
                      child: Text('Nothing to show'),
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
                        'Save',
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                  widget.type != 0
                      ? IconButton(
                          icon: Icon(
                            Icons.photo,
                            size: 28,
                            color: Colors.lightBlue,
                          ),
                          onPressed: () {
                            loadAssets();
                          },
                        )
                      : Container()
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
                  controller: editTextGalleryCaption,
                  onChanged: (value) {
                    galleryCap = value.trim();
                  },
                  focusNode: focusNodeGalleryCap,
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
            images.isNotEmpty
                ? Column(
                    children: [
                      SizedBox(
                        height: 8,
                      ),
                      Divider(
                        thickness: 1.5,
                        color: Colors.grey,
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        'New Images',
                        style: TextStyle(color: Colors.black, fontSize: 18.0),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      buildGridView(),
                      Divider(
                        thickness: 1.5,
                        color: Colors.grey,
                      ),
                    ],
                  )
                : Container(),
            picUrls != null ? buildNewGridView() : Container,
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
    if (widget.type == 2 && (images.length != 0 || picUrls != null)) {
      setState(() {
        this.isLoading = true;
      });
      uploadGalleryImages(galleryCap);
    } else {
      if (widget.type == 0 && text != '') {
        handleUpdateData(text, '', null, 0);
      } else {
        Fluttertoast.showToast(msg: 'Post Cannot be empty');
      }
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

  // Show New Images from Picker
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

  //Show Existing Images in Post
  Widget buildNewGridView() {
    return Container(
        height: picUrls.length <= 2
            ? config.App(context).appHeight(50)
            : config.App(context).appHeight(75),
        child: GridView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: picUrls.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: picUrls.length <= 2 ? 1 : 3,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 0.0),
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FullPhoto(url: picUrls[index])));
              },
              child: Container(
                margin: EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                    border: Border.all(width: 10.0, color: Colors.transparent),
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                          color: Color.fromARGB(80, 0, 0, 0),
                          blurRadius: 5.0,
                          offset: Offset(5.0, 5.0))
                    ],
                    image: DecorationImage(
                        fit: BoxFit.cover,
                        image: CachedNetworkImageProvider(picUrls[index]))),
                width: MediaQuery.of(context).size.width,
                child: Container(
                  margin: EdgeInsets.only(top: 5.0, right: 5),
                  alignment: Alignment.topRight,
                  child: InkWell(
                    highlightColor: Colors.red,
                    onTap: () {
                      setState(() {
                        picUrls.removeAt(index);
                      });
                    },
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
            );
          },
        ));
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
