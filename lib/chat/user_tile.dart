import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final String image;
  final void Function()? onTap;

  const UserTile({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    required this.onTap,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        // margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              // borderRadius: BorderRadius.circular(70),
              backgroundImage: NetworkImage(image),
              radius: 25,
            ), //icon
            const SizedBox(
              width: 10.0,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  message,
                  style: TextStyle(
                      color: Colors.black45,
                      fontSize: 17.0,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Spacer(),
            Text(
              time,
              style: TextStyle(
                  color: Colors.black45,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
