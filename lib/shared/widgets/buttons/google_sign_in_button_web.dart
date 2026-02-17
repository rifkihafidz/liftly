import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;
import '../cards/menu_list_item.dart';
import '../../../core/constants/colors.dart';

Widget buildGoogleSignInButton({
  required BuildContext context,
  VoidCallback? onPressed,
  bool isLoading = false,
  String? text,
  String? subtitle,
  IconData? icon,
  Color? color,
}) {
  // On Web, we overlay the official button (invisible) ON TOP of our custom UI.
  // This tricks the user into thinking they are clicking our custom button,
  // but they are actually clicking the iframe that triggers the popup.

  return Stack(
    children: [
      // 1. The Custom UI (Visible)
      MenuListItem(
        title: text ?? 'Connect Google Drive',
        subtitle: subtitle ?? 'Enable sync across your devices',
        icon: icon ?? Icons.cloud_outlined,
        color: color ?? AppColors.accent,
        onTap: () {
          // This onTap might not be reached if the overlay covers it,
          // but we keep it just in case.
        },
        isLoading: isLoading,
      ),

      // 2. The Official Button (Invisible Overlay)
      Positioned.fill(
        child: Opacity(
          opacity: 0.01, // Almost invisible but interactive
          child: (GoogleSignInPlatform.instance as web.GoogleSignInPlugin)
              .renderButton(
            configuration: web.GSIButtonConfiguration(
              theme: web.GSIButtonTheme.filledBlack,
              size: web.GSIButtonSize.large,
              text: web.GSIButtonText.signinWith,
              shape: web.GSIButtonShape.pill,
            ),
          ),
        ),
      ),
    ],
  );
}
