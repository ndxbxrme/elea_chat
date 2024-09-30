import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String userId;
  final double radius;
  final int currentRandom;
  const AvatarWidget(
      {super.key,
      required this.userId,
      this.radius = 18.0,
      this.currentRandom = 0});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(
        "https://firebasestorage.googleapis.com/v0/b/elea-c.appspot.com/o/avatars%2F${userId}.jpg?alt=media&token=80fe8000-73f5-4273-b6bb-85615fa168cf&rnd=$currentRandom",
      ),
    );
  }
}
