import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

// =====================================================================
// DRISHTI Mobile App: Ministry of Social Justice and Empowerment Header
// High-contrast official header banner with Ashoka Chakra emblem styling
// =====================================================================

class GovernmentHeader extends StatelessWidget {
  final String? subtitle;
  final Widget? trailing;

  const GovernmentHeader({
    Key? key,
    this.subtitle,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.primaryNavy,
        border: Border(
          bottom: BorderSide(color: AppColors.saffronAccent, width: 3),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Emblem representation
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.saffronAccent, width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.account_balance,
                  size: 20,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Titles
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    subtitle ?? AppStrings.appTagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
