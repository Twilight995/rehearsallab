import 'package:flutter/material.dart';
import 'package:rehearsallab/ui/pages/delete_confirm/delete_confirm_page.dart';
import 'package:rehearsallab/ui/pages/home/home_page.dart';
import 'package:rehearsallab/ui/pages/login/login_page.dart';
import 'package:rehearsallab/ui/pages/mic_permission/mic_permission_page.dart';
import 'package:rehearsallab/ui/pages/onboarding_intro/onboarding_intro_page.dart';
import 'package:rehearsallab/ui/pages/onboarding_privacy/onboarding_privacy_page.dart';
import 'package:rehearsallab/ui/pages/presentation_detail/presentation_detail_page.dart';
import 'package:rehearsallab/ui/pages/presentation_form/presentation_form_page.dart';
import 'package:rehearsallab/ui/pages/processing/processing_page.dart';
import 'package:rehearsallab/ui/pages/recording/recording_page.dart';
import 'package:rehearsallab/ui/pages/report/report_page.dart';
import 'package:rehearsallab/ui/pages/settings/settings_page.dart';
import 'package:rehearsallab/ui/pages/signup/signup_page.dart';
import 'package:rehearsallab/ui/pages/splash/splash_page.dart';

/// 라우트 목록 (계약서 3.2). 통합 문서 화면 번호와 1:1.
/// 바텀시트(27 · 28 · 29 · 37)는 라우트가 아니라 `show<Name>Sheet` 함수.
/// 상세 탭(원고 · 리허설 · Q&A · 이력)은 presentationDetail 안의 탭. 딥링크는 `?tab=script`.
enum AppPage {
  splash,
  onboardingIntro,
  onboardingPrivacy,
  login,
  signup,
  home,
  presentationForm,
  settings,
  deleteConfirm,
  presentationDetail,
  micPermission,
  recording,
  processing,
  report,
}

extension AppPageExtension on AppPage {
  String get path => '/$name';

  /// 필요한 파라미터는 query로 받는다 (presentationId, rehearsalId, tab, step)
  Widget page(Map<String, String> query) => switch (this) {
    AppPage.splash => const SplashPage(),
    AppPage.onboardingIntro => const OnboardingIntroPage(),
    AppPage.onboardingPrivacy => const OnboardingPrivacyPage(),
    AppPage.login => const LoginPage(),
    AppPage.signup => const SignupPage(),
    AppPage.home => const HomePage(),
    AppPage.presentationForm => PresentationFormPage(
      presentationId: query['presentationId'],
    ),
    AppPage.settings => const SettingsPage(),
    AppPage.deleteConfirm => DeleteConfirmPage(
      step: int.tryParse(query['step'] ?? '1') ?? 1,
    ),
    AppPage.presentationDetail => PresentationDetailPage(
      presentationId: query['presentationId'] ?? '',
      initialTab: query['tab'],
    ),
    AppPage.micPermission => MicPermissionPage(
      presentationId: query['presentationId'] ?? '',
    ),
    AppPage.recording => RecordingPage(
      presentationId: query['presentationId'] ?? '',
      scriptVersionId: query['scriptVersionId'] ?? '',
    ),
    AppPage.processing => ProcessingPage(
      rehearsalId: query['rehearsalId'] ?? '',
    ),
    AppPage.report => ReportPage(rehearsalId: query['rehearsalId'] ?? ''),
  };
}
