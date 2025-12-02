// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// import 'package:common/widgets/widgets.dart';

// class ForgotPasswordScreen extends StatefulWidget {
//   const ForgotPasswordScreen({super.key});

//   @override
//   State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
// }

// class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
//   int _step = 0;
//   final _emailFormKey = GlobalKey<FormState>();
//   final _otpFormKey = GlobalKey<FormState>();
//   final _resetFormKey = GlobalKey<FormState>();

//   final _emailCtrl = TextEditingController();
//   final _otpCtrl = TextEditingController();
//   final _newPassCtrl = TextEditingController();
//   final _confirmPassCtrl = TextEditingController();

//   bool _otpSent = false;
//   bool _otpVerified = false;
//   static const String _mockOtp = '654321';

//   bool _obscureNew = true;
//   bool _obscureConfirm = true;
//   bool _hasNewPasswordText = false;
//   bool _hasConfirmPasswordText = false;

//   @override
//   void initState() {
//     super.initState();
//     _newPassCtrl.addListener(() => setState(() => _hasNewPasswordText = _newPassCtrl.text.isNotEmpty));
//     _confirmPassCtrl
//         .addListener(() => setState(() => _hasConfirmPasswordText = _confirmPassCtrl.text.isNotEmpty));
//   }

//   @override
//   void dispose() {
//     _emailCtrl.dispose();
//     _otpCtrl.dispose();
//     _newPassCtrl.dispose();
//     _confirmPassCtrl.dispose();
//     super.dispose();
//   }

//   String? _validateEmail(String? value) {
//     if (value == null || value.trim().isEmpty) return 'Enter your email';
//     final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
//     return ok ? null : 'Enter a valid email';
//   }

//   String? _validateOtp(String? value) {
//     if (!_otpSent) return 'Tap "Send OTP" first';
//     if (value == null || value.trim().isEmpty) return 'Enter the OTP';
//     if (value.trim().length != 6) return 'OTP must be 6 digits';
//     return null;
//   }

//   String? _validatePassword(String? value) {
//     if (value == null || value.isEmpty) return 'Enter a new password';
//     if (value.length < 8) return 'Use at least 8 characters';
//     if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add at least 1 uppercase letter';
//     if (!RegExp(r'[0-9]').hasMatch(value)) return 'Add at least 1 number';
//     return null;
//   }

//   String? _validateConfirmPassword(String? value) {
//     if (value == null || value.isEmpty) return 'Confirm your new password';
//     if (value != _newPassCtrl.text) return 'Passwords do not match';
//     return null;
//   }

//   void _sendOtp() {
//     if (_emailFormKey.currentState!.validate()) {
//       setState(() {
//         _otpSent = true;
//         _step = 1;
//       });
//       showSuccessSnackBar(context, 'OTP sent (demo code: 654321)');
//     }
//   }

//   void _verifyOtp() {
//     if (_otpFormKey.currentState!.validate()) {
//       if (_otpCtrl.text.trim() == _mockOtp) {
//         setState(() {
//           _otpVerified = true;
//           _step = 2;
//         });
//         showSuccessSnackBar(context, 'OTP verified');
//       } else {
//         showErrorSnackBar(context, 'Invalid OTP');
//       }
//     }
//   }

//   void _resetPassword() {
//     if (!_otpVerified) {
//       showErrorSnackBar(context, 'Verify OTP before resetting password');
//       return;
//     }
//     if (_resetFormKey.currentState!.validate()) {
//       showSuccessSnackBar(context, 'Password updated (demo)');
//       Navigator.pop(context);
//     }
//   }

