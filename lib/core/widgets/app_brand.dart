import 'package:flutter/material.dart';
import 'package:qr_scanner/app/theme/app_tokens.dart';
import 'package:qr_scanner/core/constants/app_constants.dart';

class AppBrandTitle extends StatelessWidget {
  const AppBrandTitle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      header: true,
      label: AppConstants.appName,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSizes.brandMark,
            height: AppSizes.brandMark,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark ? AppColors.brandBright : AppColors.brand,
                  AppColors.brandDeep,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.qr_code_2,
              size: compact ? 16 : 18,
              color: isDark ? AppColors.darkInk : Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            AppConstants.appName,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              fontSize: compact ? 18 : 20,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
