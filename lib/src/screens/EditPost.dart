import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:fusetestapp/config/appConfig.dart' as config;

import '../app.dart';

class EditPost extends StatefulWidget {
  final type, content, caption,code;
  final urls;

  EditPost(this.type, this.content, this.caption,this.code, this.urls);

  @override
  _EditPostState createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  TextEditingController editTextPost;
  TextEditingController editTextCameraCaption;
  TextEditingController editTextGalleryCaption;

  File cameraImageFile;
  String cameraImageUrl;
  List<Asset> images = List<Asset>();
  List<String> imageUrls = <String>[];
  String _error = 'No Error Detected';
  bool isLoading = false;
  String galleryCap = '';
  String text = '';
  String photoUrl = '';
  String cameraCap = '';

  final FocusNode focusNodeText = new FocusNode();
  final FocusNode focusNodeCameraCap = new FocusNode();
  final FocusNode focusNodeGalleryCap = new FocusNode();

  Future getCameraImage() async {
    setState(() {
      isLoading = true;
    });
    File selected = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 72);

    if (selected != null) {
      setState(() {
        cameraImageFile = selected;
        isLoading = false;
      });
    }

    // if (cameraImageFile != null) {
    //   setState(() {
    //
    //     isLoading = false;
    //   });

      //   // uploadCameraFile(caption);
    // } else {
    //   setState(() {
    //     isLoading = false;
    //   });
    // }
  }

  void _clear() {
    setState(() {
      cameraImageFile = null;
      photoUrl = null;
    });
  }

  Future uploadCameraFile(String caption) async {

    print('newphotourl:$photoUrl');
    print('newCaption:$caption');
    print('oldCaption:$caption');

    print('newCaption:$caption');
    if( photoUrl!=null && caption == widget.caption){
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Nothing to Update');
    }else if(photoUrl!=null && caption != widget.caption){
      handleUpdateData(photoUrl, caption, null, 1);
    }else{
      print('newphotourl:$photoUrl');
      print('newCaption:$caption');
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      StorageReference reference =
      FirebaseStorage.instance.ref().child('StoryImages/Camera/$fileName');
      StorageUploadTask uploadTask = reference.putFile(cameraImageFile);
      StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
      storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
        cameraImageUrl = downloadUrl;
        setState(() {
          isLoading = false;
          handleUpdateData(photoUrl!=null?photoUrl:cameraImageUrl, caption, null,1);
        });
      }, onError: (err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: 'This file is not an image');
      });
    }

  }

  void uploadGalleryImages(String caption) {
    for (var imageFilee in images) {
      print("imagesfiles:$imageFilee");
      postImage(imageFilee).then((downloadUrl) {
        imageUrls.add(downloadUrl.toString());
        if (imageUrls.length == images.length) {
          // onPostData('', 2, caption, imageUrls);
        }
      }).catchError((err) {
        print(err);
      });
    }
  }

  void handleUpdateData(String content, String caption, List<String> url,type) {
    print('Con:$content');
    print('Cap:$caption');
    focusNodeText.unfocus();
    focusNodeCameraCap.unfocus();
    focusNodeGalleryCap.unfocus();

    setState(() {
      isLoading = true;
    });

   if(content != widget.content) {
     Firestore.instance
         .collection('Stories')
         .document('12')
         .collection('12')
         .document(widget.code)
         .updateData({
       'content': content,
       'caption': caption,
       'urls': url
     }).then((data) async {
       setState(() {
         isLoading = false;
       });

       Fluttertoast.showToast(msg: "Update success");
       Navigator.push(
           context,
           MaterialPageRoute(
               builder: (context) => MyApp()));
     }).catchError((err) {
       setState(() {
         isLoading = false;
       });

       Fluttertoast.showToast(msg: err.toString());
     });
   }else{

     Fluttertoast.showToast(msg: 'Nothing to Update');
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
        : photoUrl = widget.content ?? '';
    widget.type == 2
        ? galleryCap = widget.caption ?? ''
        : cameraCap = widget.caption ?? '';

    editTextPost = new TextEditingController(text: text);
    editTextCameraCaption = new TextEditingController(text: cameraCap);
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
    print('camera:$cameraImageFile');
    print('camera2:$images');
    print('length:${images.length}');
    // print('text:${editTextPost.text}');
    print('photoUrl:$photoUrl');
    print('captionCam:$cameraCap');
    print('text:$text');
    print('captionGal:$galleryCap');
    print('urls:${widget.urls}');
    print('type:${widget.type}');
    return Stack(
      fit: StackFit.expand,
      children: [
        (photoUrl != null && widget.type == 1 )|| (cameraImageFile != null)
            ? getCameraPhoto(context)
            : widget.urls != null && widget.type == 2
                ? getGalleryPhoto(context)
                : text!=null?Container(
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
                            controller: editTextPost,
                            onChanged: (value) {
                              text = value;
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
                  ):Container(child: Center(child: Text('Nothing to show'),),),
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
                        'Save',
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
                  controller: editTextCameraCaption,
                  onChanged: (value) {
                    cameraCap = value;
                  },
                  focusNode: focusNodeCameraCap,
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
            photoUrl != null
                ? Container(
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
                            fit: BoxFit.cover,
                            image: NetworkImage(photoUrl))),
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
                  )
                : cameraImageFile!= null? Container(
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
                            fit: BoxFit.cover,
                            image: FileImage(cameraImageFile))),
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
                  ):Container(child: Text('No Image'),),
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
                  controller: editTextGalleryCaption,
                  onChanged: (value) {
                    galleryCap = value;
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
            Container(
                height: config.App(context).appHeight(75),
                child: widget.urls!=null?buildNewGridView():buildGridView()),
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

    if(widget.type == 1 &&(cameraImageFile!=null || photoUrl!=null)){
      print('m here C');
      setState(() {
        this.isLoading = true;
      });
      uploadCameraFile(cameraCap);
    }else if(images.length!=0 || widget.urls!=null){
      print('m here D');
      setState(() {
        this.isLoading = true;
      });
      uploadGalleryImages(editTextGalleryCaption.text);
    }else{
      print('m here G');
      handleUpdateData(text, '', null,0);
    }
    // if (editTextPost.text.trim() != '' && cameraImageFile == null) {
    //   // setState(() {
    //   //   this.isLoading = true;
    //   // });
    //   print('m here T');
    //   handleUpdateData(text, '', null);
    //   // onPostData(editTextPost.text, 0, '', null);
    // } else if (cameraImageFile != null && editTextPost.text.trim() == '') {
    //   print('m here C');
    //   setState(() {
    //     this.isLoading = true;
    //   });
    //   uploadCameraFile(cameraCap);
    // } else if (images != null &&
    //     (cameraImageFile == null && editTextPost.text.trim() == '')) {
    //   print('m here D');
    //   setState(() {
    //     this.isLoading = true;
    //   });
    //   uploadGalleryImages(editTextGalleryCaption.text);
    // } else {
    //   Fluttertoast.showToast(msg: 'Nothing to Post');
    // }
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
    print('images:$images');
  }

  Widget buildGridView() {
    print('am here hehe');
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

  Widget buildNewGridView() {
    print('am here');
    return GridView.count(
      crossAxisCount: widget.urls.length == 2 || widget.urls.length == 1 ? 1 : 2,
      scrollDirection: Axis.vertical,
      children: List.generate(widget.urls.length, (index) {

        return Card(
          child: Image.network(
           widget.urls[index]
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
