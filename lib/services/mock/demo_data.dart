import 'package:rehearsallab/core/enum/audience.dart';
import 'package:rehearsallab/core/enum/audio_state.dart';
import 'package:rehearsallab/core/enum/dimension_key.dart';
import 'package:rehearsallab/core/enum/match_rate_scope.dart';
import 'package:rehearsallab/core/enum/presentation_type.dart';
import 'package:rehearsallab/core/enum/processing_stage.dart';
import 'package:rehearsallab/core/enum/script_version_origin.dart';
import 'package:rehearsallab/core/enum/sentence_state.dart';
import 'package:rehearsallab/core/enum/stage_state.dart';
import 'package:rehearsallab/core/enum/transcript_state.dart';
import 'package:rehearsallab/models/feedback.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/models/rehearsal.dart';
import 'package:rehearsallab/models/report.dart';
import 'package:rehearsallab/models/script_analysis.dart';
import 'package:rehearsallab/models/script_version.dart';

/// 통합 문서 8장 데모 데이터. Mock 서비스와 테스트가 같은 값을 쓴다.
/// 발표 2026-09-12 (D-3 기준일 2026-09-09), 리허설 #3 = 원고 v3, 12:40 / 15:00, 일치율 87% (전 회차 81%).
class DemoData {
  DemoData._();

  static final DateTime today = DateTime(2026, 9, 9, 21, 14);

  static const String presentationId = 'demo-presentation';
  static const String scriptV1Id = 'demo-script-v1';
  static const String scriptV2Id = 'demo-script-v2';
  static const String scriptV3Id = 'demo-script-v3';
  static const String consentVersion = 'demo-consent-v1';

  static final Presentation presentation = Presentation(
    id: presentationId,
    title: '○○학회 구두발표',
    type: PresentationType.conference,
    talkMinutes: 15,
    qaMinutes: 5,
    audience: Audience.adjacentField,
    date: DateTime(2026, 9, 12),
    createdAt: DateTime(2026, 9, 6, 10),
  );

  static final List<Presentation> presentations = [
    presentation,
    Presentation(
      id: 'demo-presentation-2',
      title: '석사 논문 심사',
      type: PresentationType.defense,
      talkMinutes: 20,
      qaMinutes: 10,
      audience: Audience.sameField,
      date: DateTime(2026, 9, 27),
      createdAt: DateTime(2026, 9, 5, 10),
    ),
    Presentation(
      id: 'demo-presentation-3',
      title: '랩 세미나: 실험 설계 공유',
      type: PresentationType.labSeminar,
      talkMinutes: 30,
      qaMinutes: 10,
      audience: Audience.adjacentField,
      createdAt: DateTime(2026, 9, 4, 10),
    ),
  ];

  /// 원고 v1 (assets/sample/sample_script.txt와 동일한 구조, 5섹션)
  static const String scriptV1Text = '''## 배경
최근 대규모 언어모델은 학술 발표 준비 과정에서도 활용되고 있으나, 발표자의 실제 전달 방식까지 다루는 도구는 드뭅니다. 발표 전날 피드백을 줄 사람이 없는 대학원생은 원고를 혼자 읽어 보는 것 외에 선택지가 거의 없습니다.

## 문제
기존 도구는 원고의 문법만 보거나 녹음의 속도만 측정할 뿐, 두 정보를 연결해 해석하지 않습니다. 그래서 "어디가 왜 문제인지"를 근거와 함께 돌려주지 못합니다.

## 방법
우리는 원고를 섹션 단위로 구조화한 뒤 전사문과 문장 단위로 정렬하고, 코드가 측정한 지표를 LLM이 해석하도록 설계했습니다. 파이프라인의 각 단계에서 토큰 단위 정렬 비용을 O(n·m)에서 O(n log m)으로 줄이기 위해 계층적 정렬을 도입했습니다. 각 단계는 독립적으로 실패할 수 있으며, 부분 결과를 반환합니다.

## 결과
파일럿 12명 대상 실험에서 두 번째 리허설의 원고 일치율이 평균 9%p 상승했습니다. 속도 급상승 구간과 필러가 집중된 구간을 사용자가 스스로 확인한 뒤 원고를 수정한 비율은 83%였습니다.

## 기여
측정과 해석을 분리한 파이프라인, 그리고 원고·전달 문제를 구분해 되돌려 주는 피드백 루프를 제안합니다.''';

