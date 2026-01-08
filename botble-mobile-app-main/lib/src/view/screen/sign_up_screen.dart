import 'package:flutter/material.dart';
import 'package:martfury/src/service/auth_service.dart';
import 'package:martfury/src/model/register_request.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/view/screen/sign_in_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/service/analytics_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePasswordConfirmation = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'SignUp');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  void _navigateToSignIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _passwordConfirmationController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.passwords_do_not_match'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = RegisterRequest(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        passwordConfirmation: _passwordConfirmationController.text,
      );
      print(request);

      final authService = AuthService();
      final response = await authService.register(request);

      // Log sign up event
      await AnalyticsService.logSignUp(signUpMethod: 'email');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: AppColors.success,
          ),
        );
        _navigateToSignIn();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  'auth.create_account'.tr(),
                  style: kAppTextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'auth.enter_details_to_create_account'.tr(),
                  style: kAppTextStyle(
                    fontSize: 16,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'auth.first_name'.tr(),
                style: kAppTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  hintText: 'auth.first_name_placeholder'.tr(),
                  hintStyle: kAppTextStyle(
                    color: AppColors.getHintTextColor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.getSurfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),
              Text(
                'auth.last_name'.tr(),
                style: kAppTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  hintText: 'auth.last_name_placeholder'.tr(),
                  hintStyle: kAppTextStyle(
                    color: AppColors.getHintTextColor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.getSurfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),
              Text(
                'common.email'.tr(),
                style: kAppTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'auth.email_placeholder'.tr(),
                  hintStyle: kAppTextStyle(
                    color: AppColors.getHintTextColor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.getSurfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              Text(
                'common.phone'.tr(),
                style: kAppTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: 'auth.phone_placeholder'.tr(),
                  hintStyle: kAppTextStyle(
                    color: AppColors.getHintTextColor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.getSurfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              Text(
                'auth.password'.tr(),
                style: kAppTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••••',
                  hintStyle: kAppTextStyle(
                    color: AppColors.getHintTextColor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.getSurfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'auth.confirm_password'.tr(),
                style: kAppTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordConfirmationController,
                obscureText: _obscurePasswordConfirmation,
                decoration: InputDecoration(
                  hintText: '••••••••••',
                  hintStyle: kAppTextStyle(
                    color: AppColors.getHintTextColor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.getSurfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePasswordConfirmation
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePasswordConfirmation =
                            !_obscurePasswordConfirmation;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                            'auth.sign_up'.tr(),
                            style: kAppTextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'auth.already_have_account'.tr(),
                    style: kAppTextStyle(
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _navigateToSignIn,
                    child: Text(
                      'auth.sign_in'.tr(),
                      style: kAppTextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
