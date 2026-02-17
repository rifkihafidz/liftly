import 'package:flutter/material.dart';
import 'google_sign_in_button_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_button_web.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? text;
  final String? subtitle;
  final IconData? icon;
  final Color? color;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.text,
    this.subtitle,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return buildGoogleSignInButton(
      context: context,
      onPressed: onPressed,
      isLoading: isLoading,
      text: text,
      subtitle: subtitle,
      icon: icon,
      color: color,
    );
  }
}
