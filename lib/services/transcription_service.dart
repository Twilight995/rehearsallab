import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/provider_config.dart';

/// 전사 구간.
class TranscriptSegment {
  final int startSec;
  final int endSec;
  final String text;

  const TranscriptSegment({
    required this.startSec,
    required this.endSec,
    required this.text,
  });
}

/// 받아쓰기 결과. 전체 전사문은 녹음과 같은 보관 정책을 따르며 Report에 복사하지 않는다.
class Transcript {
  final List<TranscriptSegment> segments;

  const Transcript({required this.segments});

  int get wordCount => segments.fold(
    0,
    (sum, s) => sum + s.text.trim().split(RegExp(r'\s+')).length,
  );

  String get fullText => segments.map((s) => s.text).join(' ');
}

/// 음성인식 (X1-4 Mock → X2-1 Http). 녹음만 STT 제공사로 보낸다.
abstract class TranscriptionService {
  Future<Result<Transcript>> transcribe({
    required String audioFilePath,
    required ProviderEntry? provider,
  });
}

/// 데모 전사문을 돌려주는 Mock. failure로 19번(전송 후 실패) 화면을 재현할 수 있다.
class MockTranscriptionService implements TranscriptionService {
  final Duration delay;
  final bool fail;

  const MockTranscriptionService({
    this.delay = const Duration(seconds: 2),
    this.fail = false,
  });

  static const Transcript demoTranscript = Transcript(
    segments: [
      TranscriptSegment(
        startSec: 4,
        endSec: 40,
        text:
            '최근 대규모 언어모델은 학술 발표 준비 과정에서도 활용되고 있으나 발표자의 실제 전달 방식까지 다루는 도구는 드뭅니다',
      ),
      TranscriptSegment(
        startSec: 41,
        endSec: 119,
        text: '발표 전날 어 피드백을 줄 사람이 없는 대학원생은 원고를 혼자 읽어 보는 것 외에 선택지가 거의 없습니다',
      ),
      TranscriptSegment(
        startSec: 122,
        endSec: 165,
        text: '기존 도구는 원고의 문법만 보거나 녹음의 속도만 측정할 뿐 두 정보를 연결해 해석하지 않습니다',
      ),
      TranscriptSegment(
        startSec: 166,
        endSec: 209,
        text: '그래서 어디가 왜 문제인지를 근거와 함께 돌려주지 못합니다',
      ),
      TranscriptSegment(
        startSec: 242,
        endSec: 270,
        text:
            '우리는 원고를 섹션 단위로 구조화한 뒤 전사문을 원고 문장과 하나씩 맞춰 보고 정렬 이를 통해 그니까 어 여기서 정렬이라는 게 중요한데요',
      ),
      TranscriptSegment(
        startSec: 271,
        endSec: 300,
        text: '정렬 비용을 크게 줄여 실시간 처리가 가능하도록 계층적 정렬을 도입했습니다',
      ),
      TranscriptSegment(
        startSec: 301,
        endSec: 330,
        text: '코드가 측정한 지표를 LLM이 해석하도록 설계했습니다',
      ),
      TranscriptSegment(
        startSec: 522,
        endSec: 597,
        text:
            '파일럿 12명 대상 실험에서 그니까 어 결과적으로 일치율이 9%p 올랐는데 두 번째 리허설의 원고 일치율이 평균 9%p 상승했습니다',
      ),
      TranscriptSegment(
        startSec: 598,
        endSec: 689,
        text:
            '속도 급상승 구간과 필러가 집중된 구간을 사용자가 스스로 확인한 뒤 원고를 수정한 비율은 83%였습니다 음 이건 나중에 다시 말씀드릴게요',
      ),
      TranscriptSegment(
        startSec: 691,
        endSec: 760,
        text: '측정과 해석을 분리한 파이프라인 그리고 원고 전달 문제를 구분해 되돌려 주는 피드백 루프를 제안합니다',
      ),
    ],
  );

  @override
  Future<Result<Transcript>> transcribe({
    required String audioFilePath,
    required ProviderEntry? provider,
  }) async {
    await Future<void>.delayed(delay);
    if (fail) return Failure(Exception('네트워크 오류로 전송이 중단됐습니다.'));
    return const Success(demoTranscript);
  }
}
