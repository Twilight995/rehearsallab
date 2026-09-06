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

/// 라우트 인자 키. **인자는 항상 query parameter로 전달한다** (계약서 3.2 · 5장 경계).
/// `extra`로 `Map<String, String>`을 넘겨도 같은 키로 병합되지만, 문자열 하나만 넘기는 방식은 허용하지 않는다.
class RouteParam {
  RouteParam._();

  static const String presentationId = 'presentationId';
  static const String scriptVersionId = 'scriptVersionId';
  static const String rehearsalId = 'rehearsalId';
  static const String tab = 'tab';
  static const String step = 'step';
}

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

  /// 이 라우트에 반드시 있어야 하는 인자. 비어 있으면 라우터가 홈으로 보낸다.
  List<String> get requiredParams => switch (this) {
    AppPage.presentationDetail ||
    AppPage.micPermission => const [RouteParam.presentationId],
    AppPage.recording => const [
      RouteParam.presentationId,
      RouteParam.scriptVersionId,
    ],
    AppPage.processing || AppPage.report => const [RouteParam.rehearsalId],
    _ => const [],
  };

  /// 인자를 붙인 location 문자열. `context.go(AppPage.recording.location({...}))`
  String location([Map<String, String> params = const {}]) {
    if (params.isEmpty) return path;
    return Uri(path: path, queryParameters: params).toString();
  }

  /// query(+extra 병합) 인자로 페이지를 만든다. 필수 인자 검증은 라우터 redirect가 담당한다.
  Widget page(Map<String, String> params) => switch (this) {
    AppPage.splash => const SplashPage(),
    AppPage.onboardingIntro => const OnboardingIntroPage(),
    AppPage.onboardingPrivacy => const OnboardingPrivacyPage(),
    AppPage.login => const LoginPage(),
    AppPage.signup => const SignupPage(),
    AppPage.home => const HomePage(),
    AppPage.presentationForm => PresentationFormPage(
      presentationId: params[RouteParam.presentationId],
    ),
    AppPage.settings => const SettingsPage(),
    AppPage.deleteConfirm => DeleteConfirmPage(
      step: int.tryParse(params[RouteParam.step] ?? '1') ?? 1,
    ),
    AppPage.presentationDetail => PresentationDetailPage(
      presentationId: params[RouteParam.presentationId]!,
      initialTab: params[RouteParam.tab],
    ),
    AppPage.micPermission => MicPermissionPage(
      presentationId: params[RouteParam.presentationId]!,
    ),
    AppPage.recording => RecordingPage(
      presentationId: params[RouteParam.presentationId]!,
      scriptVersionId: params[RouteParam.scriptVersionId]!,
    ),
    AppPage.processing => ProcessingPage(
      rehearsalId: params[RouteParam.rehearsalId]!,
    ),
    AppPage.report => ReportPage(rehearsalId: params[RouteParam.rehearsalId]!),
  };
}
