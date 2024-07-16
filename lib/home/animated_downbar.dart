import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:hitchify/core/app_export.dart';
import 'package:hitchify/home/driver_home.dart';

import '../chat/home_page.dart';
import '../friends/friends_home.dart';
import '../profile/driver_profile_screen.dart';
import '../profile/passenger_profile.dart';
import 'home_screen.dart';

// Import your screens

class AnimatedDownBar extends StatefulWidget {
  final String userType;
  final int screenNo; // Add userType parameter to the constructor

  AnimatedDownBar({required this.userType, required this.screenNo});

  @override
  _AnimatedDownBarState createState() => _AnimatedDownBarState();
}

class _AnimatedDownBarState extends State<AnimatedDownBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late int _selectedIndex;

  final List<BarItem> barItems = [
    BarItem(
      icon: Icons.home,
      text: 'Home',
    ),
    BarItem(
      icon: Icons.people,
      text: 'Friends',
    ),
    BarItem(
      icon: Icons.chat,
      text: 'Chat',
    ),
    BarItem(
      icon: Icons.person,
      text: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.screenNo;
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    // Set the default selected index to the passed screenNo
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onBarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Animate the bottom bar
    _animationController.reset();
    _animationController.forward();

    switch (index) {
      case 0:
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
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MyFriendsScreen(
                userType: widget.userType,
                screenNo: 1,
              )),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(
                userType: widget.userType,
              )),
        );
        break;
      case 3:
        if (widget.userType == 'passenger') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EditProfileScreen(
                  userType: widget.userType,
                )),
          );
        } else if (widget.userType == 'driver') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DriverProfileScreen(
                  userType: widget.userType,
                )),
          );
        }
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, Widget? child) {
        return Container(
          color: appTheme.teal500,
          child: CurvedNavigationBar(
            backgroundColor: Colors.white,
            color: appTheme.teal500,
            buttonBackgroundColor: Colors.white,
            height: 65,
            items: barItems.asMap().entries.map((MapEntry<int, BarItem> entry) {
              int index = entry.key;
              BarItem item = entry.value;
              return BarItemWidget(
                item: item,
                isSelected: index == _selectedIndex,
                animation: _animation,
              );
            }).toList(),
            index: _selectedIndex,
            onTap: (index) {
              _onBarItemTapped(index);
            },
          ),
        );
      },
    );
  }
}

class BarItem {
  final IconData icon;
  final String text;

  BarItem({required this.icon, required this.text});
}

class BarItemWidget extends StatelessWidget {
  final BarItem item;
  final bool isSelected;
  final Animation<double> animation;
  final double itemSize = 27.0;

