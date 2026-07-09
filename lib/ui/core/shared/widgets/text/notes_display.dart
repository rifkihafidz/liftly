import 'package:flutter/material.dart';
import 'package:liftly/core/constants/colors.dart';

class NotesDisplay extends StatelessWidget {
  final String notes;
  final int? maxLines;
  final TextOverflow? overflow;
  final int? maxLength;
  final EdgeInsetsGeometry margin;

  const NotesDisplay({
    super.key,
    required this.notes,
    this.maxLines,
    this.overflow,
    this.maxLength,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    String displayText = notes;
    if (maxLength != null && notes.length > maxLength!) {
      displayText = '${notes.substring(0, maxLength!)}...';
    }

    return Padding(
      padding: margin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.edit_rounded,
              size: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
              maxLines: maxLines,
              overflow: overflow,
            ),
          ),
        ],
      ),
    );
  }
}
