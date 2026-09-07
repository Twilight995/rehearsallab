import 'package:rehearsallab/core/enum/auth_error_code.dart';
import 'package:rehearsallab/services/presentation_form_service.dart';

/// 화면 문구 상수. Pen 디자인(rehearsallab.pen)의 텍스트와 글자 단위로 같아야 한다.
/// 이름 규칙: `<page><Meaning>` (계약서 3.1). 제공사명처럼 런타임 값이 들어가는 문구는 함수.
class AppStrings {
  AppStrings._();

  // ── 공통 ──
  static const appName = 'RehearsalLab';
  static const commonNext = '다음';
  static const commonSkip = '건너뛰기';
  static const commonCancel = '취소';
  static const commonEdit = '편집';
  static const commonSave = '저장';
  static const commonRetry = '재시도';
  static const commonBack = '돌아가기';
  static const commonMockBadge = '개발용 목업';
  static const commonProviderUnset = '개발용 목업 · 제공사 미지정';
  static const commonUndetermined = '미확정';
  static const commonDateTbd = '날짜 미정';
  static const commonPrepared = '2차 기능 · 준비 중';
  static const tabHome = '홈';
  static const tabPresentation = '발표';
  static const tabSettings = '설정';
  static const detailTitle = '발표 상세';
  static const detailTabScript = '원고';
  static const detailTabRehearsal = '리허설';
  static const detailTabQa = 'Q&A';
  static const detailTabHistory = '이력';

  // ── 00 스플래시 ──
  static const splashTagline = '발표 전날, 피드백 줄 사람이 없어도';

  // ── 01 · 02 온보딩 ──
  static const introLoopScript = '원고';
  static const introLoopAnalysis = '분석';
  static const introLoopRehearsal = '리허설';
  static const introLoopFeedback = '피드백';
  static const intro1Headline = '발표 전날,\n피드백 줄 사람이\n없어도';
  static const intro1Body =
      '원고를 넣고 소리 내 읽으면, 코드가 측정하고 AI가 해석해 다음 리허설에서 고칠 것을 알려드립니다.';
  static const intro2Headline = '코드가 측정하고\nAI가 해석합니다';
  static const intro2Body =
      '말하기 속도, 군말, 원고 일치율은 숫자로 정확히. 왜 그런지는 AI가 근거와 함께 설명합니다.';
  static const intro2MetricSpeed = '속도';
  static const intro2MetricSpeedUnit = 'WPM';
  static const intro2MetricFiller = '필러';
  static const intro2MetricFillerUnit = '회';
  static const intro2MetricMatch = '원고 일치';
  static const intro2MetricMatchUnit = '%';

  // ── 03 프라이버시 동의 ──
  static const privacyHeadline = '원고와 녹음은\n이렇게 다룹니다';
  static const privacyBody = '동의해야 계속할 수 있어요. 설정에서 언제든 보관 기간을 바꾸거나 삭제할 수 있습니다.';
  static const privacyTransferTitle = '외부 전송 대상';
  static String privacyTransferDesc(String stt, String llm) =>
      '녹음 → $stt. 원고 · 전사문 · 발표 유형 · 청중 · 측정 지표 → $llm. 제목 · 이메일은 보내지 않지만 원고와 말의 내용은 그대로 전송됩니다.';
  static const privacyRetentionTitle = '보관 기간';
  static const privacyRetentionDesc =
      '녹음 · 전사문 원본 7일 (30일 / 처리 후 즉시 삭제 선택). 원고 · 리포트는 직접 삭제 전까지. 리포트에 인용된 발화 문장은 남습니다.';
  static const privacyDeleteTitle = '언제든 삭제';
  static const privacyDeleteDesc =
      '발표 단위 또는 전체 삭제. 외부 제공사 삭제는 요청 중 / 완료 / 미지원으로 표시합니다.';
  static String privacyConsentText(String consentVersion) =>
      '이해했고 동의합니다 (필수) · 고지 버전 $consentVersion · 제공사 · 범위 · 보관 정책이 바뀌면 다시 동의를 받습니다';
  static const privacyAgreeButton = '동의하고 시작하기';

