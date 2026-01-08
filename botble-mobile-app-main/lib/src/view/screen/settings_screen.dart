import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/service/biometric_service.dart';
import 'package:martfury/src/service/profile_service.dart';
import 'package:martfury/src/service/token_service.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/view/widget/change_password_dialog.dart';
import 'package:local_auth/local_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricService _biometricService = BiometricService();
  final ProfileService _profileService = ProfileService();
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricEnabledInAPI = false;
  bool _isLoading = true;
  bool _isUpdating = false;
  BiometricType? _biometricType;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load settings from API first (only if the endpoint exists)
      try {
        final profile = await _profileService.getProfile();
        // Check if the API returns settings object with biometric_enabled field
        if (profile.containsKey('settings') && profile['settings'] is Map) {
          final settings = profile['settings'] as Map<String, dynamic>;
          if (settings.containsKey('biometric_enabled')) {
            _isBiometricEnabledInAPI = settings['biometric_enabled'] == true;
          } else {
            _isBiometricEnabledInAPI =
                await BiometricService.isBiometricLoginEnabled();
          }
        } else if (profile.containsKey('biometric_enabled')) {
          // Fallback to root level biometric_enabled if it exists
          _isBiometricEnabledInAPI = profile['biometric_enabled'] == true;
        } else {
          // API doesn't have biometric field yet, use local setting
          _isBiometricEnabledInAPI =
              await BiometricService.isBiometricLoginEnabled();
        }
      } catch (e) {
        // Continue with local settings if API fails
        _isBiometricEnabledInAPI =
            await BiometricService.isBiometricLoginEnabled();
      }

      // Check if biometric is available
      _isBiometricAvailable = await _biometricService.isBiometricAvailable();

      if (_isBiometricAvailable) {
        // Get available biometric types
        final biometrics = await _biometricService.getAvailableBiometrics();
        if (biometrics.isNotEmpty) {
          // Prioritize Face ID on iOS
          if (biometrics.contains(BiometricType.face)) {
            _biometricType = BiometricType.face;
          } else if (biometrics.contains(BiometricType.fingerprint)) {
            _biometricType = BiometricType.fingerprint;
          } else {
            _biometricType = biometrics.first;
          }
        }

        // Check if biometric login is enabled locally
        _isBiometricEnabled = await BiometricService.isBiometricLoginEnabled();

        // Sync with API setting if different
        if (_isBiometricEnabled != _isBiometricEnabledInAPI) {
          // Prefer API setting as source of truth
          _isBiometricEnabled = _isBiometricEnabledInAPI;
          await BiometricService.setBiometricLoginEnabled(_isBiometricEnabled);
        }
      }
    } catch (e) {
      // Failed to load biometric settings - using default values
      debugPrint('Failed to load biometric settings: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      if (value) {
        // Authenticate before enabling
        final authenticated = await _biometricService.authenticate(
          reason: 'profile.authenticate_to_enable_biometric'.tr(),
        );

        if (authenticated) {
          // Update local setting
          await BiometricService.setBiometricLoginEnabled(true);

          // Store the current auth token for biometric login
          final currentToken = await TokenService.getToken();

          if (currentToken != null) {
            await BiometricService.setBiometricToken(currentToken);

            // Verify it was saved
            await BiometricService.getBiometricToken();
          } else {}

          // Update API setting
          try {
            await _profileService.updateSettings(biometricEnabled: true);
          } catch (e) {
            // Continue even if API update fails
          }

          setState(() {
            _isBiometricEnabled = true;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('profile.biometric_enabled'.tr()),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // Disable biometric login
        await BiometricService.setBiometricLoginEnabled(false);
        await BiometricService.setBiometricToken(null);

        // Update API setting
        try {
          await _profileService.updateSettings(biometricEnabled: false);
        } catch (e) {
          // Continue even if API update fails
        }

        setState(() {
          _isBiometricEnabled = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('profile.biometric_disabled'.tr()),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  String _getBiometricLabel() {
    if (_biometricType == BiometricType.face) {
      return 'profile.face_id'.tr();
    } else if (_biometricType == BiometricType.fingerprint) {
      return 'profile.touch_id'.tr();
    } else {
      return 'profile.biometric_authentication'.tr();
    }
  }

  String _getBiometricDescription() {
    if (_biometricType == BiometricType.face) {
      return 'profile.use_face_id_to_login'.tr();
    } else if (_biometricType == BiometricType.fingerprint) {
      return 'profile.use_touch_id_to_login'.tr();
    } else {
      return 'profile.use_biometric_to_login'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'profile.settings'.tr(),
          style: kAppTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Security Section
                    Text(
                      'profile.security'.tr(),
                      style: kAppTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getPrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Biometric Authentication Toggle
                    if (_isBiometricAvailable)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceColor(context),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SwitchListTile(
                          title: Text(
                            _getBiometricLabel(),
                            style: kAppTextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.getPrimaryTextColor(context),
                            ),
                          ),
                          subtitle: Text(
                            _getBiometricDescription(),
                            style: kAppTextStyle(
                              fontSize: 14,
                              color: AppColors.getSecondaryTextColor(context),
                            ),
                          ),
                          value: _isBiometricEnabled,
                          onChanged: _isUpdating ? null : _toggleBiometric,
                          activeColor: AppColors.primary,
                          secondary:
                              _isUpdating
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : null,
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.getSecondaryTextColor(
                              context,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.getSecondaryTextColor(
                                    context,
                                  ),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'profile.biometric_not_available'.tr(),
                                  style: kAppTextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.getPrimaryTextColor(
                                      context,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'profile.biometric_not_available_description'
                                  .tr(),
                              style: kAppTextStyle(
                                fontSize: 14,
                                color: AppColors.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Change Password Button
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.getSurfaceColor(context),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.lock_outline,
                          color: AppColors.getPrimaryTextColor(context),
                        ),
                        title: Text(
                          'profile.change_password'.tr(),
                          style: kAppTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.getPrimaryTextColor(context),
                          ),
                        ),
                        subtitle: Text(
                          'profile.update_your_account_password'.tr(),
                          style: kAppTextStyle(
                            fontSize: 14,
                            color: AppColors.getSecondaryTextColor(context),
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => const ChangePasswordDialog(),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Additional security info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.security,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'profile.biometric_security_info'.tr(),
                              style: kAppTextStyle(
                                fontSize: 14,
                                color: AppColors.getPrimaryTextColor(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
