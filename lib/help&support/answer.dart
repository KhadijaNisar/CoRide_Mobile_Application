import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class answerPage extends StatefulWidget {
  final String Question;
  final String Answer;
  const answerPage({
    Key? key,
    required this.Question,
    required this.Answer,
  }) : super(key: key);

  @override
  _answerPageState createState() => _answerPageState();
}

class _answerPageState extends State<answerPage> {
  bool _isFeedbackSubmitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Container(
          //   color: CupertinoColors.systemGrey5,
          Column(
            children: [
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Center(
                  child: Text(
                    widget.Question,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  color: CupertinoColors.systemGrey5,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      widget.Answer,
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Divider(),
              // Container(
              //   color: CupertinoColors.systemGrey5,
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    Text(
                      "Was this helpfull?",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    SizedBox(height: 10),
                    _isFeedbackSubmitted
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, color: Color(0xFF08B783)),
                              SizedBox(height: 8),
                              Text(
                                "Thanks for your feedback",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isFeedbackSubmitted = true;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Icon(Icons.thumb_up,
                                        color: Color(0xFF08B783)),
                                    SizedBox(width: 8),
                                    Text(
                                      "Yes",
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isFeedbackSubmitted = true;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Icon(Icons.thumb_down,
                                        color: Color(0xFF08B783)),
                                    SizedBox(width: 8),
                                    Text(
                                      "No",
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                    SizedBox(height: 15),
                    // FilledButton(
                    //   style: ButtonStyle(
                    //     backgroundColor: MaterialStateColor.resolveWith(
                    //         (states) => Color(
                    //             0xFF08B783)), // Change the background color here
                    //     shape:
                    //         MaterialStateProperty.all<RoundedRectangleBorder>(
                    //       RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(
                    //             8.0), // Adjust the border radius here
                    //       ),
                    //     ),
                    //   ),
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => chatPage(
                    //             receiverEmail: receiverEmail,
                    //             receiverID: receiverID,
                    //             displayName: displayName,
                    //             image: image),
                    //       ),
                    //     );
                    //   },
                    //   child: Text(
                    //     "Contact Support",
                    //     style: TextStyle(fontSize: 16, color: Colors.black),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
