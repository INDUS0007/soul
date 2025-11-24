import 'package:flutter/material.dart';

import 'package:common/api/api_client.dart';
import 'package:common/widgets/widgets.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _hasPasswordText = false;
  bool _loading = false;
  String? _error; // non-form errors

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() {
      setState(() => _hasPasswordText = _passCtrl.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validateUser(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter email or phone number';
    }
    final s = value.trim();
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    final isPhone = RegExp(r'^[0-9+()\-\s]{7,}$').hasMatch(s);
    if (!isEmail && !isPhone) return 'Enter a valid email or phone';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    (bool, String?) result;
    try {
      result = await _api.login(_userCtrl.text.trim(), _passCtrl.text);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to reach server: $error';
      });
      return;
    }

    final (ok, err) = result;
    if (!mounted) return;

    if (!ok) {
    setState(() {
      _loading = false;
        _error = err;
    });
      return;
    }

    Map<String, dynamic>? profile;
    try {
      profile = await _api.getProfile();
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context, 'Signed in, but failed to load profile: $error');
      }
    }

    if (!mounted) return;

    setState(() => _loading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(profile: profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: size.width > 500 ? 420 : 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/soul_support_logo.png',
                              height: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stack) => Icon(
                                Icons.self_improvement,
                                size: 96,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const SizedBox(height: 24),
              TextFormField(
                            controller: _userCtrl,
              textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email or phone number',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(25)),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateUser,
              ),
                          const SizedBox(height: 16),
              TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
              textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(25)),
                              ),
                              suffixIcon: _hasPasswordText
                                  ? IconButton(
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                    )
                                  : null,
                            ),
                            validator: _validatePassword,
              onFieldSubmitted: (_) {
                if (!_loading) {
                  _submit();
                }
              },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ForgotPasswordScreen(),
                                        ),
                                      ),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _error!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
                          ],
              const SizedBox(height: 12),
                          FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                            icon: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2.2),
                                  )
                                : const Icon(Icons.login),
                            label: Text(_loading ? 'Signing in…' : 'Sign in'),
                ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account?"),
              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const RegisterScreen(),
                                          ),
                                        ),
                                child: const Text('Sign up'),
              ),
            ],
                          ),
                        ],
                      ),
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