//   Widget _buildStepContent() {
//     switch (_step) {
//       case 0:
//         return Form(
//           key: _emailFormKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const Text('Enter your registered email to receive a one-time password (OTP).'),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _emailCtrl,
//                 keyboardType: TextInputType.emailAddress,
//                 decoration: _fieldDecoration(
//                   label: 'Email',
//                   prefix: Icons.alternate_email_outlined,
//                   suffix: InkWell(
//                     onTap: _sendOtp,
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                       child: Text(
//                         'Send OTP',
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.primary,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 validator: _validateEmail,
//               ),
//             ],
//           ),
//         );
//       case 1:
//         return Form(
//           key: _otpFormKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Text(
//                 'Verify OTP Now',
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Enter the 6-digit code sent to your email.',
//                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                       color: Theme.of(context).colorScheme.onSurfaceVariant,
//                     ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 20),
//               OtpBoxField(
//                 length: 6,
//                 validator: _validateOtp,
//                 onChanged: (value) => _otpCtrl.text = value,
//                 onCompleted: (value) => _otpCtrl.text = value,
//               ),
//               const SizedBox(height: 16),
//               FilledButton(
//                 onPressed: _verifyOtp,
//                 child: const Text('Verify OTP'),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text("Didn't receive any code? "),
//                   InkWell(
//                     onTap: _sendOtp,
//                     child: Text(
//                       'Resend Code',
//                       style: TextStyle(
//                         color: Theme.of(context).colorScheme.primary,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       default:
//         return Form(
//           key: _resetFormKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const Text('Create your new password.'),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _newPassCtrl,
//                 obscureText: _obscureNew,
//                 decoration: _fieldDecoration(
//                   label: 'New password',
//                   prefix: Icons.lock_outline,
//                   suffix: _hasNewPasswordText
//                       ? IconButton(
//                           onPressed: () => setState(() => _obscureNew = !_obscureNew),
//                           icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
//                         )
//                       : null,
//                 ),
//                 validator: _validatePassword,
//               ),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _confirmPassCtrl,
//                 obscureText: _obscureConfirm,
//                 decoration: _fieldDecoration(
//                   label: 'Confirm new password',
//                   prefix: Icons.lock_reset_outlined,
//                   suffix: _hasConfirmPasswordText
//                       ? IconButton(
//                           onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
//                           icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
//                         )
//                       : null,
//                 ),
//                 validator: _validateConfirmPassword,
//               ),
//               const SizedBox(height: 16),
//               FilledButton.icon(
//                 onPressed: _resetPassword,
//                 icon: const Icon(Icons.check_circle_outline),
//                 label: const Text('Update password'),
//               ),
//             ],
//           ),
//         );
//     }
//   }

//   InputDecoration _fieldDecoration({required String label, IconData? prefix, Widget? suffix}) {
//     return InputDecoration(
//       labelText: label,
//       prefixIcon: prefix != null ? Icon(prefix) : null,
//       suffixIcon: suffix,
//       border: const OutlineInputBorder(
//         borderRadius: BorderRadius.all(Radius.circular(25)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Forgot password')),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 480),
//             child: Card(
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 200),
//                   child: _buildStepContent(),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class OtpBoxField extends StatefulWidget {
//   final int length;
//   final FormFieldValidator<String>? validator;
//   final ValueChanged<String>? onChanged;
//   final ValueChanged<String>? onCompleted;

//   const OtpBoxField({super.key, this.length = 6, this.validator, this.onChanged, this.onCompleted});

//   @override
//   State<OtpBoxField> createState() => _OtpBoxFieldState();
// }

// class _OtpBoxFieldState extends State<OtpBoxField> {
//   late final List<TextEditingController> _controllers;
//   late final List<FocusNode> _focusNodes;
//   late final List<String> _lastValues;

//   @override
//   void initState() {
//     super.initState();
//     _controllers = List.generate(widget.length, (_) => TextEditingController());
//     _focusNodes = List.generate(widget.length, (_) => FocusNode());
//     _lastValues = List.generate(widget.length, (_) => '');
//   }

//   @override
//   void dispose() {
//     for (final controller in _controllers) {
//       controller.dispose();
//     }
//     for (final node in _focusNodes) {
//       node.dispose();
//     }
//     super.dispose();
//   }