  // ── 04 로그인 · 05 가입 ──
  static const loginForgotNotice =
      '프로토타입은 기기 안에서만 계정을 관리해 비밀번호 재설정을 지원하지 않습니다. 새 이메일로 가입해 주세요.';
  static const authErrorUnknown = '잠시 후 다시 시도해 주세요.';
  static String authError(AuthErrorCode code) => switch (code) {
    AuthErrorCode.invalidEmail => '이메일 형식을 확인해 주세요.',
    AuthErrorCode.passwordTooShort => '비밀번호는 8자 이상이어야 합니다.',
    AuthErrorCode.passwordMismatch => '비밀번호가 서로 다릅니다.',
    AuthErrorCode.emailTaken => '이미 가입된 이메일입니다. 로그인해 주세요.',
    AuthErrorCode.invalidCredentials => '이메일 또는 비밀번호가 맞지 않습니다.',
    AuthErrorCode.storage =>
      '계정 정보를 읽거나 저장하지 못했습니다. 앱을 다시 실행해도 같으면 설정에서 데이터를 확인해 주세요.',
    AuthErrorCode.consentBind => '동의 기록을 저장하지 못해 로그인을 완료할 수 없습니다. 다시 시도해 주세요.',
    AuthErrorCode.consentCheck => '동의 상태를 확인하지 못해 로그인을 완료할 수 없습니다. 다시 시도해 주세요.',
  };
  static const splashLoadFailed = '설정을 불러오지 못했습니다.';
  static const privacyLoading = '고지 내용을 불러오는 중입니다';
  static const privacyLoadFailed = '고지 내용을 불러오지 못했습니다. 다시 시도해 주세요.';
  static const privacyVersionPending = '불러오는 중';
  static const loginTitle = '다시 오셨네요';
  static const loginSubtitle = '이메일과 비밀번호로 로그인하세요.';
  static const authEmailLabel = '이메일';
  static const authEmailHint = '이메일 주소';
  static const authPasswordLabel = '비밀번호';
  static const authPasswordHint = '8자 이상';
  static const authPasswordConfirmLabel = '비밀번호 확인';
  static const authPasswordConfirmHint = '한 번 더 입력';
  static const loginButton = '로그인';
  static const loginToSignup = '계정이 없나요? 가입하기';
  static const loginForgot = '비밀번호를 잊으셨나요?';
  static const signupTitle = '계정 만들기';
  static const signupSubtitle = '이메일 하나면 충분합니다. 원고와 녹음은 이 계정에만 묶입니다.';
  static const signupButton = '가입하기';
  static const signupToLogin = '이미 계정이 있나요? 로그인';

  // ── 06 · 07 홈 ──
  static String homeGreeting(String name) => '안녕하세요, $name님';
  static const homeEmptyBig = '첫 발표를\n만들어 보세요';
  static const homeEmptySub = '원고를 붙여넣으면 5분 안에 첫 리포트를 봅니다';
  static const homeSectionTitle = '내 발표';
  static String homeSectionCount(int n) => '$n개';
  static const homeSectionSort = 'D-day 순';
  static const homeEmptyTitle = '아직 발표가 없어요';
  static const homeEmptyDesc = '발표를 만들고 원고를 붙여넣으면\n분석 → 리허설 → 피드백 루프가 시작됩니다.';
  static const homeCreateFirst = '첫 발표 만들기';
  static const homeSample = '샘플 발표로 리포트 둘러보기';
  static const homeNextLabel = '다음 발표까지';
  static String homeDday(int days) => days == 0 ? 'D-day' : 'D-$days';
  static String homeRehearsalCount(int n) => '리허설 $n회';

  /// 07 헤더 보조 문구: '○○학회 구두발표 · 9월 12일 (금) · 리허설 2회' (날짜 없으면 '날짜 미정')
  static String homeNextSummary(
    String title,
    String dateLabel,
    int rehearsals,
  ) => [title, dateLabel, homeRehearsalCount(rehearsals)].join(' · ');
  static const homeLoadFailed = '발표 목록을 불러오지 못했습니다.';

