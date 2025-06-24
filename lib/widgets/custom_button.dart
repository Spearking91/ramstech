import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height,
    this.width,
    this.disabled = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final double? height;
  final double? width;
  final bool? disabled;
  final bool? isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: (disabled! || isLoading!) ? null : onPressed,
      style: FilledButton.styleFrom(
        fixedSize: Size(width ?? MediaQuery.sizeOf(context).width, 60),
        disabledBackgroundColor: Colors.white54,
      ),
      child: isLoading!
          ? const CircularProgressIndicator(
              color: Colors.white70,
            )
          : Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
    );
  }
}
