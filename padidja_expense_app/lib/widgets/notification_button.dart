import 'package:flutter/material.dart';
import 'package:padidja_expense_app/screens/notification_screen.dart';

Widget buildNotificationAction(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationPage(),
          ),
        );
      },
      icon: const Icon(
        Icons.notifications_outlined,
        color: Colors.white,
        size: 24,
      ),
    ),
  );
}