//   void _handleChange(FormFieldState<String> fieldState, int index, String value) {
//     final joined = _controllers.map((c) => c.text).join();
//     fieldState.didChange(joined);
//     widget.onChanged?.call(joined);

//     final previous = _lastValues[index];
//     if (value.isNotEmpty && value.length == 1) {
//       if (index < widget.length - 1) {
//         _focusNodes[index + 1].requestFocus();
//       } else {
//         _focusNodes[index].unfocus();
//       }
//     } else if (value.isEmpty && previous.isNotEmpty && index > 0) {
//       _focusNodes[index - 1].requestFocus();
//       final controller = _controllers[index - 1];
//       controller.selection = TextSelection.collapsed(offset: controller.text.length);
//     }

//     _lastValues[index] = value;

//     if (joined.length == widget.length) {
//       widget.onCompleted?.call(joined);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final borderRadius = BorderRadius.circular(8);
//     final errorStyle = TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12);

//     return FormField<String>(
//       validator: widget.validator,
//       builder: (fieldState) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: List.generate(widget.length, (index) {
//                 return SizedBox(
//                   width: 48,
//                   height: 56,
//                   child: Focus(
//                     onKeyEvent: (node, event) {
//                       if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
//                         if (_controllers[index].text.isEmpty && index > 0) {
//                           _focusNodes[index - 1].requestFocus();
//                           Future.microtask(() {
//                             _controllers[index - 1].clear();
//                             final joined = _controllers.map((c) => c.text).join();
//                             fieldState.didChange(joined);
//                             widget.onChanged?.call(joined);
//                           });
//                           return KeyEventResult.handled;
//                         }
//                       }
//                       return KeyEventResult.ignored;
//                     },
//                     child: TextField(
//                       controller: _controllers[index],
//                       focusNode: _focusNodes[index],
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                       maxLength: 1,
//                       keyboardType: TextInputType.number,
//                       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                       decoration: InputDecoration(
//                         counterText: '',
//                         contentPadding: EdgeInsets.zero,
//                         border: OutlineInputBorder(borderRadius: borderRadius),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: borderRadius,
//                           borderSide: const BorderSide(color: Colors.grey),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: borderRadius,
//                           borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
//                         ),
//                       ),
//                       onChanged: (value) => _handleChange(fieldState, index, value),
//                     ),
//                   ),
//                 );
//               }),
//             ),
//             if (fieldState.hasError)
//               Padding(
//                 padding: const EdgeInsets.only(top: 6),
//                 child: Text(fieldState.errorText!, style: errorStyle),
//               ),
//           ],
//         );
//       },
//     );
//   }
// }