  // ── 08 발표 생성 ──
  static const formTitle = '새 발표';
  static const formTitleLabel = '제목';
  static const formTypeLabel = '발표 유형';
  static const formTimeSpecLabel = '시간 규격';
  static const formTalkLabel = '발표';
  static const formQaLabel = 'Q&A';
  static const formMinuteUnit = '분';
  static const formTimeHint =
      'Q&A 0분은 질의응답 없음으로 저장됩니다. 발표 시간은 1~60분까지 입력할 수 있고, 20분을 넘는 발표는 프로토타입에서 20분까지만 녹음해 부분 리허설로 분석합니다.';
  static String formPartialNotice(int talkMinutes) =>
      '발표 규격은 $talkMinutes분이며, 이번 녹음은 최대 20분의 부분 리허설입니다';
  static const formAudienceLabel = '청중';
  static const formDateLabel = '발표 날짜 (선택)';
  static const formDateHint =
      "날짜를 비워 두면 홈에서 '날짜 미정'으로 표시되고 날짜가 있는 발표 뒤에 정렬됩니다.";
  static const formSubmit = '발표 만들기';
  static const formTitleRequired = '제목을 입력하세요.';
  static const formTalkRange = '발표 시간은 1~60분의 정수여야 합니다.';
  static const formQaRange = 'Q&A 시간은 0 이상의 정수여야 합니다.';
  static const formTitleHint = '○○학회 구두발표';
  static const formEditTitle = '발표 편집';
  static const formDatePlaceholder = '날짜 선택';
  static const formDateClear = '날짜 지우기';
  static const formSaveFailed = '발표를 저장하지 못했습니다. 다시 시도해 주세요.';
  static String formError(PresentationFormError code) => switch (code) {
    PresentationFormError.titleRequired => formTitleRequired,
    PresentationFormError.talkRange => formTalkRange,
    PresentationFormError.qaRange => formQaRange,
  };

  // ── 09 설정 ──
  static const settingsTitle = '설정';
  static const settingsGroupAccount = '계정';
  static const settingsEmail = '이메일';
  static const settingsLogout = '로그아웃';
  static const settingsGroupData = '데이터';
  static const settingsRetention = '녹음 · 전사문 보관 기간';
  static String settingsRetentionValue(String option) => '녹음 · 전사문 $option';
  static const settingsDeleteAll = '모든 데이터 삭제';
  static const settingsRetentionNote =
      "녹음 · 전사문 원본: 선택한 기간 (녹음 시각 기준, 재분석해도 연장되지 않음) / 원고 · 분석 · 리포트: 직접 삭제 전까지. 리포트의 발화 인용은 원본 삭제 후에도 남습니다. '처리 후 즉시 삭제'를 고르면 구간 재생을 쓸 수 없고 삭제된 녹음은 복원되지 않으며, 이 옵션에서만 AI 분석 실패 시 전사문을 재시도용으로 최대 24시간 임시 보관합니다.";
  static const settingsGroupInfo = '정보';
  static const settingsPrivacyAgain = '프라이버시 고지 다시 보기';
  static const settingsProviders = 'AI · 음성인식 제공사';
  static String settingsProvidersValue(String llm, String stt) => '$llm / $stt';
  static const settingsExternal = '외부 보관 · 삭제 상태';
  static String settingsExternalValue(String stt, String llm, String status) =>
      '$stt / $llm · $status';
  static const settingsVersion = '버전';
  static const settingsVersionValue = '1.0.0 (proto)';

  // ── 31 · 32 모든 데이터 삭제 ──
  static const deleteTitle = '모든 데이터 삭제';
  static String deleteStep(int step) => '확인 $step / 2';
  static const delete1Headline = '모든 발표 데이터를\n삭제할까요?';
  static const delete1Desc = '설정한 외부 제공사 데이터도 삭제를 요청합니다. 완료 여부는 설정 화면에 표시돼요.';
  static const deleteWarning = '삭제한 데이터는 복구할 수 없습니다. 외부 처리 제공사에도 삭제를 요청합니다.';
  static const deleteScopeHeading = '삭제되는 데이터';
  static String deleteScopePresentations(int p, int v) =>
      '• 발표 $p개 · 원고 $v개 버전';
  static String deleteScopeRehearsals(int r, int rep) =>
      '• 리허설 녹음 $r개 · 리포트 $rep개';
  static const deleteScopeAnalyses = '• 분석 결과 · 체크한 액션 이력';
  static const deleteCancel = '취소하고 돌아가기';
  static const delete1Next = '다음 확인';
  static const delete2Headline = '한 번 더\n확인해 주세요';
  static const delete2Desc = '되돌릴 수 없는 작업입니다. 아래에 "삭제"를 입력하면 버튼이 활성화됩니다.';
  static const delete2InputLabel = '확인을 위해 "삭제"를 입력하세요';
  static const delete2Keyword = '삭제';
  static const delete2Note = '계정은 유지됩니다. 데이터만 삭제돼요.';
  static const delete2Confirm = '영구 삭제';

