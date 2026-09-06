/// 서비스 반환 타입 (unitask 동일).
/// 명령: `Future<Result<T>>` · 순수 동기 계산: `Result<T>` · 관찰: `Stream<T>`
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final Exception exception;
  const Failure(this.exception);
}