import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:common/widgets/widgets.dart';
import 'package:common/api/api_client.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _otpSent = false;
  bool _otpVerified = false;
  String? _otpToken;
  final ApiClient _api = ApiClient();
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _resetting = false;

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _hasNewPasswordText = false;
  bool _hasConfirmPasswordText = false;

  @override
  void initState() {
    super.initState();
    _newPassCtrl.addListener(() => setState(() => _hasNewPasswordText = _newPassCtrl.text.isNotEmpty));
    _confirmPassCtrl
        .addListener(() => setState(() => _hasConfirmPasswordText = _confirmPassCtrl.text.isNotEmpty));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
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
    if (value == null || value.isEmpty) return 'Enter a new password';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add at least 1 uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Add at least 1 number';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your new password';
    if (value != _newPassCtrl.text) return 'Passwords do not match';
    return null;
  }

  void _sendOtp() {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _sendingOtp = true;
    });

    _api.sendPasswordResetOtp(email).then((result) {
      if (!mounted) return;
      setState(() => _sendingOtp = false);
      final (ok, err) = result;
      if (!ok) {
        showErrorSnackBar(context, err ?? 'Failed to send OTP');
        return;
      }
      setState(() {
        _otpSent = true;
        _step = 1;
      });
      showSuccessSnackBar(context, 'OTP sent to $email');
    });
  }

  void _verifyOtp() {
    if (!(_otpFormKey.currentState?.validate() ?? false)) return;
    if (!_otpSent) {
      showErrorSnackBar(context, 'Please request an OTP first');
      return;
    }
    final email = _emailCtrl.text.trim();
    final code = _otpCtrl.text.trim();
    if (email.isEmpty || code.isEmpty) return;

    setState(() => _verifyingOtp = true);
    _api.verifyPasswordResetOtp(email: email, code: code).then((result) {
      if (!mounted) return;
      setState(() => _verifyingOtp = false);
      final (ok, err, token) = result;
      if (!ok || token == null) {
        showErrorSnackBar(context, err ?? 'OTP verification failed');
        return;
      }
      setState(() {
        _otpVerified = true;
        _otpToken = token;
        _step = 2;
      });
      showSuccessSnackBar(context, 'OTP verified');
    });
  }

  void _resetPassword() {
    if (!_otpVerified) {
      showErrorSnackBar(context, 'Verify OTP before resetting password');
      return;
    }
    if (!(_resetFormKey.currentState?.validate() ?? false)) return;
    final token = _otpToken;
    final newPass = _newPassCtrl.text;
    if (token == null) {
      showErrorSnackBar(context, 'Missing verification token. Please verify OTP again.');
      return;
    }

    setState(() => _resetting = true);
    _api.resetPassword(token: token, newPassword: newPass).then((result) {
      if (!mounted) return;
      setState(() => _resetting = false);
      final (ok, err) = result;
      if (!ok) {
        showErrorSnackBar(context, err ?? 'Password reset failed');
        return;
      }
      showSuccessSnackBar(context, 'Password updated');
      Navigator.pop(context);
    });
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return Form(
          key: _emailFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Enter your registered email to receive a one-time password (OTP).'),
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
                          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2)),
                        )
                      : InkWell(
                          onTap: _sendOtp,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        );
      case 1:
        return Form(
          key: _otpFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verify OTP Now',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to your email.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OtpBoxField(
                length: 6,
                validator: _validateOtp,
                onChanged: (value) => _otpCtrl.text = value,
                onCompleted: (value) => _otpCtrl.text = value,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _verifyingOtp ? null : _verifyOtp,
                child: const Text('Verify OTP'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive any code? "),
                  InkWell(
                    onTap: _sendOtp,
                    child: Text(
                      'Resend Code',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      default:
        return Form(
          key: _resetFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create your new password.'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPassCtrl,
                obscureText: _obscureNew,
                decoration: _fieldDecoration(
                  label: 'New password',
                  prefix: Icons.lock_outline,
                  suffix: _hasNewPasswordText
                      ? IconButton(
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                        )
                      : null,
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPassCtrl,
                obscureText: _obscureConfirm,
                decoration: _fieldDecoration(
                  label: 'Confirm new password',
                  prefix: Icons.lock_reset_outlined,
                  suffix: _hasConfirmPasswordText
                      ? IconButton(
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                        )
                      : null,
                ),
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _resetting ? null : _resetPassword,
                icon: _resetting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_resetting ? 'Updating...' : 'Update password'),
              ),
            ],
          ),
        );
    }
  }

  InputDecoration _fieldDecoration({required String label, IconData? prefix, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefix != null ? Icon(prefix) : null,
      suffixIcon: suffix,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(25)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildStepContent(),
                ),
              ),
            ),
          ),
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

  const OtpBoxField({super.key, this.length = 6, this.validator, this.onChanged, this.onCompleted});

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

  void _handleChange(FormFieldState<String> fieldState, int index, String value) {
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
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    }

    _lastValues[index] = value;

    if (joined.length == widget.length) {
      widget.onCompleted?.call(joined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);
    final errorStyle = TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12);

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
                      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                        if (_controllers[index].text.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                          Future.microtask(() {
                            _controllers[index - 1].clear();
                            final joined = _controllers.map((c) => c.text).join();
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
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                      ),
                      onChanged: (value) => _handleChange(fieldState, index, value),
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