  // ── 10 · 11 · 11b · 12 · 13 · 37 · 38 원고 탭 ──
  static const scriptPlaceholder = '발표 원고를 여기에 붙여넣으세요.';
  static const scriptSectionHint =
      '섹션을 나누려면 줄 맨 앞에 ## 섹션 이름을 쓰세요 (예: ## 배경, ## 방법). 안 나눠도 됩니다.';
  static const scriptPaste = '붙여넣기';
  static const scriptOpenFile = '파일 열기 (.txt)';
  static String scriptWords(String words) => '$words어절 · 평균 속도로 읽으면';
  static String scriptOver(String delta) => '$delta 초과';
  static String scriptUnder(String delta) => '$delta 여유';
  static const scriptAnalyze = '원고 분석';
  static const scriptReanalyze = '다시 분석';
  static const scriptAnalyzingTitle = '논리 구조를 읽고 있어요…';
  static String scriptAnalyzingSub(String words, int sections) =>
      '보통 5~20초 걸립니다. 원고 $words어절 · $sections개 섹션';
  static const scriptAnalyzingStep1 = '논리 구조 파악';
  static const scriptAnalyzingStep2 = '명료성 · 용어 점검';
  static const scriptAnalyzingStep3 = '청중 적합성 판단';
  static const scriptAnalyzingStep4 = '리라이트 제안 생성';
  static const scriptAnalyzingPrivacy =
      '원고 텍스트가 AI 제공사로 전송되어 분석됩니다. 결과는 이 발표에만 저장돼요.';
  static const scriptAnalyzingCancel = '분석 취소';
  static const scriptSummaryLabel = 'AI 한 줄 총평';
  static const scriptTopActionsTitle = 'Top 3 개선 액션';
  static const scriptTopActionsSub = '체크하면 이력에 기록';
  static const scriptDimensionsTitle = '차원별 피드백';
  static const scriptDimensionsSub = '근거 먼저, 점수는 참고';
  static const dimensionExpand = '문제점 · 제안 보기';
  static const dimensionCollapse = '문제점 · 제안 접기';
  static const dimensionCollapseShort = '접기';
  static const dimensionProblem = '문제점';
  static const dimensionSuggestion = '제안';
  static const dimensionScoreMax = '/5';
  static const scriptRewritesTitle = '리라이트 제안';
  static String scriptRewritesSub(int applied, int total) =>
      '확정마다 새 버전 · $applied/$total 반영됨';
  static const rewriteOriginal = '원문';
  static const rewriteReplacement = '수정문';
  static const rewriteApply = '원고에 반영';
  static String rewriteApplied(int version) => '반영됨 → v$version';
  static const scriptEstimateTitle = '예상 소요 시간 vs 규격';
  static String scriptEstimateSub(String est, String spec) => '$est / $spec';
  static String scriptEstimateLegend(int recommended, int over) =>
      '권장 배분($recommended%)보다 $over%p 초과';
  static const scriptEditButton = '원고 편집';
  static const scriptStartRehearsal = '리허설 시작';
  static String scriptVersionAnalyzed(int analyzed, int current) =>
      'v$analyzed 분석 · 현재 v$current';
  static String scriptDirtyNotice(int from, int to) =>
      '원고가 v$from에서 v$to로 바뀌었어요. 이전 분석 리포트는 이력에 보존됩니다. 다시 분석하면 최신 원고 기준으로 피드백을 받습니다.';
  static String scriptVersionChangeTitle(int from, int to) =>
      'v$from → v$to 변경 내역';
  static String scriptVersionChangeMeta(int count) => '$count문장 치환 · 방금';
  static String scriptRevert(int target, int next) =>
      'v$target 텍스트로 되돌리기 (v$next로 저장)';
  static String rewriteSheetContext(
    int index,
    int total,
    String section,
    int from,
    int to,
  ) => '리라이트 $index/$total · ## $section · 원고 v$from → v$to';
  static const rewriteSheetProblem = '문제점';
  static String rewriteSheetNote(int to, int from) =>
      '이 문장만 치환하고 새 원고 v$to로 저장합니다. 원고 v$from와 이전 분석 결과는 이력에 그대로 보존되고, v$to는 재분석 필요 상태가 됩니다. 원문이 현재 원고와 다르면 치환하지 않고 재분석을 안내합니다.';
  static String rewriteSheetApply(int to) => '이 문장 치환하고 v$to 저장';
  static const rewriteNotFound = '원문을 찾을 수 없어요. 원고를 다시 분석하세요.';
  static const scriptFailedTitle = '원고는 저장됐어요.\n분석만 다시 시도해요';
  static String scriptFailedDesc(int version) =>
      'AI 서비스 응답이 지연되어 분석을 완료하지 못했습니다. 원고 v$version은 그대로 있고, 다시 시도하면 처음부터 분석합니다.';
  static String scriptFailedError(String error) => '오류: $error';
  static const scriptKeptHeading = '유지된 원고';
  static String scriptKeptLine1(int version, String words, int sections) =>
      '원고 v$version · $words어절 · $sections개 섹션';
  static String scriptKeptLine2(String est, String delta) =>
      '평균 속도 예상 $est · 규격보다 $delta';
  static const scriptFailedRetry = '원고 분석 다시 시도';
  static const scriptBackToScript = '원고로 돌아가기';

