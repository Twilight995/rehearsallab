import 'package:go_router/go_router.dart';
import 'package:rehearsallab/app/router/app_page.dart';

/// AppPage.values로 일괄 생성 (unitask 동일). 이동은 context.goNamed / pushNamed + queryParameters.
final appRouter = GoRouter(
  initialLocation: AppPage.splash.path,
  routes: AppPage.values.map((e) {
    return GoRoute(
      name: e.name,
      path: e.path,
      builder: (context, state) => e.page(state.uri.queryParameters),
    );
  }).toList(),
);
