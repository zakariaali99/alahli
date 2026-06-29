import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;

  const ConfirmDialog({
    required this.title,
    required this.content,
    this.confirmLabel = 'تأكيد',
    this.cancelLabel = 'إلغاء',
    this.confirmColor = AppColors.primary,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        textAlign: TextAlign.right,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: Text(
        content,
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 14),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
