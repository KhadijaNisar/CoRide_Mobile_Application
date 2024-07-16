import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../chat/chat_page.dart';

class FriendsContent extends StatefulWidget {
  const FriendsContent({Key? key}) : super(key: key);

  @override
  State<FriendsContent> createState() => _FriendsContentState();
}

class _FriendsContentState extends State<FriendsContent> {
  late String currentUserUid; // Add this variable to store the current user's UID

  void getCurrentUserUid() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      setState(() {
        currentUserUid = uid;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUserUid();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: getFriendData(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SizedBox(
                height: 50,
                child: CircularProgressIndicator(
                  color: Color(0XFF08B783)
                ),
              ),
            );
          }
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> friend = snapshot.data![index];
                // String displayName = friend['displayName'];
                String displayName = friend['displayName'] ?? '';
                String phoneNumber = friend['phoneNumber'];
                String image = friend['image'];
                String recieverEmail = friend['email'] ?? '';
                String recieverId = friend['uid'] ?? '';
                String cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), ''); // Change the variable name

                return Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF66b899),
                        radius: 20,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(displayName),
                      subtitle: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(phoneNumber),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.call),
                            onPressed: () {
                              launch('tel:$cleanedPhoneNumber');
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.message),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      chatPage(
                                        displayName: displayName,
                                        image: image,
                                        receiverEmail: recieverEmail,
                                        receiverID: recieverId,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );

          } else {
            return Center(
              child: Text('No friends found.'),
            );
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getFriendData() async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('All_Friends')
        .doc(currentUserUid)
        .collection('friend')
        .get();

    List<String> friendUserIds = snapshot.docs.map<String>((doc) {
      Map<String, dynamic> data = doc.data();
      return data['friendsUserId'];
    }).toList();

    List<Map<String, dynamic>> friendData = [];


    for (String friendUserId in friendUserIds) {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUserId)
          .get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData = userSnapshot.data()!;
        String phoneNumber = userData['phoneNumber'];
        String displayName = userData['displayName'];
        String image = userData['image'];
        String recieverEmail = userData['email'];
        String recieverId = userData['uid'];

        Map<String, dynamic> friend = {
          'phoneNumber': phoneNumber,
          'displayName': displayName,
          'image': image,
          'recieverEmail': recieverEmail,
          'recieverId' : recieverId,
        };
      print("Friend Data: $friend");
        friendData.add(friend);
      }
    }

    return friendData;
  }


  Future<List<String>> getFriendUserIds() async {
    // Fetch the documents from the 'friend' collection within the document named after the current user's UID
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('All_Friends')
        .doc(currentUserUid)
        .collection('friend')
        .get();

    // Extract the 'friendsUserId' field from each fetched document
    List<String> friendUserIds = snapshot.docs.map<String>((doc) {
      Map<String, dynamic> data = doc.data();
      // Adjust the property name according to your document structure
      return data['friendsUserId'];
    }).toList();

    return friendUserIds;
  }
}

// import 'package:fast_contacts/fast_contacts.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:url_launcher/url_launcher.dart';
//
//
// class FriendsContent extends StatefulWidget {
//   const FriendsContent({super.key});
//
//   @override
//   State<FriendsContent> createState() => _FriendsContentState();
// }
//
//
// class _FriendsContentState extends State<FriendsContent> {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: double.infinity,
//       child: FutureBuilder(
//         future: getContacts(),
//         builder: (context,AsyncSnapshot snapshot){
//           if(snapshot.data == null) {
//               return Center(
//                 child: SizedBox(
//                   height: 50,
//                   child:CircularProgressIndicator(
//                     color: Colors.green,
//                   )
//                 ),
//               );
//           }
//           return ListView.builder(
//             itemCount: snapshot.data.length,
//               itemBuilder: (context,index){
//               Contact contact = snapshot.data[index];
//               print("Contact no: $contact.phones[0].number");
//               return Column(
//                 children: [
//                   ListTile(
//                   leading: const CircleAvatar(
//                     backgroundColor: Colors.green,
//                     radius: 20,
//                     child: Icon(Icons.person,
//                       color: Colors.white),
//                   ),
//                   title: Text(contact.displayName),
//                   subtitle: Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: [
//                       Text(contact.phones[0].number),
//                     ],
//                   ),
//                     trailing: IconButton(
//                       icon: Icon(Icons.call),
//                       onPressed: () {
//                         String phoneNumber = contact.phones[0].number.replaceAll(RegExp(r'[^0-9]'), '');
//                         launch('tel:$phoneNumber');
//                        // launch('tel://$contact.phones[0].number');
//                       },
//                     ),
//                 ),
//                   const Divider()
//                 ]
//               );
//               }
//           );
//           },
//       ),
//     );
//   }
//   Future<List<Contact>> getContacts() async{
//     bool isGranted =  await Permission.contacts.status.isGranted;
//     if(!isGranted){
//       await Permission.contacts.request().isGranted;
//     }
//     if(isGranted){
//       return await FastContacts.getAllContacts();
//     }
//     return [];
//
//   }
// }
