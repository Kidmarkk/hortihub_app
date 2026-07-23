import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final authNotifier = ref.read(authStateProvider.notifier);

    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isVerySmall = screenWidth < 360;

    // Dynamic sizes
    final double logoSize = isVerySmall ? 40 : 50;
    final double titleFontSize = Responsive.getResponsiveFontSize(context, baseSize: 28);
    final double fieldFontSize = Responsive.getResponsiveFontSize(context, baseSize: 14);
    final double buttonFontSize = Responsive.getResponsiveFontSize(context, baseSize: 16);
    final double cardPadding = Responsive.getResponsivePadding(context, basePadding: 24);
    final double horizontalPadding = isVerySmall ? 12 : 24;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF026D2A), Color(0xFF016325), Color(0xFF01581F)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: SingleChildScrollView(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo + App Name (responsive)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/hortihub_logo_1.jpg',
                                width: logoSize,
                                height: logoSize,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.image_not_supported,
                                  color: const Color(0xFF026D2A),
                                  size: logoSize,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'MEG Horticulture Hub',
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF026D2A),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isVerySmall ? 20 : 30),

                          // Username
                          TextFormField(
                            controller: _usernameController,
                            style: TextStyle(fontSize: fieldFontSize),
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: TextStyle(fontSize: fieldFontSize),
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person, size: fieldFontSize + 4),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isVerySmall ? 8 : 14,
                                horizontal: 12,
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          SizedBox(height: isVerySmall ? 10 : 16),

                          // Password with eye button
                          TextFormField(
                            controller: _passwordController,
                            style: TextStyle(fontSize: fieldFontSize),
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(fontSize: fieldFontSize),
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock, size: fieldFontSize + 4),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: fieldFontSize + 4,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isVerySmall ? 8 : 14,
                                horizontal: 12,
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          SizedBox(height: isVerySmall ? 16 : 24),

                          // Error message (if any)
                          if (authState.hasError)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _getErrorMessage(authState.error),
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: fieldFontSize,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            height: isVerySmall ? 40 : 50,
                            child: ElevatedButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        authNotifier.login(
                                          _usernameController.text.trim(),
                                          _passwordController.text.trim(),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF026D2A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: authState.isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: buttonFontSize,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(Object? error) {
    if (error is Exception) {
      final msg = error.toString();
      return msg.replaceFirst('Exception: ', '');
    }
    return 'Login failed. Please check your credentials and try again.';
  }
}