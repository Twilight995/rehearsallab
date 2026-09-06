import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/auth/auth_provider.dart';
import 'package:rehearsallab/services/auth_service.dart';
import 'package:rehearsallab/ui/common/auth_form_frame.dart';
import 'package:rehearsallab/ui/common/label_text_field.dart';

/// 05 가입 (`ZiY21`). 성공 → 06 빈 홈. 뒤로가기 → 04 로그인.
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final invalid = AuthService.validate(
      _email.text,
      _password.text,
      passwordConfirm: _confirm.text,
    );
    if (invalid != null) {
      setState(() => _error = AppStrings.authError(invalid));
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    final result = await ref
        .read(authNotifierProvider.notifier)
        .signUp(_email.text, _password.text);
    if (!mounted) return;
    switch (result) {
      case Success():
        context.go(AppPage.home.path);
      case Failure(:final exception):
        setState(() {
          _submitting = false;
          _error = exception is AuthException
              ? AppStrings.authError(exception.code)
              : AppStrings.authErrorUnknown;
        });
    }
  }

  void _toLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppPage.login.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormFrame(
      title: AppStrings.signupTitle,
      subtitle: AppStrings.signupSubtitle,
      onBack: _toLogin,
      fields: [
        LabelTextField(
          label: AppStrings.authEmailLabel,
          hintText: AppStrings.authEmailHint,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
        ),
        LabelTextField(
          label: AppStrings.authPasswordLabel,
          hintText: AppStrings.authPasswordHint,
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
        ),
        LabelTextField(
          label: AppStrings.authPasswordConfirmLabel,
          hintText: AppStrings.authPasswordConfirmHint,
          controller: _confirm,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
      ],
      errorText: _error,
      submitLabel: AppStrings.signupButton,
      submitting: _submitting,
      onSubmit: _submit,
      altActions: [
        AuthAltButton(label: AppStrings.signupToLogin, onPressed: _toLogin),
      ],
    );
  }
}