  static const String rewrite1Original =
      '파이프라인의 각 단계에서 토큰 단위 정렬 비용을 O(n·m)에서 O(n log m)으로 줄이기 위해 계층적 정렬을 도입했습니다.';
  static const String rewrite1Replacement =
      '정렬 비용을 크게 줄여 실시간 처리가 가능하도록 계층적 정렬을 도입했습니다.';
  static const String rewrite2Original = '전사문과 문장 단위로 정렬하고';
  static const String rewrite2Replacement = '전사문을 원고 문장과 하나씩 맞춰 보고(정렬), 이를 통해';

  static final ScriptVersion scriptV1 = ScriptVersion(
    id: scriptV1Id,
    presentationId: presentationId,
    version: 1,
    text: scriptV1Text,
    createdBy: ScriptVersionOrigin.user,
    createdAt: DateTime(2026, 9, 6, 10, 5),
  );

  static final ScriptVersion scriptV2 = ScriptVersion(
    id: scriptV2Id,
    presentationId: presentationId,
    version: 2,
    text: scriptV1Text.replaceFirst(rewrite2Original, rewrite2Replacement),
    parentVersionId: scriptV1Id,
    createdBy: ScriptVersionOrigin.rewrite,
    createdAt: DateTime(2026, 9, 6, 10, 20),
  );

  static final ScriptVersion scriptV3 = ScriptVersion(
    id: scriptV3Id,
    presentationId: presentationId,
    version: 3,
    text: scriptV2.text.replaceFirst(rewrite1Original, rewrite1Replacement),
    parentVersionId: scriptV2Id,
    createdBy: ScriptVersionOrigin.rewrite,
    createdAt: DateTime(2026, 9, 6, 10, 25),
  );

  /// 원고 v1 분석 결과 (12번 화면). 리라이트 2번은 v2로 반영된 상태.
  static final ScriptAnalysis analysisV1 = ScriptAnalysis(
    id: 'demo-analysis-v1',
    scriptVersionId: scriptV1Id,
    summary: '방법 섹션이 청중 대비 과도하게 상세하고, 기여가 결과보다 먼저 나오지 않아 핵심이 늦게 드러납니다.',
    topActions: [
      TopAction(
        text: '방법 섹션의 알고리즘 세부 설명 3문장을 한 문장으로 요약',
        checkedAt: DateTime(2026, 9, 6, 10, 30),
      ),
      const TopAction(text: "'정렬(alignment)' 용어를 첫 등장에서 한 줄로 정의"),
      const TopAction(text: '기여 섹션의 첫 문장을 발표 도입부로 이동'),
    ],
    dimensions: const [
      DimensionFeedback(
        key: DimensionKey.logic,
        score: 3,
        evidenceQuote:
            '"우리는 원고를 섹션 단위로 구조화한 뒤 … 설계했습니다." 다음에 결과가 아니라 배경이 다시 나옵니다.',
        evidenceLocation: '## 방법 → ## 결과 전환부',
        problem: '기여가 결과 뒤에만 등장해 청중이 핵심을 발표 12분 이후에 듣게 됩니다.',
        suggestion: '기여 첫 문장을 배경 직후에 미리 언급하고, 결과 뒤에 다시 강조하세요.',
      ),
      DimensionFeedback(
        key: DimensionKey.clarity,
        score: 4,
        evidenceQuote: '"전사문과 문장 단위로 정렬하고" — \'정렬\'이 정의 없이 등장합니다.',
        evidenceLocation: '## 방법 · 1번째 문단',
        problem: "'정렬'이 무엇을 맞춰 보는지 청중이 알 수 없습니다.",
        suggestion: '첫 등장에서 "전사문을 원고 문장과 하나씩 맞춰 보는 것"이라고 풀어 주세요.',
      ),
      DimensionFeedback(
        key: DimensionKey.audience,
        score: 2,
        evidenceQuote:
            '"파이프라인의 각 단계에서 토큰 단위 정렬 비용을 …" 인접 분야 청중에게 필요 이상으로 상세합니다.',
        evidenceLocation: '## 방법 · 3번째 문단',
        problem: '복잡도 표기(O(n·m) → O(n log m))는 인접 분야 청중의 이해를 막고 30초를 씁니다.',
        suggestion: '복잡도 표기를 빼고 "실시간 처리가 가능해졌다"는 효과만 말하세요.',
      ),
    ],
    rewrites: const [
      Rewrite(
        id: 'rw-1',
        original: rewrite1Original,
        replacement: rewrite1Replacement,
        reason: '인접 분야 청중에게 복잡도 표기는 불필요. 30초 절감.',
      ),
      Rewrite(
        id: 'rw-2',
        original: rewrite2Original,
        replacement: rewrite2Replacement,
        reason: "'정렬' 용어를 첫 등장에서 정의.",
        appliedVersionId: scriptV2Id,
      ),
      Rewrite(
        id: 'rw-3',
        original: '각 단계는 독립적으로 실패할 수 있으며, 부분 결과를 반환합니다.',
        replacement: '한 단계가 실패해도 나머지 결과는 그대로 보여 드립니다.',
        reason: '구현 세부보다 청중이 얻는 효과로 표현.',
      ),
      Rewrite(
        id: 'rw-4',
        original: '측정과 해석을 분리한 파이프라인, 그리고 원고·전달 문제를 구분해 되돌려 주는 피드백 루프를 제안합니다.',
        replacement:
            '이 발표의 기여는 두 가지입니다. 측정과 해석을 분리한 파이프라인, 그리고 원고 문제와 전달 문제를 구분해 돌려주는 피드백 루프입니다.',
        reason: '기여를 명시적으로 세어 주면 청중이 기억합니다.',
      ),
    ],
    sectionEstimates: const [
      SectionEstimate(name: '배경', seconds: 130),
      SectionEstimate(name: '문제', seconds: 100),
      SectionEstimate(name: '방법', seconds: 380),
      SectionEstimate(name: '결과', seconds: 210),
      SectionEstimate(name: '기여', seconds: 60),
    ],
    status: StageState.succeeded,
    createdAt: DateTime(2026, 9, 6, 10, 15),
  );