  // ── 20 리허설 탭 (첫 녹음 준비) ──
  static const rehearsalEmptyTitle = '원고를 실제로\n소리 내 읽어 보세요';
  static const rehearsalEmptyDesc =
      '속도 · 군말 · 빠뜨린 문장 · 시간 배분을 측정합니다. 끝나면 1~2분 뒤 리포트가 나와요.';
  static const rehearsalTagSpeed = '속도 WPM';
  static const rehearsalTagFiller = '필러';
  static const rehearsalTagMatch = '원고 일치';
  static const rehearsalTagTiming = '시간 배분';
  static const checkQuiet = '조용한 곳인가요?';
  static const checkEarphone = '이어폰 마이크를 권장합니다';
  static const checkManualScroll = '텔레프롬프터는 수동 스크롤이에요';
  static const checkAutoPause = '전화·알림이 오면 자동으로 일시정지돼요';
  static const rehearsalPermissionNote = '마이크 권한은 녹음 시작 직전에 한 번만 요청합니다.';
  static const rehearsalStart = '녹음 시작';
  static const rehearsalAgain = '다시 리허설';

  // ── 21 회차 목록 ──
  static const listTrendMatch = '일치율';
  static const listTrendWpm = 'WPM';
  static const listTrendFiller = '필러';
  static String listTrendDelta(String delta, int round) => '$delta vs #$round';
  static const listSectionTitle = '회차별 리포트';
  static const listSectionSub = '최신순';
  static const listFirstRound = '첫 회차';
  static const listVsPrev = '전 회차 대비';
  static String listMeta(String time, String spec, int match, int fillers) =>
      '$time / $spec · 일치 $match% · 필러 $fillers회';

  // ── 25 · 26 마이크 권한 ──
  static const micTitle = '마이크 권한';
  static const micRationaleHeadline = '목소리를 녹음하려면\n마이크가 필요해요';
  static const micRationaleDesc =
      '녹음 버튼을 누른 동안만 목소리를 담습니다. 다음 단계에서 기기의 권한 창이 열려요.';
  static const micDataHeading = '녹음 데이터 안내';
  static const micData1 = '녹음은 음성인식 제공사로 전송되어 받아쓰기됩니다';
  static const micData2 = '보관 기간 기본 7일 · 설정에서 변경';
  static const micData3 = '리허설 단위로 언제든 삭제 가능';
  static const micRationaleHint = '온보딩에서는 권한을 요청하지 않았어요. 지금 한 번만 요청합니다.';
  static const micRationaleContinue = '계속 · 마이크 권한 요청';
  static const micRationaleBack = '지금은 돌아가기';
  static const micDeniedHeadline = '마이크를 사용할 수\n없어요';
  static const micDeniedDesc = '기기 설정에서 마이크 접근을 허용하면 리허설을 시작할 수 있습니다.';
  static const micDeniedHint = '권한을 바꾸지 않아도 원고 분석은 계속 사용할 수 있어요.';
  static const micOpenSettings = '기기 설정 열기';

