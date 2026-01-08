import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/theme/app_fonts.dart';

/// Screen displayed when the API returns 502 Bad Gateway (server error)
class ServerErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const ServerErrorScreen({super.key, this.onRetry});

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
              // Server error icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.error.withValues(alpha: 0.2)
                          : AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dns_outlined,
                  size: 80,
                  color: AppColors.error,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'common.server_error'.tr(),
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
                'common.server_error_message'.tr(),
                style: kAppTextStyle(
                  fontSize: 16,
                  color: AppColors.getSecondaryTextColor(context),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Retry button
              if (onRetry != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, color: Colors.black),
                    label: Text(
                      'common.server_error_retry'.tr(),
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