  BarItemWidget({
    required this.item,
    required this.isSelected,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    double opacity = isSelected ? 1.0 : 0.5;
    Color color = isSelected ? Color(0xff52c498) : Colors.black;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 10),
        Icon(
          item.icon,
          size: itemSize,
          color: color.withOpacity(opacity),
        ),
        SizedBox(height: 3),
        Text(
          item.text,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(opacity),
          ),
        ),
      ],
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:curved_navigation_bar/curved_navigation_bar.dart';
// import 'package:hitchify/core/app_export.dart';
// import 'package:hitchify/home/driver_home.dart';
//
// import '../chat/home_page.dart';
// import '../friends/friends_home.dart';
// import '../profile/driver_profile_screen.dart';
// import '../profile/passenger_profile.dart';
// import 'home_screen.dart';
//
// // Import your screens
//
// class AnimatedDownBar extends StatefulWidget {
//   final String userType;
//   final int screenNo; // Add userType parameter to the constructor
//
//   AnimatedDownBar({required this.userType, required this.screenNo});
//
//   @override
//   _AnimatedDownBarState createState() => _AnimatedDownBarState();
// }
//
// class _AnimatedDownBarState extends State<AnimatedDownBar>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _animation;
//   late int _selectedIndex;
//
//   final List<BarItem> barItems = [
//     BarItem(
//       icon: Icons.home,
//       text: 'Home',
//     ),
//     BarItem(
//       icon: Icons.people,
//       text: 'Friends',
//     ),
//     BarItem(
//       icon: Icons.chat,
//       text: 'Chat',
//     ),
//     BarItem(
//       icon: Icons.person,
//       text: 'Profile',
//     ),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedIndex = widget.screenNo;
//     _animationController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 500),
//     );
//     _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
//
//     // Set the default selected index to the passed screenNo
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   void _onBarItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//
//     // Animate the bottom bar
//     _animationController.reset();
//     _animationController.forward();
//
//     switch (index) {
//       case 0:
//         if (widget.userType == 'passenger') {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => HomeScreen()),
//           );
//         } else if (widget.userType == 'driver') {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => driverHome()),
//           );
//         }
//         break;
//       case 1:
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) => MyFriendsScreen(
//                 userType: widget.userType,
//                 screenNo: 1,
//               )),
//         );
//         break;
//       case 2:
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) => HomePage(
//                 userType: widget.userType,
//               )),
//         );
//         break;
//       case 3:
//         if (widget.userType == 'passenger') {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => EditProfileScreen(
//                   userType: widget.userType,
//                 )),
//           );
//         } else if (widget.userType == 'driver') {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => DriverProfileScreen(
//                   userType: widget.userType,
//                 )),
//           );
//         }
//         break;
//       default:
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _animationController,
//       builder: (BuildContext context, Widget? child) {
//         return Transform.translate(
//           offset: Offset(0, _animation.value * 20),
//           child: Container(
//             color: appTheme.teal500,
//             child: CurvedNavigationBar(
//               backgroundColor: Colors.white,
//               color: appTheme.teal500,
//               buttonBackgroundColor: Colors.white,
//               height: 75,
//               items:
//               barItems.asMap().entries.map((MapEntry<int, BarItem> entry) {
//                 int index = entry.key;
//                 BarItem item = entry.value;
//                 return BarItemWidget(
//                   item: item,
//                   isSelected: index == _selectedIndex,
//                   animation: _animation,
//                 );
//               }).toList(),
//               index: _selectedIndex,
//               onTap: (index) {
//                 _onBarItemTapped(index);
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// class BarItem {
//   final IconData icon;
//   final String text;
//
//   BarItem({required this.icon, required this.text});
// }
//
// class BarItemWidget extends StatelessWidget {
//   final BarItem item;
//   final bool isSelected;
//   final Animation<double> animation;
//   final double itemSize = 27.0;
//
//   BarItemWidget({
//     required this.item,
//     required this.isSelected,
//     required this.animation,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     double opacity = isSelected ? 1.0 : 0.5;
//     Color color = isSelected ? Color(0xff52c498) : Colors.black;
//
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         SizedBox(height: 10),
//         Icon(
//           item.icon,
//           size: itemSize,
//           color: color.withOpacity(opacity),
//         ),
//         SizedBox(height: 3),
//         Text(
//           item.text,
//           style: TextStyle(
//             fontSize: 12,
//             color: color.withOpacity(opacity),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
//
// // import 'package:flutter/material.dart';
// // import 'package:curved_navigation_bar/curved_navigation_bar.dart';
// // import 'package:hitchify/home/driver_home.dart';
// //
// // import '../chat/home_page.dart';
// // import '../friends/friends_home.dart';
// // import '../profile/driver_profile_screen.dart';
// // import '../profile/passenger_profile.dart';
// // import 'home_screen.dart';
// //
// // // Import your screens
// //
// // class AnimatedDownBar extends StatefulWidget {
// //   final String userType;
// //   final int screenNo;// Add userType parameter to the constructor
// //
// //   AnimatedDownBar({required this.userType,required this.screenNo});
// //
// //   @override
// //   _AnimatedDownBarState createState() => _AnimatedDownBarState();
// // }
// //
// // class _AnimatedDownBarState extends State<AnimatedDownBar>
// //     with SingleTickerProviderStateMixin {
// //   late AnimationController _animationController;
// //   late Animation<double> _animation;
// //   late int _selectedIndex ;
// //
// //
// //   final List<BarItem> barItems = [
// //     BarItem(
// //       icon: Icons.home,
// //       text: 'Home',
// //     ),
// //     BarItem(
// //       icon: Icons.people,
// //       text: 'Friends',
// //     ),
// //     BarItem(
// //       icon: Icons.chat,
// //       text: 'Chat',
// //     ),
// //     BarItem(
// //       icon: Icons.person,
// //       text: 'Profile',
// //     ),
// //   ];
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     // _selectedIndex = 0;
// //     _selectedIndex = widget.screenNo;
// //     _animationController = AnimationController(
// //       vsync: this,
// //       duration: Duration(milliseconds: 500),
// //     );
// //     _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
// //
// //     // Set the default selected index to 0 (Home)
// //   }
// //
// //   @override
// //   void dispose() {
// //     _animationController.dispose();
// //     super.dispose();
// //   }
// //
// //   void _onBarItemTapped(int index) {
// //     print("Selected Index: $_selectedIndex");
// //     setState(() {
// //       _selectedIndex = index;
// //     });
// //
// //     switch (index) {
// //       case 0:
// //         if (widget.userType == 'passenger') {
// //           Navigator.pushReplacement(
// //             context,
// //             MaterialPageRoute(
// //                 builder: (context) => HomeScreen()),
// //           );
// //         } else if (widget.userType == 'driver') {
// //           // print("Type: $widget.userType");
// //           Navigator.pushReplacement(
// //             context,
// //             MaterialPageRoute(
// //                 builder: (context) => driverHome()),
// //           );
// //         }
// //         // Navigator.pushReplacement(
// //         //   context,
// //         //   MaterialPageRoute(builder: (context) => HomeScreen()),
// //         // );
// //         break;
// //       case 1:
// //         Navigator.pushReplacement(
// //           context,
// //           MaterialPageRoute(
// //               builder: (context) => MyFriendsScreen(
// //                     userType: widget.userType,
// //                 screenNo: 1,
// //                   )),
// //         );
// //         break;
// //       case 2:
// //         Navigator.pushReplacement(
// //           context,
// //           MaterialPageRoute(
// //               builder: (context) => HomePage(
// //                     userType: widget.userType,
// //                   )),
// //         );
// //         break;
// //       case 3:
// //         if (widget.userType == 'passenger') {
// //           Navigator.pushReplacement(
// //             context,
// //             MaterialPageRoute(
// //                 builder: (context) => EditProfileScreen(
// //                       userType: widget.userType,
// //                     )),
// //           );
// //         } else if (widget.userType == 'driver') {
// //           // print("Type: $widget.userType");
// //           Navigator.pushReplacement(
// //             context,
// //             MaterialPageRoute(
// //                 builder: (context) => DriverProfileScreen(
// //                       userType: widget.userType,
// //                     )),
// //           );
// //         }
// //         // context, MaterialPageRoute(builder: (context) => EditProfileScreen()));
// //         break;
// //       default:
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return AnimatedBuilder(
// //       animation: _animationController,
// //       builder: (BuildContext context, Widget? child) {
// //         return Transform.translate(
// //           offset: Offset(0, _animation.value * 20),
// //           child: Container(
// //             color: Colors.white,
// //             child: CurvedNavigationBar(
// //               backgroundColor: Colors.white,
// //               color: Color(0xff52c498),
// //               buttonBackgroundColor: Colors.white,
// //               height: 70,
// //               items:
// //                   barItems.asMap().entries.map((MapEntry<int, BarItem> entry) {
// //                 int index = entry.key;
// //                 print("Index: $index");
// //                 print("Selected : $_selectedIndex");
// //                 BarItem item = entry.value;
// //                 return BarItemWidget(
// //                   item: item,
// //                   isSelected: index == _selectedIndex,
// //                   animation: _animation,
// //                 );
// //               }).toList(),
// //               onTap: (index) {
// //                 _onBarItemTapped(index);
// //               },
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }
// // }
// //
// // class BarItem {
// //   final IconData icon;
// //   final String text;
// //
// //   BarItem({required this.icon, required this.text});
// // }
// //
// // class BarItemWidget extends StatelessWidget {
// //   final BarItem item;
// //   final bool isSelected;
// //   final Animation<double> animation;
// //   final double itemSize = 27.0;
// //
// //   BarItemWidget({
// //     required this.item,
// //     required this.isSelected,
// //     required this.animation,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     double opacity = isSelected ? 1.0 : 0.5;
// //     Color color = isSelected ? Color(0xff52c498) : Colors.black;
// //
// //     return Column(
// //       mainAxisAlignment: MainAxisAlignment.center,
// //       children: [
// //         SizedBox(height: 10),
// //         Icon(
// //           item.icon,
// //           size: itemSize,
// //           color: color.withOpacity(opacity),
// //         ),
// //         SizedBox(height: 3),
// //         Text(
// //           item.text,
// //           style: TextStyle(
// //             fontSize: 12,
// //             color: color.withOpacity(opacity),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }
