import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:rehearsallab/app/router/app_page.dart';

/// query parameter와 `extra`(`Map<String, String>`만 허용)를 병합한다. query가 우선.
@visibleForTesting
Map<String, String> mergeRouteParams(GoRouterState state) {
  final merged = <String, String>{};
  final extra = state.extra;
  if (extra is Map) {
    for (final e in extra.entries) {
      if (e.key is String && e.value is String) {
        merged[e.key as String] = e.value as String;
      }
    }
  }
  merged.addAll(state.uri.queryParameters);
  return merged;
}

/// 필수 인자가 비어 있으면 홈으로 보낸다. 정상이면 null.
@visibleForTesting
String? guardRequiredParams(AppPage page, Map<String, String> params) {
  for (final key in page.requiredParams) {
    final value = params[key];
    if (value == null || value.trim().isEmpty) return AppPage.home.path;
  }
  return null;
}

GoRouter buildAppRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation ?? AppPage.splash.path,
  routes: AppPage.values.map((e) {
    return GoRoute(
      name: e.name,
      path: e.path,
      redirect: (context, state) =>
          guardRequiredParams(e, mergeRouteParams(state)),
      builder: (context, state) => e.page(mergeRouteParams(state)),
    );
  }).toList(),
);

/// AppPage.values로 일괄 생성 (unitask 동일). 이동은
/// `context.go(AppPage.recording.location({RouteParam.presentationId: id, RouteParam.scriptVersionId: vid}))`
/// 또는 `context.pushNamed(AppPage.recording.name, queryParameters: {...})`.
final appRouter = buildAppRouter();
