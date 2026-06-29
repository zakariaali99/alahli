import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color bgColor;
    Color fgColor;
    IconData defaultIcon;

    if (isError) {
      bgColor = AppColors.destructive;
      fgColor = Colors.white;
      defaultIcon = Icons.error_outline;
    } else if (isSuccess) {
      bgColor = AppColors.secondary;
      fgColor = Colors.white;
      defaultIcon = Icons.check_circle_outline;
    } else {
      bgColor = isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated;
      fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
      defaultIcon = Icons.info_outline;
    }

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            icon ?? defaultIcon,
            color: fgColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isError || isSuccess 
            ? BorderSide.none 
            : BorderSide(color: isDark ? AppColors.darkMuted : AppColors.border),
      ),
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      elevation: 6,
      duration: duration,
      action: SnackBarAction(
        label: 'إغلاق',
        textColor: isError || isSuccess ? Colors.white70 : AppColors.primary,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