  /// 리허설 #3 (원고 v3) 12:40, 전부 성공
  static final Rehearsal rehearsal3 = Rehearsal(
    id: 'demo-rehearsal-3',
    presentationId: presentationId,
    scriptVersionId: scriptV3Id,
    round: 3,
    recordedAt: DateTime(2026, 9, 9, 21, 14),
    durationSec: 760,
    teleprompterOn: true,
    audio: AudioInfo(
      state: AudioState.stored,
      expiresAt: DateTime(2026, 9, 16, 21, 14),
    ),
    transcript: TranscriptInfo(
      state: TranscriptState.stored,
      expiresAt: DateTime(2026, 9, 16, 21, 14),
    ),
    stages: {for (final s in ProcessingStage.values) s: StageState.succeeded},
    consentVersion: consentVersion,
    reportId: 'demo-report-3',
  );

  static final Rehearsal rehearsal2 = rehearsal3.copyWith(
    id: 'demo-rehearsal-2',
    round: 2,
    recordedAt: DateTime(2026, 9, 8, 22, 40),
    durationSec: 835,
    reportId: 'demo-report-2',
  );

  static final Rehearsal rehearsal1 = rehearsal3.copyWith(
    id: 'demo-rehearsal-1',
    scriptVersionId: scriptV2Id,
    round: 1,
    recordedAt: DateTime(2026, 9, 7, 20, 5),
    durationSec: 970,
    reportId: 'demo-report-1',
  );

  static List<Rehearsal> get rehearsals => [rehearsal3, rehearsal2, rehearsal1];

  /// 타임라인 32구간 WPM (결과 섹션 09:00 부근 181 급상승)
  /// 타임라인 32구간 WPM(어절/분) **측정값**. 평균 142, 결과 섹션(08:40–11:30) 안 09:06 지점(index 23)에 181.
  /// 그래프 높이는 이 값에서 파생한다. 시각용 높이에서 측정값을 역산하지 않는다.
  static const List<int> wpmSeriesValues = [
    118,
    124,
    128,
    122,
    131,
    134,
    137,
    131,
    128,
    133,
    139,
    136,
    142,
    139,
    138,
    142, //
    136,
    138,
    144,
    146,
    148,
    145,
    160,
    181,
    176,
    172,
    168,
    158,
    150,
    140,
    132,
    128,
  ];

  /// 타임라인 선택 지점(181 WPM) 인덱스 · 시각
  static const int selectedWpmIndex = 23;
  static const int selectedWpmTimeSec = 546;

  /// (구) Pen 막대 높이. 그래프 모양 참고용으로만 남긴다.
  static const List<int> wpmHeights = [
    30, 34, 36, 32, 38, 40, 42, 38, 36, 40, 44, 42, 46, 44, 40, 42, //
    38, 40, 44, 46, 48, 50, 56, 62, 60, 58, 54, 48, 44, 40, 36, 34,
  ];