  // ── 14 · 15 · 16 · 30 녹음 ──
  static const recWaiting = '대기';
  static const recRecording = '녹음 중';
  static const recPaused = '일시정지됨';
  static String recHintWaiting(String spec) => '규격 $spec · 20분 도달 시 자동 종료';
  static String recHintSection(String section, int index, int total) =>
      '현재 섹션: ## $section · $index/$total';
  static String recHintTeleprompterOff(String section, int index, int total) =>
      '텔레프롬프터 OFF · 현재 섹션: ## $section · $index/$total';
  static const recCountdownLabel = '곧 녹음이 시작됩니다';
  static const recStartNow = '바로 시작';
  static const recTeleprompterOn = '텔레프롬프터 ON';
  static const recTeleprompter = '텔레프롬프터';
  static const recPause = '일시정지';
  static const recResume = '재개';
  static const recStop = '종료';
  static const recStatePausedTitle = '녹음 일시정지';
  static const recStateAutoStopped = '자동 종료 · 기기에 저장됨';
  static String recSheetMeta(String spec, int version) =>
      '/ $spec · 원고 v$version';

  // ── 27 · 28 · 29 녹음 바텀시트 ──
  static const endConfirmTitle = '리허설을 끝낼까요?';
  static String endConfirmDesc(String elapsed) =>
      '$elapsed 녹음했어요. 종료하면 이 녹음으로 리포트를 만듭니다.';
  static const endConfirmPrimary = '종료하고 분석';
  static const endConfirmSecondary = '계속 녹음';
  static const discardTitle = '이 녹음을 버릴까요?';
  static String discardDesc(String elapsed) =>
      '지금까지 녹음한 $elapsed는 저장되지 않습니다. 원고는 유지돼요.';
  static const discardPrimary = '녹음 버리기';
  static const discardSecondary = '녹음으로 돌아가기';
  static const autoStopTitle = '20분에 도달했어요';
  static String autoStopDesc(String spec, String over) =>
      '녹음을 자동으로 종료하고 저장했습니다. 규격 $spec보다 $over 초과했어요. 저장한 녹음으로 분석을 시작할 수 있습니다.';
  static const autoStopPrimary = '저장한 녹음 분석';
  static const autoStopSecondary = '리허설 목록으로';

  // ── 17 · 18 · 19 처리 중 ──
  static const processingTitle = '리허설 처리 중';
  static const processingHeadline = '리허설을 분석하고 있어요';
  static const processingSub =
      '보통 1~2분 걸립니다. 이 화면을 유지해 주세요. 완료되면 자동으로 리포트로 이동합니다.';
  static const processingPartialHeadline = '일부만 완료됐어요';
  static const processingPartialSub =
      'AI 해석만 실패했습니다. 속도·필러·원고 대조 결과는 바로 볼 수 있어요.';
  static const processingFailedHeadline = '처리에 실패했어요';
  static const processingFailedSub = '받아쓰기 단계에서 오류가 났습니다. 녹음은 안전하게 보관되어 있어요.';
  static String processingStageDesc(
    String location,
    String status,
    String detail,
  ) => detail.isEmpty ? '$location · $status' : '$location · $status · $detail';
  static String processingPrivacy(
    String stt,
    String llm,
    String consentVersion,
  ) =>
      '녹음 → $stt · 원고 · 전사문 · 지표 → $llm. 녹음 · 전사문 원본은 선택한 보관 기간(7일) 후 삭제. 고지 버전 $consentVersion';
  static const processingRefresh = '처리 상태 새로고침';
  static const processingPartialResult = '부분 결과 보기';
  static const processingRetryAi = 'AI 해석 재시도';
  static const processingRerecord = '녹음 다시 하기';
  static const processingLocalNote =
      '녹음은 기기에 보관되어 있어 같은 녹음으로 재시도할 수 있습니다. 실패 시각부터 7일 안에 재시도하지 않으면 기기 녹음도 삭제됩니다.';
  static String stateAudioStored(String deleteAt) =>
      '녹음: 보관 중 · $deleteAt 삭제 예정 · 재생 가능';
  static String stateAudioLocal(String until) =>
      '녹음: 기기에만 저장됨 · $until까지 재시도 가능 · 외부 전송 전';
  static const stateAudioDeleted = '녹음 삭제됨 · 재생 불가';

  /// 7일 · 30일 옵션: 전사문은 녹음과 같은 보관 기간 (재시도 기한 = 원본 만료)
  static String stateAiFailedRetained(String deadline) =>
      'AI 해석: 실패 · $deadline까지 재시도 가능 (전사문은 녹음과 함께 보관)';
  static const stateAiFailedDeleted = 'AI 해석: 실패 · 전사문이 삭제되어 재시도 불가 · 새 리허설 필요';

