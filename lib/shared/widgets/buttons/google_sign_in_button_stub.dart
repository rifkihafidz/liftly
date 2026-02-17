import 'package:flutter/material.dart';
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
  return MenuListItem(
    title: text ?? 'Connect Google Drive',
    subtitle: subtitle ?? 'Enable sync across your devices',
    icon: icon ?? Icons.cloud_outlined,
    color: color ?? AppColors.accent,
    onTap: onPressed ?? () {},
    isLoading: isLoading,
  );
}