  static final ReportMetrics metrics3 = ReportMetrics(
    wpmSeries: [
      for (var i = 0; i < wpmSeriesValues.length; i++)
        WpmPoint(timeSec: (760 * i / 32).round(), wpm: wpmSeriesValues[i]),
    ],
    fillers: const [
      FillerEvent(timeSec: 71, text: '어'),
      FillerEvent(timeSec: 261, text: '그니까'),
      FillerEvent(timeSec: 522, text: '그니까'),
      FillerEvent(timeSec: 546, text: '어'),
      FillerEvent(timeSec: 594, text: '음'),
      FillerEvent(timeSec: 641, text: '그니까'),
      FillerEvent(timeSec: 665, text: '어'),
    ],
    silences: const [
      SilenceSpan(startSec: 190, endSec: 194),
      SilenceSpan(startSec: 404, endSec: 409),
    ],
    sectionTimes: const [
      SectionTime(name: '배경', actualSec: 120, recommendedSec: 135, startSec: 0),
      SectionTime(name: '문제', actualSec: 90, recommendedSec: 90, startSec: 120),
      SectionTime(
        name: '방법',
        actualSec: 310,
        recommendedSec: 270,
        startSec: 210,
      ),
      SectionTime(
        name: '결과',
        actualSec: 170,
        recommendedSec: 240,
        startSec: 520,
      ),
      SectionTime(
        name: '기여',
        actualSec: 70,
        recommendedSec: 165,
        startSec: 690,
      ),
    ],
  );

  /// 원고 대조 (빠뜨림 6 · 즉흥 추가 3 · 순서 변경 1). 원고 문장 인덱스는 scriptV3 기준 예시.
  static const List<AlignedSentence> alignment3 = [
    AlignedSentence(
      scriptSentenceRef: 0,
      state: SentenceState.read,
      timeSec: 4,
    ),
    AlignedSentence(
      scriptSentenceRef: 1,
      state: SentenceState.read,
      timeSec: 41,
    ),
    AlignedSentence(
      scriptSentenceRef: 2,
      state: SentenceState.read,
      timeSec: 122,
    ),
    AlignedSentence(
      scriptSentenceRef: 3,
      state: SentenceState.read,
      timeSec: 166,
    ),
    AlignedSentence(
      scriptSentenceRef: 4,
      state: SentenceState.read,
      timeSec: 242,
    ),
    AlignedSentence(
      scriptSentenceRef: 4,
      state: SentenceState.added,
      timeSec: 252,
      spokenText: '그니까 어… 여기서 정렬이라는 게 중요한데요',
    ),
    AlignedSentence(scriptSentenceRef: 5, state: SentenceState.missed),
    AlignedSentence(
      scriptSentenceRef: 6,
      state: SentenceState.reordered,
      timeSec: 271,
    ),
    AlignedSentence(scriptSentenceRef: 7, state: SentenceState.missed),
    AlignedSentence(scriptSentenceRef: 8, state: SentenceState.missed),
    AlignedSentence(scriptSentenceRef: 9, state: SentenceState.missed),
    AlignedSentence(scriptSentenceRef: 10, state: SentenceState.missed),
    AlignedSentence(scriptSentenceRef: 11, state: SentenceState.missed),
    AlignedSentence(
      scriptSentenceRef: 12,
      state: SentenceState.read,
      timeSec: 522,
    ),
    AlignedSentence(
      scriptSentenceRef: 12,
      state: SentenceState.added,
      timeSec: 540,
      spokenText: '그니까 어… 결과적으로 일치율이 9%p 올랐는데',
    ),
    AlignedSentence(
      scriptSentenceRef: 13,
      state: SentenceState.read,
      timeSec: 598,
    ),
    AlignedSentence(
      scriptSentenceRef: 13,
      state: SentenceState.added,
      timeSec: 640,
      spokenText: '음, 이건 나중에 다시 말씀드릴게요',
    ),
    AlignedSentence(
      scriptSentenceRef: 14,
      state: SentenceState.read,
      timeSec: 691,
    ),
  ];

