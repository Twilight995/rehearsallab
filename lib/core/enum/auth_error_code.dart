/// 04 로그인 · 05 가입 실패 원인. 문구는 AppStrings.authError(code).
/// 로그인 실패는 "이메일 없음"과 "비밀번호 틀림"을 구분하지 않는다(계정 존재 여부 노출 방지).
enum AuthErrorCode {
  invalidEmail,
  passwordTooShort,
  passwordMismatch,
  emailTaken,
  invalidCredentials,

  /// 계정 저장소 읽기 · 쓰기 실패 (손상된 JSON 등). 데이터를 자동 삭제하지 않고 알린다.
  storage,

  /// 인증은 됐지만 동의 기록을 계정에 묶지 못함. 세션을 만들지 않고 다시 시도하게 한다.
  consentBind,
}

extension AuthErrorCodeExtension on AuthErrorCode {
  static AuthErrorCode fromName(String name) => AuthErrorCode.values.firstWhere(
    (e) => e.name == name,
    orElse: () => AuthErrorCode.invalidCredentials,
  );
}
