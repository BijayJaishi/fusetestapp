import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fusetestapp/config/appconfig.dart' as config;
import 'package:fusetestapp/src/screens/AddPost.dart';
import 'package:fusetestapp/src/screens/EditPost.dart';
import 'package:fusetestapp/src/screens/FullPhoto.dart';

class MyApp extends StatelessWidget {
  DateTime currentBackPressTime;
  var length;

  List<Choice> choices = const <Choice>[
    const Choice(title: 'Edit Post', icon: Icons.edit),
  ];

  onItemMenuPress(choice) {
    if (choice.title == 'Edit Post') {}
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: config.Colors().secondDarkColor(1),
      appBar: AppBar(
        title: Text('My facebook'),
        centerTitle: true,
      ),
      body: WillPopScope(
        child: SafeArea(child: _buildMainContent(context)),
        onWillPop: onWillPop,
      ),
    );
  }

  _buildMainContent(context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildListDelegate([
            _buildListItem(context),
          ]),
        )
      ],
    );
  }

  Widget _buildListItem(context) {
    return Column(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 10.0, left: 7, right: 7),
          padding: const EdgeInsets.all(7.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                  width: 55.0,
                  height: 55.0,
                  decoration: new BoxDecoration(
                      shape: BoxShape.circle,
                      image: new DecorationImage(
                        fit: BoxFit.cover,
                        image: new AssetImage("assets/Bijay.JPG"),
                      ))),
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddPost()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Whats on Your mind?',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance
              .collection('Stories')
              .document('12')
              .collection('12')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                  child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.lightBlue)));
            } else {
              length = snapshot.data.documents.length;
              if (length == 0) {
                return Container(
                  margin: EdgeInsets.all(10),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        "No any Post ! Please Upload Some Posts",
                        style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              } else {
                return ListView.builder(
                  padding: EdgeInsets.only(top: 3.0),
                  itemBuilder: (context, index) => getPostCard(
                      index, snapshot.data.documents[index], context),
                  itemCount: snapshot.data.documents.length,
                  shrinkWrap: true,
                  // todo comment this out and check the result
                  physics:
                      ClampingScrollPhysics(), // todo comment this out and check the result
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget getPostCard(index, DocumentSnapshot document, context) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0, left: 7, right: 7, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7.0, left: 7),
                child: Row(
                  children: [
                    Container(
                        width: 55.0,
                        height: 55.0,
                        decoration: new BoxDecoration(
                            shape: BoxShape.circle,
                            image: new DecorationImage(
                              fit: BoxFit.cover,
                              image: new AssetImage("assets/Bijay.JPG"),
                            ))),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Bijay Jaishi',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditPost(
                                document['type'],
                                document['content'],
                                document['caption'],
                                document['postId'],
                                document['urls'])));
                  })
              // PopupMenuButton<Choice>(
              //   onSelected: onItemMenuPress,
              //   itemBuilder: (BuildContext context) {
              //     return choices.map((Choice choice) {
              //       return PopupMenuItem<Choice>(
              //           value: choice,
              //           child: Row(
              //             children: <Widget>[
              //               Icon(
              //                 choice.icon,
              //                 color: Colors.black,
              //               ),
              //               Container(
              //                 width: 10.0,
              //               ),
              //               Text(
              //                 choice.title,
              //                 style: TextStyle(color: Colors.black),
              //               ),
              //             ],
              //           ));
              //     }).toList();
              //   },
              // ),
            ],
          ),
          Divider(
            color: Colors.grey,
            thickness: 1.5,
          ),
          document['type'] == 0
              ? Padding(
                  padding: const EdgeInsets.only(
                      top: 4.0, left: 10, right: 10, bottom: 10),
                  child: Text(
                    document['content'],
                  ),
                )
              // : (document['type'] == 1)
              //     ? Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           document['caption'] != ''
              //               ? Container(
              //                   child: Padding(
              //                     padding: const EdgeInsets.only(
              //                         top: 4.0,
              //                         left: 10,
              //                         right: 10,
              //                         bottom: 10),
              //                     child: Text(
              //                       document['caption'],
              //                     ),
              //                   ),
              //                 )
              //               : Container(),
              //           Container(
              //             child: FlatButton(
              //               child: Material(
              //                 child: CachedNetworkImage(
              //                   placeholder: (context, url) => Center(
              //                     child: Container(
              //                       child: CircularProgressIndicator(
              //                         valueColor: AlwaysStoppedAnimation<Color>(
              //                             Colors.lightBlue),
              //                       ),
              //                       width: 200.0,
              //                       height: 200.0,
              //                       padding: EdgeInsets.all(70.0),
              //                       decoration: BoxDecoration(
              //                         color: Colors.transparent,
              //                         borderRadius: BorderRadius.all(
              //                           Radius.circular(8.0),
              //                         ),
              //                       ),
              //                     ),
              //                   ),
              //                   errorWidget: (context, url, error) => Material(
              //                     child: Image.asset(
              //                       'assets/img_not_available.jpeg',
              //                       width: double.infinity,
              //                       height: 250,
              //                       fit: BoxFit.cover,
              //                     ),
              //                     borderRadius: BorderRadius.all(
              //                       Radius.circular(8.0),
              //                     ),
              //                     clipBehavior: Clip.hardEdge,
              //                   ),
              //                   imageUrl: document['content'],
              //                   height: 250,
              //                   width: double.infinity,
              //                   fit: BoxFit.cover,
              //                 ),
              //                 borderRadius:
              //                     BorderRadius.all(Radius.circular(8.0)),
              //                 clipBehavior: Clip.hardEdge,
              //               ),
              //               onPressed: () {
              //                 Navigator.push(
              //                     context,
              //                     MaterialPageRoute(
              //                         builder: (context) =>
              //                             FullPhoto(url: document['content'])));
              //               },
              //               padding: EdgeInsets.only(
              //                   bottom: 3, left: 3, right: 3, top: 2),
              //             ),
              //           )
              //         ],
              //       )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    document['caption'] != ''
                        ? Container(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 4.0, left: 10, right: 10, bottom: 10),
                              child: Text(
                                document['caption'],
                              ),
                            ),
                          )
                        : Container(),
                    Container(
                      width: config.App(context).appWidth(100),
                      height: document['urls'].length <= 2
                          ? config.App(context).appWidth(50)
                          : config.App(context).appWidth(96),
                      child: GridView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: document['urls'].length >= 4
                                  ? 4
                                  : document['urls'].length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 4.0,
                                      mainAxisSpacing: 4.0),
                              itemBuilder: (BuildContext context, int index) {
                                return Container(
                                  child: FlatButton(
                                    child: Material(
                                      child: CachedNetworkImage(
                                        placeholder: (context, url) => Center(
                                          child: Container(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.lightBlue),
                                            ),
                                            width: 200.0,
                                            height: 200.0,
                                            padding: EdgeInsets.all(70.0),
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(8.0),
                                              ),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Material(
                                          child: Image.asset(
                                            'assets/img_not_available.jpeg',
                                            width: double.infinity,
                                            height: 250,
                                            fit: BoxFit.cover,
                                          ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8.0),
                                          ),
                                          clipBehavior: Clip.hardEdge,
                                        ),
                                        imageUrl: document['urls'][index],
                                        height: 250,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(8.0)),
                                      clipBehavior: Clip.hardEdge,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => FullPhoto(
                                                  url: document['urls']
                                                      [index])));
                                    },
                                    padding: EdgeInsets.only(
                                        bottom: 3, left: 3, right: 3, top: 2),
                                  ),
                                );
                                // return Card(
                                //     child: Image.network(document['urls'][index]));
                              },
                            )

                    ),
                  ],
                )
        ],
      ),
    );
  }

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(
        msg: "Press Again To Exit",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.lightBlue,
        timeInSecForIos: 1,
        textColor: Colors.white,
      );
      return Future.value(false);
    }
    return Future.value(true);
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}
