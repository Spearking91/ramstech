import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton(
      {super.key,
      required this.onPressed,
      this.disabled = false,
      this.isLoading = false});
  final VoidCallback onPressed;
  final bool disabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
            disabledBackgroundColor: Colors.white54,
            fixedSize: Size.fromWidth(
              MediaQuery.sizeOf(context).width,
            ),
            side: BorderSide(color: Colors.grey[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            )),
        child: isLoading
            ? CircularProgressIndicator(
                color: disabled ? Colors.grey : Colors.teal,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/google-icon-logo-svgrepo-com.svg',
                    height: 24,
                    width: 24,
                    colorFilter: disabled
                        ? ColorFilter.mode(Colors.grey, BlendMode.srcIn)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text('Continue with Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ))
                ],
              ));
  }
}
