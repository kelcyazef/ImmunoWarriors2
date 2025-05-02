import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'user-not-found' => 'No user found for that email.',
          'wrong-password' => 'Wrong password provided.',
          'invalid-email' => 'The email address is not valid.',
          'invalid-credential' => 'Invalid credentials provided.',
          _ => 'An error occurred: ${e.message}',
        };
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'weak-password' => 'The password provided is too weak.',
          'email-already-in-use' => 'An account already exists for that email.',
          'invalid-email' => 'The email address is not valid.',
          _ => 'An error occurred: ${e.message}',
        };
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navyBlue = const Color(0xFF0A2342); // Navy blue color constant
    
    return Scaffold(
      backgroundColor: navyBlue,
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create Account' : 'Sign In'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Card(
            elevation: 5,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            margin: const EdgeInsets.all(0),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: const Color(0xFFEDF2F7),
                                child: Icon(Icons.shield, size: 30, color: navyBlue),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isSignUp ? 'Create Account' : 'Sign In',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: navyBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),

                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Email field
                        const Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.mail_outline, color: Colors.grey[600]),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              showCursor: true, // Make cursor visible
                              cursorColor: navyBlue, // Set cursor color
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Your email address',
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Email required' : null,
                              enabled: !_isLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Password field
                    const Text('Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.lock_outline, color: Colors.grey[600]),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              showCursor: true, // Make cursor visible
                              cursorColor: navyBlue, // Set cursor color
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Your password',
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              validator: (value) => value == null || value.length < 6 ? '6 characters minimum' : null,
                              enabled: !_isLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _isSignUp ? _signUp() : _signIn(),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_isSignUp ? 'Create Account' : 'Sign In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: !_isLoading
                            ? () {
                                setState(() {
                                  _errorMessage = null;
                                  _isSignUp = !_isSignUp;
                                });
                              }
                            : null,
                        child: Text(
                          _isSignUp ? 'Sign In' : 'Create Account',
                          style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue),
                        ),
                      ),
                    ),
                      ],
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
