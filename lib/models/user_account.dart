// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

/// 로컬 계정 (04 로그인 · 05 가입). 비밀번호는 이 모델에 담지 않는다 — 해시는 AuthService 저장소 전용.
/// 원고 · 녹음 · 동의 기록은 `id`에 묶인다 (통합 문서 5장 ConsentRecord.userId).
class UserAccount {
  final String id;
  final String email;
  final DateTime createdAt;

  const UserAccount({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  /// 07 홈 인사말용 표시 이름: 이메일의 @ 앞부분 (별도 이름 입력 없음).
  String get displayName {
    final at = email.indexOf('@');
    return at <= 0 ? email : email.substring(0, at);
  }

  UserAccount copyWith({String? id, String? email, DateTime? createdAt}) =>
      UserAccount(
        id: id ?? this.id,
        email: email ?? this.email,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'email': email,
    'created_at': createdAt.toIso8601String(),
  };

  factory UserAccount.fromMap(Map<String, dynamic> map) => UserAccount(
    id: map['id'] as String,
    email: map['email'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  String toJson() => json.encode(toMap());

  factory UserAccount.fromJson(String source) =>
      UserAccount.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAccount &&
          other.id == id &&
          other.email == email &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, email, createdAt);

  @override
  String toString() => 'UserAccount(id: $id, email: $email)';
}
