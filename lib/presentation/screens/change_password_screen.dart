import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/auth_utils.dart';
import '../../data/datasources/remote/api_service.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'New password is required';
    if (value.length < 8) return 'Minimum 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'At least one uppercase letter (A–Z)';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'At least one lowercase letter (a–z)';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'At least one number (0–9)';
    if (!RegExp(r'[#@!_\-]').hasMatch(value)) {
      return 'At least one special character (# @ ! _ -)';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your new password';
    if (value != _newPasswordCtrl.text) {
      return 'Does not match New Password';
    }
    return null;
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Password Update'),
        content: const Text('Are you sure you want to update your password?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('No', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // close confirmation dialog
              _updatePassword();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final oldHashed = AuthUtils.hashPassword(_oldPasswordCtrl.text);
      final newHashed = AuthUtils.hashPassword(_newPasswordCtrl.text);

      final payload = <String, String>{
        'oldPassword': oldHashed,
        'newPassword': newHashed,
        'username': user.userId,
      };

      final api = ApiService();
      final response = await api.postWithFormData(ApiConstants.updatePassword, payload);

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        final errorMsg = response.data['message'] ?? response.data['raw'] ?? 'Update failed';
        if (errorMsg.toLowerCase().contains('old password') ||
            errorMsg.toLowerCase().contains('didn\'t match')) {
          _showErrorDialog('Old password did not match');
        } else {
          _showErrorDialog('Update failed: $errorMsg');
        }
      }
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Password Updated'),
        content: const Text('Your password has been successfully updated. Please login again.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Password Update Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVerySmall = Responsive.isVerySmallScreen(context);
    final fontSize = Responsive.getResponsiveFontSize(context, baseSize: 14);
    final padding = Responsive.getResponsivePadding(context);
    final spacing = isVerySmall ? 8.0 : 16.0;
    final buttonPadding = EdgeInsets.symmetric(
      vertical: isVerySmall ? 10 : 14,
    );
    final double helperTextSize = isVerySmall ? 10 : 12;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: TextStyle(fontSize: Responsive.getResponsiveFontSize(context, baseSize: 18)),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Old Password
              TextFormField(
                controller: _oldPasswordCtrl,
                obscureText: _obscureOld,
                style: TextStyle(fontSize: fontSize),
                decoration: InputDecoration(
                  labelText: 'Old Password',
                  labelStyle: TextStyle(fontSize: fontSize),
                  border: const OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isVerySmall ? 8 : 14,
                    horizontal: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOld ? Icons.visibility_off : Icons.visibility,
                      size: fontSize + 4,
                    ),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Old password is required' : null,
              ),
              SizedBox(height: spacing),

              // New Password
              TextFormField(
                controller: _newPasswordCtrl,
                obscureText: _obscureNew,
                style: TextStyle(fontSize: fontSize),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(fontSize: fontSize),
                  border: const OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isVerySmall ? 8 : 14,
                    horizontal: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility,
                      size: fontSize + 4,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  helperText: 'Minimum 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special char (# @ ! _ -)',
                  helperStyle: TextStyle(fontSize: helperTextSize),
                  helperMaxLines: 3,
                ),
                validator: _validateNewPassword,
              ),
              SizedBox(height: spacing),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: _obscureConfirm,
                style: TextStyle(fontSize: fontSize),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(fontSize: fontSize),
                  border: const OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isVerySmall ? 8 : 14,
                    horizontal: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      size: fontSize + 4,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: _validateConfirmPassword,
              ),
              SizedBox(height: spacing * 2),

              // Update button
              ElevatedButton(
                onPressed: _isLoading ? null : _showConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: buttonPadding,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Update Password',
                        style: TextStyle(
                          fontSize: Responsive.getResponsiveFontSize(context, baseSize: 16),
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