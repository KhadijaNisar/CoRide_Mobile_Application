import 'package:flutter/material.dart';
import 'package:hitchify/home/driver_home.dart';
import 'package:hitchify/home/home_screen.dart';
import 'package:intl/intl.dart';
import 'package:hitchify/chat/user_tile.dart';
import 'package:hitchify/chat/chat_page.dart';
import 'package:hitchify/firebase_services/chat_services.dart';
import 'package:hitchify/firebase_services/firebase_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

import '../home/animated_downbar.dart';

class HomePage extends StatefulWidget {
  final String userType;

  HomePage({required this.userType});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ChatService _chatService = ChatService();
  final FirebaseAuthService _auth = FirebaseAuthService();

  @override
  void initState() {
    super.initState();
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
      // Navigator.push(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF66b899),
        title: Text("Messages"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.userType == 'passenger') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            } else if (widget.userType == 'driver') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => driverHome()),
              );
            }
          },
        ),
      ),
      body: _buildUserList(),
      bottomNavigationBar: AnimatedDownBar(
        userType: 'passenger',
        screenNo: 2,
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text("Error");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading...");
        }

        List<Map<String, dynamic>> users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> userData = users[index];
            return _buildUserListItem(userData, context);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    if (userData["uid"] != _auth.getCurrentUser()!.uid) {
      return StreamBuilder(
        stream: _chatService.getMessages(
            _auth.getCurrentUser()!.uid, userData["uid"]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error");
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading...");
          }

          QuerySnapshot<Map<String, dynamic>> messagesSnapshot =
          snapshot.data as QuerySnapshot<Map<String, dynamic>>;

          if (messagesSnapshot.docs.isNotEmpty) {
            Map<String, dynamic> lastMessage =
            messagesSnapshot.docs.last.data();
            String message = lastMessage["message"];
            Timestamp timestamp = lastMessage["timestamp"];
            DateTime dateTime = timestamp.toDate();
            String formattedTime = DateFormat.Hm().format(dateTime);

            return UserTile(
              image: userData["image"],
              name: userData["displayName"],
              message: _truncateMessage(message),
              time: formattedTime,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => chatPage(
                      displayName: userData["displayName"],
                      image: userData["image"],
                      receiverEmail: userData["email"],
                      receiverID: userData["uid"],
                    ),
                  ),
                );
              },
            );
          } else {
            return UserTile(
              image: userData["image"],
              name: userData["displayName"],
              message: "No messages yet",
              time: "",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => chatPage(
                      displayName: userData["displayName"],
                      image: userData["image"],
                      receiverEmail: userData["email"],
                      receiverID: userData["uid"],
                    ),
                  ),
                );
              },
            );
          }
        },
      );
    } else {
      return Container();
    }
  }

  String _truncateMessage(String message) {
    const maxLength = 30;
    if (message.length > maxLength) {
      return message.substring(0, maxLength) + '...';
    } else {
      return message;
    }
  }
}

// // ignore_for_file: unused_field
// import 'package:hitchify/home/driver_home.dart';
// import 'package:hitchify/home/home_screen.dart';
// import 'package:intl/intl.dart';
// import 'package:hitchify/chat/user_tile.dart';
// import 'package:hitchify/chat/chat_page.dart';
// import 'package:hitchify/firebase_services//chat_services.dart';
// import 'package:hitchify/firebase_services/firebase_services.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class HomePage extends StatelessWidget {
//   final String userType; // Add userType parameter to the constructor
//
//   HomePage({required this.userType});
//   // HomePage({super.key});
//
//   //chat and auth service
//   final ChatService _chatService = ChatService();
//
//   // final AuthService _authService = AuthService();
//   final FirebaseAuthService _auth = FirebaseAuthService();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // backgroundColor: Colors.grey,
//       appBar: AppBar(
//         backgroundColor: Color(0xFF66b899),
//         title: Text("Messages"),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back,color: Colors.white),
//           onPressed: () {
//             if (userType == 'passenger') {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => HomeScreen()),
//               );
//             } else if (userType == 'driver') {
//               // print("Type: $widget.userType");
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => driverHome()),
//               );
//             }
//           },
//         ),
//       ),
//       // drawer: const MyDrawer(),
//
//       body: _buildUserList(),
//     );
//   }
//
//   // Build a list of users except for the current logged in user
//   Widget _buildUserList() {
//     return StreamBuilder<List<Map<String, dynamic>>>(
//       stream: _chatService.getUsersStream(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Text("Error");
//         }
//
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Text("Loading...");
//         }
//
//         List<Map<String, dynamic>> users = snapshot.data!;
//         return ListView.builder(
//           itemCount: users.length,
//           itemBuilder: (context, index) {
//             Map<String, dynamic> userData = users[index];
//             return _buildUserListItem(userData, context);
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildUserListItem(
//       Map<String, dynamic> userData, BuildContext context) {
//     // Display all users except the current user
//     if (userData["uid"] != _auth.getCurrentUser()!.uid) {
//       return StreamBuilder(
//         stream: _chatService.getMessages(
//             _auth.getCurrentUser()!.uid, userData["uid"]),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Text("Error");
//           }
//
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Text("Loading...");
//           }
//
//           QuerySnapshot<Map<String, dynamic>> messagesSnapshot =
//               snapshot.data as QuerySnapshot<Map<String, dynamic>>;
//
//           if (messagesSnapshot.docs.isNotEmpty) {
//             // Get the last message and its timestamp
//             Map<String, dynamic> lastMessage =
//                 messagesSnapshot.docs.last.data();
//             String message = lastMessage["message"];
//             Timestamp timestamp = lastMessage["timestamp"];
//             DateTime dateTime = timestamp.toDate();
//             String formattedTime = DateFormat.Hm().format(dateTime);
//
//             return UserTile(
//               image: userData["image"],
//               name: userData["displayName"],
//               message: _truncateMessage(message),
//               time: formattedTime,
//               onTap: () {
//                 // Tapped on a user, go to chat page
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => chatPage(
//                       displayName: userData["displayName"],
//                       image: userData["image"],
//                       receiverEmail: userData["email"],
//                       receiverID: userData["uid"],
//                     ),
//                   ),
//                 );
//               },
//             );
//           } else {
//             return UserTile(
//               image: userData["image"],
//               name: userData["displayName"],
//               message: "No messages yet",
//               time: "",
//               onTap: () {
//                 // Tapped on a user, go to chat page
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => chatPage(
//                       displayName: userData["displayName"],
//                       image: userData["image"],
//                       receiverEmail: userData["email"],
//                       receiverID: userData["uid"],
//                     ),
//                   ),
//                 );
//               },
//             );
//           }
//         },
//       );
//     } else {
//       return Container();
//     }
//   }
//
//   String _truncateMessage(String message) {
//     // Limit the message to a certain number of characters
//     const maxLength = 30;
//     if (message.length > maxLength) {
//       return message.substring(0, maxLength) + '...';
//     } else {
//       return message;
//     }
//   }
// }