  static final AiFeedback aiFeedback3 = AiFeedback(
    topActions: const [
      TopAction(text: '결과 섹션에서 속도를 낮추기 (WPM 181 → 150 목표)'),
      TopAction(text: '방법 섹션에서 빠뜨린 6문장 중 2문장 다시 읽기'),
      TopAction(text: "'그니까', '어' 같은 필러를 결과 섹션에서 줄이기"),
    ],
    dimensions: const [
      DimensionFeedback(
        key: DimensionKey.logic,
        score: 4,
        evidenceQuote: '방법→결과 전환에서 "그래서 결과적으로"를 넣어 흐름이 매끄러워졌습니다.',
        evidenceLocation: '4:58 구간',
        problem: '결과 뒤 기여로 넘어갈 때 연결어가 없습니다.',
        suggestion: '"이 결과가 말해 주는 기여는"으로 이어 주세요.',
      ),
      DimensionFeedback(
        key: DimensionKey.clarity,
        score: 4,
        evidenceQuote: "'정렬'을 정의한 문장을 그대로 읽어 용어 문제는 해소됐습니다.",
        evidenceLocation: '## 방법 · 1번째 문장',
        problem: '"파이프라인"은 여전히 정의 없이 쓰입니다.',
        suggestion: '"처리 순서"로 바꾸거나 첫 등장에서 한 줄로 설명하세요.',
      ),
      DimensionFeedback(
        key: DimensionKey.audience,
        score: 3,
        evidenceQuote: '빠뜨린 6문장이 모두 방법 세부라 결과적으로 청중에겐 오히려 적절했습니다.',
        evidenceLocation: '## 방법 · 빠뜨린 문장',
        problem: '빠뜨린 문장을 원고에서도 뺄지 결정하지 않으면 다음 리허설에서 다시 길어집니다.',
        suggestion: '6문장 중 4문장은 원고에서 삭제하고 2문장만 다시 읽으세요.',
      ),
      DimensionFeedback(
        key: DimensionKey.timing,
        score: 3,
        evidenceQuote: '방법 5:10(권장 4:30), 기여 1:10(권장 2:45) — 핵심 기여가 급하게 끝났습니다.',
        evidenceLocation: '섹션별 시간 배분',
        problem: '기여에 쓸 시간을 방법이 가져갔습니다.',
        suggestion: '방법을 40초 줄이고 기여 첫 문장을 천천히 두 번 말하세요.',
      ),
      DimensionFeedback(
        key: DimensionKey.delivery,
        score: 2,
        evidenceQuote: '결과 섹션 WPM 181, 필러 7회 중 5회가 여기 집중 — 긴장 구간입니다.',
        evidenceLocation: '8:40–11:30 구간 (결과)',
        problem: '숫자를 말할 때 속도가 오르고 필러가 늘어납니다.',
        suggestion: '"9%p 상승했습니다" 앞에서 한 박자 쉬고 숫자를 또박또박 읽으세요.',
      ),
      DimensionFeedback(
        key: DimensionKey.fidelity,
        score: 4,
        evidenceQuote: '일치율 87%, 전 회차 대비 +6%p. 빠뜨림은 방법 섹션에만 있습니다.',
        evidenceLocation: '원고 대조 뷰',
        problem: '즉흥 추가 3문장이 모두 필러로 시작합니다.',
        suggestion: '추가하고 싶은 말은 원고에 넣어 두세요.',
      ),
    ],
  );

  static final Report report3 = Report(
    id: 'demo-report-3',
    rehearsalId: 'demo-rehearsal-3',
    metrics: metrics3,
    alignment: alignment3,
    matchRate: 0.87,
    matchRateScope: MatchRateScope.full,
    prevMatchRate: 0.81,
    ai: aiFeedback3,
    createdAt: DateTime(2026, 9, 9, 21, 16),
  );

  /// AI 해석만 실패한 부분 리포트 (33번 화면)
  static final Report report3Partial = report3.copyWith(
    id: 'demo-report-3-partial',
    clearAi: true,
  );

  static final Report report2 = report3.copyWith(
    id: 'demo-report-2',
    rehearsalId: 'demo-rehearsal-2',
    matchRate: 0.81,
    prevMatchRate: 0.74,
    createdAt: DateTime(2026, 9, 8, 22, 42),
  );

  static final Report report1 = report3.copyWith(
    id: 'demo-report-1',
    rehearsalId: 'demo-rehearsal-1',
    matchRate: 0.74,
    clearPrevMatchRate: true,
    createdAt: DateTime(2026, 9, 7, 20, 7),
  );

  static List<Report> get reports => [report3, report2, report1];
}
