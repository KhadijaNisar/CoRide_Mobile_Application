import 'package:flutter/material.dart';
import 'package:hitchify/core/app_export.dart';
import 'package:hitchify/friends/addFriends.dart';
import 'package:hitchify/friends/friendsList.dart';
import 'package:hitchify/friends/friendsRequests.dart';
import 'package:hitchify/home/home_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:hitchify/home/animated_downbar.dart';

import '../chat/home_page.dart';
import '../home/driver_home.dart';

class MyFriendsScreen extends StatefulWidget {
  final String userType; //
  final int screenNo;// Add userType parameter to the constructor
  MyFriendsScreen({required this.userType,required this.screenNo});
  @override
  _MyFriendsScreenState createState() => _MyFriendsScreenState();
}

class _MyFriendsScreenState extends State<MyFriendsScreen> {
  int _selectedIndex = 0;
  int _requestCount = 0;

  @override
  void initState() {
    super.initState();
    _requestContactsPermission();
    fetchRequestCount();
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (widget.userType == 'passenger') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),(route)=>false
      );
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => HomeScreen()),
      // );
    } else if (widget.userType == 'driver') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => driverHome()),(route)=>false
      );
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => driverHome()),
      // );
    }
    return true;
  }

  void fetchRequestCount() async {
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot requestSnapshot = await FirebaseFirestore.instance
        .collection('All_Requests')
        .doc(currentUserUid)
        .collection('request')
        .get();

    setState(() {
      _requestCount = requestSnapshot.size;
    });
  }

  Future<void> _requestContactsPermission() async {
    final status = await Permission.contacts.request();
    print('Permission status: $status');
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDialog();
    } else if (status.isGranted) {
      print('Contacts permission granted');
    }
    print('Permission status: $status');
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contacts Permission'),
          content: Text('Please grant permission to access contacts.'),
          backgroundColor:
          const Color(0xff52c498), // Change background color here
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
              },
              child: Text(
                'No',
                style: TextStyle(color: Colors.black),
              ), // Option to deny permission
            ),
            TextButton(
              onPressed: () async {
                // Request permission again
                final status = await Permission.contacts.request();
                await Future.delayed(Duration(seconds: 1));
                if (status.isGranted) {
                  print('Contacts permission granted');
                  setState(() {});
                } else {
                  print('Contacts permission denied');
                }
                Navigator.of(context).pop();
              },
              child: Text(
                'Yes',
                style: TextStyle(color: Colors.black),
              ), // Option to grant permission
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Friends",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (widget.userType == 'passenger') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),(route)=>false
                );
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (context) => HomeScreen()),
                // );
              } else if (widget.userType == 'driver') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => driverHome()),(route)=>false
                );
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (context) => driverHome()),
                // );
              }
            },
          ),
          backgroundColor: appTheme.teal500,
          bottom: TabBar(
            indicatorColor: Colors.white,
            unselectedLabelColor: Colors.black,
            labelColor: Colors.white,
            tabs: [
              Tab(
                icon: Icon(Icons.people),
                text: 'Friends',
              ),
              Tab(
                icon: Stack(
                  children: [
                    Icon(Icons.handshake_outlined),
                    if (_requestCount > 0)
                      Positioned(
                        right: 0,
                        left: 10,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _requestCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                text: 'Requests',
              ),
              Tab(icon: Icon(Icons.person_add), text: 'Add Friends'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FriendsContent(),
            RequestsContent(),
            AddFriends(),
          ],
        ),
        bottomNavigationBar: AnimatedDownBar(
          userType: 'passenger',
          screenNo: widget.screenNo,
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:hitchify/friends/addFriends.dart';
// import 'package:hitchify/friends/friendsList.dart';
// import 'package:hitchify/friends/friendsRequests.dart';
// import 'package:hitchify/home/home_screen.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import '../chat/home_page.dart';
// import '../home/driver_home.dart';
//
// class MyFriendsScreen extends StatefulWidget {
//   final String userType; // Add userType parameter to the constructor
//   MyFriendsScreen({required this.userType});
//   @override
//   _MyFriendsScreenState createState() => _MyFriendsScreenState();
// }
//
// class _MyFriendsScreenState extends State<MyFriendsScreen> {
//   int _selectedIndex = 0;
//   int _requestCount = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _requestContactsPermission();
//     fetchRequestCount();
//   }
//
//   void fetchRequestCount() async {
//     String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
//     QuerySnapshot requestSnapshot = await FirebaseFirestore.instance
//         .collection('All_Requests')
//         .doc(currentUserUid)
//         .collection('request')
//         .get();
//
//     setState(() {
//       _requestCount = requestSnapshot.size;
//     });
//   }
//
//   Future<void> _requestContactsPermission() async {
//     final status = await Permission.contacts.request();
//     print('Permission status: $status');
//     if (status.isDenied || status.isPermanentlyDenied) {
//       _showPermissionDialog();
//     } else if (status.isGranted) {
//       print('Contacts permission granted');
//     }
//     print('Permission status: $status');
//   }
//
//   void _showPermissionDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Contacts Permission'),
//           content: Text('Please grant permission to access contacts.'),
//           backgroundColor:
//               const Color(0xff52c498), // Change background color here
//           actions: <Widget>[
//             TextButton(
//               onPressed: () async {
//                 Navigator.of(context).pop();
//               },
//               child: Text(
//                 'No',
//                 style: TextStyle(color: Colors.black),
//               ), // Option to deny permission
//             ),
//             TextButton(
//               onPressed: () async {
//                 // Request permission again
//                 // bool isGranted = await Permission.contacts.request().isGranted;
//                 final status = await Permission.contacts.request();
//                 // Check if permission is granted
//                 await Future.delayed(Duration(seconds: 1));
//                 if (status.isGranted) {
//                   print('Contacts permission granted');
//                   setState(() {});
//                 } else {
//                   print('Contacts permission denied');
//                 }
//                 Navigator.of(context).pop();
//               },
//               child: Text(
//                 'Yes',
//                 style: TextStyle(color: Colors.black),
//               ), // Option to grant permission
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       initialIndex: 0,
//       length: 3,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text("Friends",
//               style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white)),
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () {
//               if (widget.userType == 'passenger') {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => HomeScreen()),
//                 );
//               } else if (widget.userType == 'driver') {
//                 // print("Type: $widget.userType");
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => driverHome()),
//                 );
//               }
//             },
//           ),
//           backgroundColor: Colors.green,
//           bottom: TabBar(
//             // isScrollable: true,
//             indicatorColor: Colors.white,
//             unselectedLabelColor: Colors.black,
//             labelColor: Colors.white,
//             // labelPadding: EdgeInsets.symmetric(horizontal: 30),
//             tabs: [
//               Tab(
//                 icon: Icon(Icons.people),
//                 text: 'Friends',
//               ),
//               Tab(
//                 icon: Stack(
//                   children: [
//                     Icon(Icons.handshake_outlined),
//                     if (_requestCount > 0)
//                       Positioned(
//                         right: 0,
//                         left:
//                             10, // Adjust this value to move the container to the desired position
//                         top: 0,
//                         child: Container(
//                           padding: EdgeInsets.all(2),
//                           decoration: BoxDecoration(
//                             color: Colors.red,
//                             shape: BoxShape.circle,
//                           ),
//                           constraints: BoxConstraints(
//                             minWidth: 16,
//                             minHeight: 16,
//                           ),
//                           child: Text(
//                             _requestCount.toString(),
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 text: 'Requests',
//               ),
//               Tab(icon: Icon(Icons.person_add), text: 'Add Friends'),
//             ],
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             FriendsContent(),
//             RequestsContent(),
//             AddFriends(),
//           ],
//         ),
//       ),
//     );
//   }
// }