  /// 즉시 삭제 옵션: 전사문 24시간 임시 보관 예외
  static String stateAiFailedTempRetained(String deadline) =>
      'AI 해석: 실패 · $deadline까지 재시도 가능 (전사문 임시 보관 24시간)';
  static const stateAiOk = 'AI 해석: 완료';

  // ── 22 · 33 · 34 리포트 ──
  static String reportRound(int round) => '리허설 #$round';
  static const reportTotalTime = '총 시간';
  static String reportTimeLeft(String delta) => '$delta 남음';
  static String reportTimeOver(String delta) => '$delta 초과';
  static const reportMatch = '원고 일치';
  static String reportMatchDelta(String delta) => '전 회차 대비 $delta';
  static const reportScopeDiffers = '평가 범위 다름';
  static const reportTopTitle = '다음 리허설 Top 3';
  static const reportTopSub = '체크하면 이력에 기록';
  static const reportTimelineTitle = '타임라인';
  static const reportTimelineSub = '탭하면 그 지점부터 재생';
  static const reportTimelineUnavailable = '녹음이 삭제되어 재생할 수 없어요';
  static const legendWpm = '속도(WPM)';
  static const legendFiller = '필러';
  static const legendSilence = '침묵';
  static String reportWpm(int wpm) => '$wpm WPM';
  static const reportAllocationTitle = '섹션별 시간 배분';
  static const reportAllocationSub = '실제 vs 권장';
  static const reportCompareTitle = '원고 대조';
  static const reportCompareExpanded = '펼쳐짐';
  static const reportFilterAll = '전체';
  static String reportFilterMissed(int n) => '빠뜨린 것만 $n';
  static String reportFilterAdded(int n) => '추가한 것만 $n';
  static const reportDimensionsTitle = '차원별 피드백';
  static const reportDimensionsSub = '6개 · 근거 먼저';
  static const reportEditScript = '원고 수정하러 가기';
  static const reportPartialBadge = '부분 결과';
  static const reportExpiredBadge = '녹음 보관 만료';
  static const reportPartialRehearsalBadge = '부분 리허설';
  static const reportAiUnavailableTitle = 'AI 해석을 받지 못했어요';
  static String reportAiUnavailableDesc(String llm, String deadline) =>
      '$llm 응답 시간 초과로 6개 차원 피드백만 비어 있습니다. 속도 · 필러 · 시간 배분 · 원고 대조는 코드가 계산한 결과라 그대로 신뢰해도 됩니다. 재시도는 $deadline까지 가능하고, 그 뒤에는 전사문이 삭제되어 새 리허설이 필요합니다.';
  static const reportPlaybackExpired =
      '보관 기간(7일)이 지나 녹음과 전사문 원본은 삭제됐습니다. 지표 · 원고 대조 · 저장된 AI 피드백과 인용 문장은 그대로 볼 수 있지만, 전체 전사문이 필요한 새 AI 재분석은 할 수 없어요.';

  // ── 23 · 24 준비 중 ──
  static const qaTitle = '발표 다음의 대화도\n준비할 수 있도록';
  static const qaDesc = '예상 질문 5~10개를 만들고, 답변을 1~2분 녹음해 직접성·근거·길이를 평가합니다.';
  static const plannedHeading = '준비하고 있는 기능';
  static const qaPlanned1 = '예상 질문 생성 (왜 나올 질문인지 + 힌트)';
  static const qaPlanned2 = '답변 녹음 1~2분';
  static const qaPlanned3 = '답변 평가: 직접성 · 근거 · 길이';
  static const qaBack = '리허설 탭으로 돌아가기';
  static const historyTitle = '작은 변화가 쌓이는\n과정을 보여드릴게요';
  static const historyDesc =
      '회차별 점수와 지표 추이, Top 3 액션 반영 여부, 원고 버전 타임라인이 여기에 모입니다.';
  static const historyPlanned1 = '회차별 종합 점수 · WPM · 필러 · 일치율';
  static const historyPlanned2 = 'Top 3 액션 반영 / 부분 / 미반영';
  static const historyPlanned3 = '원고 버전 타임라인 v1 → v2 → v3';
  static const historyBack = '리허설 목록 보기';

  // ── Phase 0 임시 ──
  static String placeholderBody(String task) => '구현 예정 · $task';
}
