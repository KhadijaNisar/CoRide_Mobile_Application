// ignore_for_file: camel_case_types

// import 'dart:js';
import 'package:hitchify/chat/chat_bubble.dart';
import 'package:hitchify/chat/my_textfield.dart';
// import 'package:hitchify/firebase_services/auth/auth_service.dart';
import 'package:hitchify/firebase_services/chat_services.dart';
import 'package:hitchify/firebase_services/firebase_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class chatPage extends StatelessWidget {
  final String receiverEmail;
  final String displayName;
  final String receiverID;
  final String image;

  chatPage(
      {super.key,
      required this.receiverEmail,
      required this.receiverID,
      required this.displayName,
      required this.image});

  //text controller
  final TextEditingController _messageController = TextEditingController();

  //chat and auth services
  final ChatService _chatService = ChatService();
  // final AuthService _authService = AuthService();
  final FirebaseAuthService _auth = FirebaseAuthService();

  //send message
  void sendMessage() async {
    //if there is something inside the textfield
    if (_messageController.text.isNotEmpty) {
      //send message
      await _chatService.sendMessage(receiverID, _messageController.text);

      //clear text controller
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xEEF7F7FC),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(image),
              radius: 18, // Adjust the size as needed
            ),
            SizedBox(width: 8), // Add some spacing between the avatar and text
            Text(displayName),
          ],
        ),
        backgroundColor: Color(0xFF66b899),
      ),
      body: Column(
        children: [
          //display all messages
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildMessageList(),
            ),
          ),

          //user input
          _buildUserInput(),
        ],
      ),
    );
  }

  //build message list
  Widget _buildMessageList() {
    final ScrollController _scrollController = ScrollController();
    String senderID = _auth.getCurrentUser()!.uid;
    return StreamBuilder(
        stream: _chatService.getMessages(receiverID, senderID),
        builder: (context, snapshot) {
          //errors
          if (snapshot.hasError) {
            return const Text("Error");
          }

          //loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading ...");
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
          //return list View
          return ListView(
            controller: _scrollController,
            children: snapshot.data!.docs
                .map((doc) => _buildMessageItem(doc))
                .toList(),
          );
        });
  }

  //build message item
  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    //is current user
    bool isCurrentUser = data["senderID"] == _auth.getCurrentUser()!.uid;

    //align message to the right if sender is the current user, otherwise left
    var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
        alignment: alignment,
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ChatBubble(message: data["message"], isCurrentUser: isCurrentUser)
          ],
        ));
  }

  //build message input
  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          //textfield should take up most of the space
          Expanded(
              child: MyTextField(
                  hintText: "Type a message",
                  obscuretxt: false,
                  controller: _messageController)),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF66b899), // Set the background color to green
              shape: BoxShape
                  .circle, // Optional: You can set the shape of the container
            ),
            child: IconButton(
              onPressed: sendMessage,
              icon: Icon(Icons.send_outlined),
              color: Colors.white, // Optional: Set the color of the icon
            ),
          ),
          SizedBox(
            width: 5.0,
          ),
        ],
      ),
    );
  }
}
