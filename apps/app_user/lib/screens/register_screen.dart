import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:common/api/api_client.dart';
import 'package:common/widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiClient _api = ApiClient();

  int _currentStep = 0;

  // Step 0 controllers
  final _basicFormKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _middleCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final List<String> _genders = const [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];
  String? _selectedGender;

  final List<Map<String, String>> _dialCodes = const [
    {'country': 'US', 'code': '+1'},
    {'country': 'UK', 'code': '+44'},
    {'country': 'AU', 'code': '+61'},
    {'country': 'IN', 'code': '+91'},
    {'country': 'AE', 'code': '+971'},
  ];
  Map<String, String> _selectedDial = const {'country': 'IN', 'code': '+91'};

  String get _fullPhone => _phoneCtrl.text.trim().isEmpty
      ? ''
      : '${_selectedDial['code']} ${_phoneCtrl.text.trim()}';

  // Step 1 OTP
  final _otpFormKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  String? _otpToken;
  int _otpFieldSeed = 0;

  // Step 2 password + consent
  final _passwordFormKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _agree = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _hasPasswordText1 = false;
  bool _hasPasswordText2 = false;
  bool _registering = false;

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() {
      setState(() => _hasPasswordText1 = _passCtrl.text.isNotEmpty);
    });
    _confirmCtrl.addListener(() {
      setState(() => _hasPasswordText2 = _confirmCtrl.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
  // username field removed; no controller to dispose
    _firstCtrl.dispose();
    _middleCtrl.dispose();
    _lastCtrl.dispose();
    _nicknameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // Validators
  // Username is auto-generated from email; manual validation not required

  String? _validateFirst(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter first name';
    if (value.trim().length < 2) return 'Too short';
    return null;
  }

  String? _validateLast(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter last name';
    if (value.trim().length < 2) return 'Too short';
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your age';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0 || parsed > 120) return 'Enter a realistic age';
    return null;
  }

  // 
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter phone number';
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Check for non-digit characters in the *raw* input (before cleaning)
    // NOTE: If you need to allow dashes or spaces, adjust the regex [^0-9\-\s]
    if (RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Enter only numbers (0-9) in the phone field.'; // <--- NEW ERROR MESSAGE
    }

    if (cleaned.length < 10) return 'Enter a valid phone number';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
    return ok ? null : 'Enter a valid email';
  }

  String? _validateOtp(String? value) {
    if (!_otpSent) return 'Tap "Send OTP" first';
    if (value == null || value.trim().isEmpty) return 'Enter the OTP';
    if (value.trim().length != 6) return 'OTP must be 6 digits';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value))
    return 'Add at least 1 uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Add at least 1 number';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != _passCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    final valid = _basicFormKey.currentState?.validate() ?? false;
    if (!valid) return;

    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _sendingOtp = true;
      _otpSent = false;
      _otpVerified = false;
      _otpToken = null;
    });

    final (ok, error) = await _api.sendRegistrationOtp(email);

    if (!mounted) return;
    setState(() {
      _sendingOtp = false;
    });

    if (!ok) {
      showErrorSnackBar(context, error ?? 'Failed to send OTP');
      return;
    }

    setState(() {
      _otpSent = true;
      _currentStep = 1;
      _otpCtrl.clear();
      _otpFieldSeed++;
    });

    showSuccessSnackBar(context, 'OTP sent to $email');
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();
    if (!(_otpFormKey.currentState?.validate() ?? false)) return;

    if (!_otpSent) {
      showErrorSnackBar(context, 'Please request an OTP first');
      return;
    }

    final email = _emailCtrl.text.trim();
    final code = _otpCtrl.text.trim();
    if (email.isEmpty || code.isEmpty) return;

    setState(() {
      _verifyingOtp = true;
    });

    final (ok, error, token) =
        await _api.verifyRegistrationOtp(email: email, code: code);

    if (!mounted) return;
    setState(() {
      _verifyingOtp = false;
    });

    if (!ok || (token == null || token.isEmpty)) {
      showErrorSnackBar(context, error ?? 'OTP verification failed');
      return;
    }

    setState(() {
      _otpVerified = true;
      _otpToken = token;
      _currentStep = 2;
    });

    showSuccessSnackBar(context, 'Email verified');
  }

  Future<void> _completeSignup() async {
    if (!_otpVerified) {
      showErrorSnackBar(context, 'Please verify your email OTP first');
      return;
    }
    if (_otpToken == null) {
      showErrorSnackBar(context, 'Verification token missing. Please verify OTP again.');
      return;
    }
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;
    if (!_agree) {
      showErrorSnackBar(context, 'You must agree to Terms & Privacy');
      return;
    }

    // Auto-generate a username from the email local-part (sanitize and ensure min length)
    String username;
    final emailLocal = _emailCtrl.text.trim().isNotEmpty
        ? _emailCtrl.text.trim().split('@').first
        : '';
    if (emailLocal.isNotEmpty) {
      username = emailLocal.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
      if (username.length < 3) {
        username = username + (DateTime.now().millisecondsSinceEpoch % 1000).toString();
      }
    } else {
      // fallback to nickname or timestamp
      username = _nicknameCtrl.text.trim().isNotEmpty
          ? _nicknameCtrl.text.trim().replaceAll(RegExp(r'[^A-Za-z0-9_]'), '')
          : 'user${DateTime.now().millisecondsSinceEpoch % 100000}';
    }
    final fullNameParts = [
      _firstCtrl.text.trim(),
      if (_middleCtrl.text.trim().isNotEmpty) _middleCtrl.text.trim(),
      _lastCtrl.text.trim(),
    ].where((s) => s.isNotEmpty).toList();
    final fullName = fullNameParts.join(' ');
    final nicknameFallback = _nicknameCtrl.text.trim().isNotEmpty ? _nicknameCtrl.text.trim() : username;
    final age = int.tryParse(_ageCtrl.text.trim());
    final email = _emailCtrl.text.trim();
    final gender = _selectedGender;
    final phone = _fullPhone.isEmpty ? _phoneCtrl.text.trim() : _fullPhone;

    setState(() => _registering = true);
    final (ok, err) = await _api.register(
      username: username,
      email: email,
      password: _passCtrl.text,
      fullName: fullName,
      nickname: nicknameFallback,
      phone: phone,
      age: age,
      gender: gender,
      otpToken: _otpToken!,
    );

    if (!mounted) return;
    setState(() => _registering = false);

    if (!ok) {
      showErrorSnackBar(context, err ?? 'Registration failed');
      return;
    }

    showSuccessSnackBar(context, 'Account created for $fullName. You can now sign in.');
    Navigator.pop(context);
  }

  InputDecoration _fieldDecoration({
    required String label,
    IconData? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefix != null ? Icon(prefix) : null,
      suffixIcon: suffix,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(25)),
      ),
    );
  }

  Step _basicInfoStep() {
    return Step(
      title: const Text('Basic info'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _basicFormKey,
        child: Column(
          children: [
            // Username removed - it will be auto-generated from the email
            const SizedBox(height: 12),
            TextFormField(
              controller: _nicknameCtrl,
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration(
                label: 'Preferred / Nickname (shown to counsellors)',
                prefix: Icons.person,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _firstCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration(
                  label: 'First name', prefix: Icons.badge_outlined),
              validator: _validateFirst,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _middleCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration(
                  label: 'Middle name', prefix: Icons.badge_outlined),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration(
                  label: 'Last name', prefix: Icons.badge_outlined),
              validator: _validateLast,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final vertical = constraints.maxWidth < 420;
                final children = <Widget>[
                  TextFormField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _fieldDecoration(
                        label: 'Age', prefix: Icons.cake_outlined),
                    validator: _validateAge,
                  ),
                  DropdownButtonFormField<String?>(
                    value: _selectedGender,
                    decoration: _fieldDecoration(
                        label: 'Gender', prefix: Icons.transgender_outlined),
                    items: _genders
                        .map((g) => DropdownMenuItem<String>(
                              value: g,
                              child: Text(g),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedGender = value),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Select gender'
                        : null,
                  ),
                ];

                if (vertical) {
                  return Column(
                    children: [
                      children[0],
                      const SizedBox(height: 12),
                      children[1],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: children[0]),
                    const SizedBox(width: 12),
                    Expanded(child: children[1]),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final vertical = constraints.maxWidth < 420;
                final dialDropdown =
                    DropdownButtonFormField<Map<String, String>>(
                  value: _selectedDial,
                  decoration: _fieldDecoration(label: 'Code'),
                  items: _dialCodes
                      .map((c) => DropdownMenuItem<Map<String, String>>(
                            value: c,
                            child: Text('${c['country']} (${c['code']})'),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedDial = value ?? _selectedDial),
                );
                // final phoneField = TextFormField(
                //   controller: _phoneCtrl,
                //   keyboardType: TextInputType.phone,
                //   textInputAction: TextInputAction.next,
                //   decoration: _fieldDecoration(
                //       label: 'Phone number', prefix: Icons.phone_outlined),
                //   validator: _validatePhone,
                // );
                final phoneField = TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone, // Suggests a numeric keyboard
                  textInputAction: TextInputAction.next,
                  
                  // *** ADDED INPUT FORMATTER ***
                  // inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  // ******************************
                  
                  decoration: _fieldDecoration(
                      label: 'Phone number', prefix: Icons.phone_outlined),
                  validator: _validatePhone,
                );
                // ---

                if (vertical) {
                  return Column(
                    children: [
                      dialDropdown,
                      const SizedBox(height: 12),
                      phoneField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Flexible(flex: 2, child: dialDropdown),
                    const SizedBox(width: 8),
                    Flexible(flex: 5, child: phoneField),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _fieldDecoration(
                label: 'Email',
                prefix: Icons.alternate_email_outlined,
                suffix: _sendingOtp
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      )
                    : InkWell(
                        onTap: _sendingOtp ? null : () => _sendOtp(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Text(
                            'Send OTP',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
              ),
              validator: _validateEmail,
            ),
          ],
        ),
      ),
    );
  }

  Step _otpStep() {
    return Step(
      title: const Text('Verify email'),
      isActive: _currentStep >= 1,
      state: _otpVerified
          ? StepState.complete
          : (_currentStep > 1 ? StepState.error : StepState.indexed),
      content: Form(
        key: _otpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Verify OTP Now',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Enter the 6-digit code sent to your email.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OtpBoxField(
              key: ValueKey(_otpFieldSeed),
              length: 6,
              validator: _validateOtp,
              onChanged: (value) => _otpCtrl.text = value,
              onCompleted: (value) => _otpCtrl.text = value,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _verifyingOtp ? null : () => _verifyOtp(),
              child: _verifyingOtp
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Verify OTP'),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive any code? "),
                InkWell(
                  onTap:
                      (_sendingOtp || _verifyingOtp) ? null : () => _sendOtp(),
                  child: Text(
                    'Resend Code',
                    style: TextStyle(
                      color: (_sendingOtp || _verifyingOtp)
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Step _securityStep() {
    return Step(
      title: const Text('Security & consent'),
      isActive: _currentStep >= 2,
      state: StepState.indexed,
      content: Form(
        key: _passwordFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure1,
              decoration: _fieldDecoration(
                label: 'Password',
                prefix: Icons.lock_outline,
                suffix: _hasPasswordText1
                    ? IconButton(
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
                        icon: Icon(_obscure1
                            ? Icons.visibility
                            : Icons.visibility_off),
                      )
                    : null,
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscure2,
              decoration: _fieldDecoration(
                label: 'Confirm password',
                prefix: Icons.lock_reset_outlined,
                suffix: _hasPasswordText2
                    ? IconButton(
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                        icon: Icon(_obscure2
                            ? Icons.visibility
                            : Icons.visibility_off),
                      )
                    : null,
              ),
              validator: _validateConfirm,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _agree,
                  onChanged: (value) => setState(() => _agree = value ?? false),
                ),
                Expanded(
                  child: Wrap(
                    children: [
                      const Text('I agree to the '),
                      _LinkText(
                        label: 'Terms & Conditions',
                        onTap: () => showSuccessSnackBar(context, 'Open Terms URL'),
                      ),
                      const Text(' and '),
                      _LinkText(
                        label: 'Privacy Policy',
                        onTap: () => showSuccessSnackBar(context, 'Open Privacy URL'),
                      ),
                      const Text('.'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _registering ? null : _completeSignup,
              icon: _registering
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label:
                  Text(_registering ? 'Creating accountâ€¦' : 'Create account'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = <Step>[
      _basicInfoStep(),
      _otpStep(),
      _securityStep(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: Stepper(
        currentStep: _currentStep,
        onStepTapped: (index) {
          // Allow navigation backward freely; forward only if prerequisites satisfied.
          if (index <= _currentStep) {
            setState(() => _currentStep = index);
            return;
          }
          if (index == 1) {
            if (_otpSent) {
              setState(() => _currentStep = 1);
            } else {
              _sendOtp();
            }
            return;
          }
          if (index == 2 && _otpVerified) {
            setState(() => _currentStep = 2);
          }
        },
        controlsBuilder: (context, details) => const SizedBox.shrink(),
        steps: steps,
      ),
    );
  }
}

class _LinkText extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LinkText({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          decoration: TextDecoration.underline,
          decorationColor: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class OtpBoxField extends StatefulWidget {
  final int length;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  const OtpBoxField(
      {super.key,
      this.length = 6,
      this.validator,
      this.onChanged,
      this.onCompleted});

  @override
  State<OtpBoxField> createState() => _OtpBoxFieldState();
}

class _OtpBoxFieldState extends State<OtpBoxField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late final List<String> _lastValues;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _lastValues = List.generate(widget.length, (_) => '');
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleChange(
      FormFieldState<String> fieldState, int index, String value) {
    final joined = _controllers.map((c) => c.text).join();
    fieldState.didChange(joined);
    widget.onChanged?.call(joined);

    final previous = _lastValues[index];
    if (value.isNotEmpty && value.length == 1) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && previous.isNotEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      final controller = _controllers[index - 1];
      controller.selection =
          TextSelection.collapsed(offset: controller.text.length);
    }

    _lastValues[index] = value;

    if (joined.length == widget.length) {
      widget.onCompleted?.call(joined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);
    final errorStyle =
        TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12);

    return FormField<String>(
      validator: widget.validator,
      builder: (fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.length, (index) {
                return SizedBox(
                  width: 48,
                  height: 56,
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.backspace) {
                        if (_controllers[index].text.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                          Future.microtask(() {
                            _controllers[index - 1].clear();
                            final joined =
                                _controllers.map((c) => c.text).join();
                            fieldState.didChange(joined);
                            widget.onChanged?.call(joined);
                          });
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: borderRadius),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: borderRadius,
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: borderRadius,
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2),
                        ),
                      ),
                      onChanged: (value) =>
                          _handleChange(fieldState, index, value),
                    ),
                  ),
                );
              }),
            ),
            if (fieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(fieldState.errorText!, style: errorStyle),
              ),
          ],
        );
      },
    );
  }
}