/// 04 로그인 · 05 가입 실패 원인. 문구는 AppStrings.authError(code).
/// 로그인 실패는 "이메일 없음"과 "비밀번호 틀림"을 구분하지 않는다(계정 존재 여부 노출 방지).
enum AuthErrorCode {
  invalidEmail,
  passwordTooShort,
  passwordMismatch,
  emailTaken,
  invalidCredentials,
}

extension AuthErrorCodeExtension on AuthErrorCode {
  static AuthErrorCode fromName(String name) => AuthErrorCode.values.firstWhere(
    (e) => e.name == name,
    orElse: () => AuthErrorCode.invalidCredentials,
  );
}
