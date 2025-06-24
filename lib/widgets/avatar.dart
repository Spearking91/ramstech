import 'package:flutter/material.dart';
import 'package:ramstech/services/firebase_auth_service.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.radius = 60, this.onPressed});

  final double radius;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Get first letter of display name or email, fallback to 'U'
    final String initial =
        FirebaseAuthMethod.user?.displayName?.isNotEmpty == true
            ? FirebaseAuthMethod.user!.displayName![0].toUpperCase()
            : (FirebaseAuthMethod.user?.email?.isNotEmpty == true
                ? FirebaseAuthMethod.user!.email![0].toUpperCase()
                : 'U');

    return TextButton(
      onPressed: onPressed,
      child: CircleAvatar(
        radius: radius,
        child: Text(
          initial,
          style: TextStyle(fontSize: radius / 1.5),
        ),
      ),
    );
  }
}
