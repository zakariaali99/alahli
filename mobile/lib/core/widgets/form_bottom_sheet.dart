import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A bottom sheet layout with scrollable body and pinned footer buttons.
/// Use inside a `showModalBottomSheet` builder.
/// The submit button never scrolls off-screen, even with the keyboard open.
class PinnedBottomSheet extends StatelessWidget {
  final String title;
  final Widget body;
  final String submitLabel;
  final String? cancelLabel;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback? onCancel;

  const PinnedBottomSheet({
    super.key,
    required this.title,
    required this.body,
    required this.submitLabel,
    this.cancelLabel,
    this.isSubmitting = false,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        // Drag handle
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        // Title row with close button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.pop(context),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        // Scrollable body
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: body,
          ),
        ),
        const SizedBox(height: 8),
        // Pinned footer buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: isSubmitting ? null : (onCancel ?? () => Navigator.pop(context)),
                child: Text(cancelLabel ?? 'إلغاء'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(submitLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
