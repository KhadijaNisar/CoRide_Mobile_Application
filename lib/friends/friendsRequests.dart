import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class RequestsContent extends StatefulWidget {
  const RequestsContent({Key? key}) : super(key: key);

  @override
  State<RequestsContent> createState() => _RequestsContentState();
}

class _RequestsContentState extends State<RequestsContent> {
  late String currentUserUid;

  @override
  void initState() {
    super.initState();
    getCurrentUserUid();
  }

  void getCurrentUserUid() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      setState(() {
        currentUserUid = uid;
      });
    }
  }

  void acceptRequest(String documentId, String senderUserId) async {
    final uuid = Uuid();
    final friendshipId = uuid.v4();

    await FirebaseFirestore.instance
        .collection('All_Friends')
        .doc(currentUserUid)
        .set({});

    // Create or update the document for senderUserId in All_Friends collection
    await FirebaseFirestore.instance
        .collection('All_Friends')
        .doc(senderUserId)
        .set({});

    // Create a document in the friend collection for the current user
    await FirebaseFirestore.instance
        .collection('All_Friends')
        .doc(currentUserUid)
        .collection('friend')
        .doc(senderUserId)
        .set({
      // 'friendshipId': currentUserUid,
      'friendshipId': friendshipId,
      'friendsUserId': senderUserId,
    });

    // Create a document in the friend collection for senderUserId
    await FirebaseFirestore.instance
        .collection('All_Friends')
        .doc(senderUserId)
        .collection('friend')
        .doc(currentUserUid)
        .set({
      // 'friendshipId': currentUserUid,
      'friendshipId': friendshipId,
      'friendsUserId': currentUserUid,
    });

    // Delete the request document
    FirebaseFirestore.instance
        .collection('All_Requests')
        .doc(currentUserUid)
        .collection('request')
        .doc(documentId)
        .delete();
  }
  // void acceptRequest(String documentId) {
  //   FirebaseFirestore.instance
  //       .collection('All_Requests')
  //       .doc(currentUserUid)
  //       .collection('request')
  //       .doc(documentId)
  //       .update({'request_status': 'accept'});
  // }

  void rejectRequest(String documentId) {
    FirebaseFirestore.instance
        .collection('All_Requests')
        .doc(currentUserUid)
        .collection('request')
        .doc(documentId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('All_Requests')
            .doc(currentUserUid)
            .collection('request')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                QueryDocumentSnapshot<Object?> document =
                    snapshot.data!.docs[index];
                Map<String, dynamic> requestData =
                    document.data() as Map<String, dynamic>;
                String senderUserId = requestData['senderUserId'];
                String receiverUserId = requestData['receiverUserId'];
                String requestStatus = requestData['request_status'];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(senderUserId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.hasData) {
                      Map<String, dynamic> userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      String image = userData['image'];
                      String displayName = userData['displayName'];
                      String phoneNumber = userData['phoneNumber'];

                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(image),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Text('$displayName'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$phoneNumber'),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => acceptRequest(
                                        document.id, senderUserId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0XFF08B783),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Accept',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => rejectRequest(document.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Reject',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            // Handle tapping on the card if needed
                          },
                          onLongPress: () {
                            // Handle long press on the card if needed
                          },
                        ),
                      );
                    }

                    return SizedBox(); // Return an empty container if user data is loading
                  },
                );
              },
            );
          }

          return Center(
            child: Text('No requests found.'),
          );
        },
      ),
    );
  }
}
