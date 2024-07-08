import 'package:flutter/material.dart';

class CustomBadgeTab extends StatelessWidget {
  final String text;
  final int badgeCount;

  CustomBadgeTab({required this.text, required this.badgeCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Text(text),
        if (badgeCount > 0)
          Positioned(
            right: -10,
            top: -5,
            child: Badge(
              isLabelVisible: badgeCount > 0,
              label: Text(
                '$badgeCount',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              alignment: Alignment.topRight,
              offset: Offset(-5, -5),
            ),
          ),
      ],
    );
  }
}
