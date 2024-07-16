import 'package:hitchify/help&support/answer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hitchify/home/nav_bar.dart';

class helpCenter extends StatelessWidget {
  const helpCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Help Center",
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: false,
      home: help(),
    );
  }
}

class help extends StatefulWidget {
  help({super.key});

  @override
  State<help> createState() => _helpState();
}

class _helpState extends State<help> {
  String _searchQuery = '';
  List<Map<String, dynamic>> helpTopics = [
    {
      'title': 'Get Started',
      'icon': Icons.flag,
      'questions': [
        {
          'question': 'How do I create an account?',
          'answer':
              'To create an account,\n1. enter your phone number without 0 at the start.\n2. Tap Next to request an OTP,\n3. then enter the 6-digit code you receive via SMS.',
        },
        {
          'question': 'Why i don\'t received an OTP?',
          'answer':
              'OTP may not be sent to your number due to various reasons such as\n1. network issues,\n2. incorrect entry of the phone number,\n3. or temporary service disruptions.\n\nPlease ensure that you have entered your phone number correctly without any typos.\nAdditionally, check your network connection and try again.\nIf the issue persists, contact your service provider for further assistance.',
        },
      ],
    },
    {
      'title': 'Profile Settings',
      'icon': Icons.settings,
      'questions': [
        {
          'question': 'How do I change my profile picture?',
          'answer':
              'To change your profile picture,\n1. first you go to the settings menu, or select the profile section,\n2. and choose the option to change your profile picture.',
        },
        {
          'question': 'Can I change my phone number?',
          'answer':
              'Yes, you can change your phone number in the profile settings.\nSelect the option to edit your phone number and follow the instructions.',
        },
      ],
    },
    {
      'title': 'Ride',
      'icon': Icons.drive_eta_sharp,
      'questions': [
        {
          'question': 'How do I book a ride?',
          'answer':
              'To book a ride, go to the ride section in the app, select your destination, choose your ride preferences, and confirm your booking.',
        },
        {
          'question': 'What should I do if my ride is late?',
          'answer':
              'If your ride is late, please check the app for updates on your driver’s location. If needed, you can contact your driver directly.',
        },
      ],
    },
    {
      'title': 'Chat',
      'icon': Icons.chat,
      'questions': [
        {
          'question': 'How do I start a chat?',
          'answer':
              'To start a chat, go to the chat section in the app, select the contact you want to chat with, and start typing your message.',
        },
        {
          'question': 'Can I send images in chat?',
          'answer':
              'Yes, you can send images in chat. Tap the attachment icon in the chat window and select the image you want to send.',
        },
      ],
    },
    {
      'title': 'Friends',
      'icon': Icons.people,
      'questions': [
        {
          'question': 'How do I add friends?',
          'answer':
              'To add friends,\n1. go to the friends section in the app,\n2. select the tab add friends, and press add button where displaying the phone number or username of the person you want to add.',
        },
        {
          'question': 'Why can\'t I see my friends list?',
          'answer':
              'If you can\'t see your friends list, please check your internet connection and ensure that you are logged in to your account.',
        },
        {
          'question': 'Who are my friends list?',
          'answer':
              'The friend list include your contacts which are using the app and from your proximity app users showing after adding in you friend list.',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredQuestionsAndAnswers = [];

    if (_searchQuery.isNotEmpty) {
      for (var topic in helpTopics) {
        for (var qa in topic['questions']) {
          if (qa['question']
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              qa['answer'].toLowerCase().contains(_searchQuery.toLowerCase())) {
            filteredQuestionsAndAnswers.add(qa);
          }
        }
      }
    }
    return Scaffold(
      drawer: NavBar(
        userType: 'driver',
        passenger: 'passenger',
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: Container(
          // extra container for custom bottom shadows
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.5),
                spreadRadius: 3,
                blurRadius: 3,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Color(0xFF66b899),
            title: Text("Help Center"),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Color(0xf7e7b7b),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Center(
                      child: Text(
                        "How can we help you?",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                            50.0), // Set the border radius here
                        color: Colors.white, // Background color
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: TextField(
                        onChanged: (query) {
                          setState(() {
                            _searchQuery = query;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search Help Center',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.black38,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          prefixIconConstraints: BoxConstraints(
                            minHeight: 22,
                            minWidth: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Help Topics",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 16),
                  Column(
                    children: [
                      ...helpTopics.map((topic) {
                        List<Map<String, String>> questionsAndAnswers = [];
                        for (var qa in topic['questions']) {
                          if (qa['question']
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()) ||
                              qa['answer']
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase())) {
                            questionsAndAnswers.add(qa);
                          }
                        }
                        if (questionsAndAnswers.isNotEmpty) {
                          return buildTopicExpansionPanel(
                            context,
                            Icon(
                              topic['icon'],
                              color: Color(0xFF08B783),
                            ),
                            topic['title'],
                            questionsAndAnswers,
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      }),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopicExpansionPanel(BuildContext context, Icon icon, String topic,
      List<Map<String, String>> questionsAndAnswers) {
    return ExpansionPanelList.radio(
      elevation: 0,
      expandedHeaderPadding: EdgeInsets.all(0),
      children: [
        ExpansionPanelRadio(
          value: topic.toLowerCase().replaceAll(' ', '_'),
          headerBuilder: (context, isExpanded) {
            return Container(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  icon,
                  SizedBox(width: 8),
                  Text(
                    topic,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
          body: Container(
            color: CupertinoColors.systemGrey5,
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: questionsAndAnswers
                  .map((qa) =>
                      buildQuestion(context, qa['question']!, qa['answer']!))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildQuestion(BuildContext context, String question, String answer) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                answerPage(Question: question, Answer: answer),
          ),
        );
      },
      child: Row(
        children: [
          Icon(Icons.circle_outlined, color: Color(0xFF08B783), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              question,
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
