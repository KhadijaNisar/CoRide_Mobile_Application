import 'package:hitchify/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  //get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String CurrentUserEmail = '';

  //get user stream
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    final String currentUserID = _auth.currentUser!.uid;

    return _firestore
        .collection("All_Friends")
        .doc(currentUserID)
        .collection("friend")
        .snapshots()
        .asyncMap<List<Map<String, dynamic>>>((snapshot) async {
      List<String> friendIDs = [];
      for (final doc in snapshot.docs) {
        friendIDs.add(doc.id);
      }

      List<DocumentSnapshot<Map<String, dynamic>>> userDocs = [];
      for (final friendID in friendIDs) {
        DocumentSnapshot<Map<String, dynamic>> userDoc =
            await _firestore.collection("users").doc(friendID).get();
        if (userDoc.exists) {
          userDocs.add(userDoc);
        }
      }
      print("User Docs $userDocs");

      List<Map<String, dynamic>> users =
          userDocs.map((doc) => doc.data()!).toList();
      return users;
    });
  }
  // Stream<List<Map<String, dynamic>>> getUsersStream() {
  //   return _firestore.collection("users").snapshots().map((snapshot) {
  //     return snapshot.docs.map((doc) {
  //       //go through each individual user
  //       final user = doc.data();
  //
  //       //return user
  //       return user;
  //     }).toList();
  //   });
  // }

  //send message
  Future<void> sendMessage(String receiverID, String message) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      final String currentUserID = currentUser.uid;
      print("current User ID : $currentUserID");

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userRef =
          firestore.collection('users').doc(currentUserID);

      userRef.get().then((DocumentSnapshot documentSnapshot) async {
        if (documentSnapshot.exists) {
          CurrentUserEmail = documentSnapshot.get('email');
          print("Current User Email : $CurrentUserEmail");
          final Timestamp timestamp = Timestamp.now();

          // Create a new message
          Message newMessage = Message(
            senderID: currentUserID,
            senderEmail: CurrentUserEmail,
            receiverID: receiverID,
            message: message,
            timestamp: timestamp,
          );

          // Construct chat room ID for the two users (sorted to ensure uniqueness)
          List<String> ids = [currentUserID, receiverID];
          ids.sort();
          String chatRoomID = ids.join('_');

          // Add new message to the database
          await _firestore
              .collection("chat_rooms")
              .doc(chatRoomID)
              .collection("messages")
              .add(newMessage.toMAp());
        } else {
          // Handle the case where currentUser is null
          print("User is not logged in");
        }
      }).catchError((error) {
        // Handle errors
      });
    } else {
      print("Document Does Not Exist");
    }
  }

//get message
  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    //construct chatroom ID for the two users
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }
}
