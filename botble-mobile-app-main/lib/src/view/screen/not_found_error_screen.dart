import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/theme/app_fonts.dart';

/// Screen displayed when the API returns 404 Not Found
class NotFoundErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const NotFoundErrorScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Not found icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.info.withValues(alpha: 0.2)
                          : AppColors.info.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_outlined,
                  size: 80,
                  color: AppColors.info,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'common.not_found_error'.tr(),
                style: kAppTextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimaryTextColor(context),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Message
              Text(
                'common.not_found_message'.tr(),
                style: kAppTextStyle(
                  fontSize: 16,
                  color: AppColors.getSecondaryTextColor(context),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Go back button
              if (onRetry != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    label: Text(
                      'common.not_found_retry'.tr(),
                      style: kAppTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
