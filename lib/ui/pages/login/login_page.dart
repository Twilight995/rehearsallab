import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/core/extension/build_context_extension.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/auth/auth_provider.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/models/user_account.dart';
import 'package:rehearsallab/services/auth_service.dart';
import 'package:rehearsallab/ui/common/auth_form_frame.dart';
import 'package:rehearsallab/ui/common/label_text_field.dart';

/// 04 로그인 (`l6Fzv`). 성공 → 06/07 홈. 뒤로가기 → 03 동의.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final invalid = AuthService.validate(_email.text, _password.text);
    if (invalid != null) {
      setState(() => _error = AppStrings.authError(invalid));
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    await _finish(
      () => ref
          .read(authNotifierProvider.notifier)
          .signIn(_email.text, _password.text),
    );
  }

  /// 성공: 이 계정의 동의가 현재 버전이면 홈, 아니면 03 재동의. 실패 · 예외: 문구 표시 후 다시 시도 가능.
  Future<void> _finish(Future<Result<UserAccount>> Function() action) async {
    Result<UserAccount> result;
    try {
      result = await action();
    } on Object catch (e) {
      // 저장소 · 서비스가 Result 밖으로 던진 예외(Error 포함)도 화면에서는 복구 가능해야 한다
      result = Failure(e is Exception ? e : Exception(e.toString()));
    }
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        final consented = await ref
            .read(consentNotifierProvider.notifier)
            .isCurrentFor(value.id);
        if (!mounted) return;
        context.go(
          consented ? AppPage.home.path : AppPage.onboardingPrivacy.path,
        );
      case Failure(:final exception):
        setState(() {
          _submitting = false;
          _error = exception is AuthException
              ? AppStrings.authError(exception.code)
              : AppStrings.authErrorUnknown;
        });
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppPage.onboardingPrivacy.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormFrame(
      title: AppStrings.loginTitle,
      subtitle: AppStrings.loginSubtitle,
      onBack: _back,
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
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
      ],
      errorText: _error,
      submitLabel: AppStrings.loginButton,
      submitting: _submitting,
      onSubmit: _submit,
      altActions: [
        AuthAltButton(
          label: AppStrings.loginToSignup,
          onPressed: () => context.push(AppPage.signup.path),
        ),
        AuthAltButton(
          label: AppStrings.loginForgot,
          muted: true,
          onPressed: () => context.showSnackbar(AppStrings.loginForgotNotice),
        ),
      ],
    );
  }
}
