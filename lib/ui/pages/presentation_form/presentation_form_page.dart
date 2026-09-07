import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rehearsallab/app/app_config.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/core/enum/audience.dart';
import 'package:rehearsallab/core/enum/presentation_type.dart';
import 'package:rehearsallab/core/extension/date_time_extension.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/presentation/presentation_provider.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/services/presentation_form_service.dart';
import 'package:rehearsallab/ui/common/app_chip.dart';
import 'package:rehearsallab/ui/common/app_top_bar.dart';
import 'package:rehearsallab/ui/common/label_text_field.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';
import 'package:rehearsallab/ui/common/stepper_field.dart';

/// 08 발표 생성 (`xfwQs`) · 편집(presentationId). 제목 · 유형 칩 · 시간 규격 스테퍼 · 청중 칩 · 날짜(선택).
/// 저장 성공 → 발표 상세(원고 탭, 10 원고 입력). 검증 실패는 폼 아래 문구 (통합 문서 4장 "제목·발표 시간 필수 검증 후 10").
class PresentationFormPage extends ConsumerStatefulWidget {
  final String? presentationId;

  const PresentationFormPage({super.key, this.presentationId});

  @override
  ConsumerState<PresentationFormPage> createState() =>
      _PresentationFormPageState();
}

class _PresentationFormPageState extends ConsumerState<PresentationFormPage> {
  final _title = TextEditingController();
  PresentationDraft _draft = PresentationDraft.initial();
  Presentation? _existing;
  List<PresentationFormError> _errors = const [];
  String? _saveError;
  bool _saving = false;
  bool _loadedExisting = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _loadExisting(Presentation? p) {
    if (_loadedExisting || p == null) return;
    _loadedExisting = true;
    _existing = p;
    _draft = PresentationDraft.fromPresentation(p);
    _title.text = p.title;
  }

  void _update(PresentationDraft next) {
    setState(() {
      _draft = next;
      if (_errors.isNotEmpty) {
        _errors = ref.read(presentationFormServiceProvider).validate(next);
      }
    });
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.date ?? today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 3),
    );
    if (picked != null) _update(_draft.copyWith(date: picked));
  }

  Future<void> _submit() async {
    final draft = _draft.copyWith(title: _title.text);
    final errors = ref.read(presentationFormServiceProvider).validate(draft);
    if (errors.isNotEmpty) {
      setState(() {
        _draft = draft;
        _errors = errors;
      });
      return;
    }
    setState(() {
      _draft = draft;
      _errors = const [];
      _saveError = null;
      _saving = true;
    });
    Result<Presentation> result;
    try {
      result = await ref
          .read(presentationsProvider.notifier)
          .save(draft, existing: _existing);
    } on Object catch (e) {
      result = Failure(e is Exception ? e : Exception(e.toString()));
    }
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        context.go(
          AppPage.presentationDetail.location({
            RouteParam.presentationId: value.id,
            RouteParam.tab: 'script',
          }),
        );
      case Failure():
        setState(() {
          _saving = false;
          _saveError = AppStrings.formSaveFailed;
        });
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppPage.home.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.presentationId;
    if (id != null) {
      _loadExisting(ref.watch(presentationByIdProvider(id)));
    }
    final isEdit = _existing != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppTopBar(
        title: isEdit ? AppStrings.formEditTitle : AppStrings.formTitle,
        onBack: _back,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.xl,
                    children: [
                      LabelTextField(
                        label: AppStrings.formTitleLabel,
                        controller: _title,
                        hintText: AppStrings.formTitleHint,
                        textInputAction: TextInputAction.done,
                        onChanged: (v) => _update(_draft.copyWith(title: v)),
                      ),
                      _ChipGroup<PresentationType>(
                        label: AppStrings.formTypeLabel,
                        values: PresentationType.values,
                        selected: _draft.type,
                        labelOf: (t) => t.title,
                        onSelected: (t) => _update(_draft.copyWith(type: t)),
                      ),
                      _TimeSpecGroup(draft: _draft, onChanged: _update),
                      _ChipGroup<Audience>(
                        label: AppStrings.formAudienceLabel,
                        values: Audience.values,
                        selected: _draft.audience,
                        labelOf: (a) => a.title,
                        onSelected: (a) =>
                            _update(_draft.copyWith(audience: a)),
                      ),
                      _DateField(
                        date: _draft.date,
                        onPick: _pickDate,
                        onClear: () =>
                            _update(_draft.copyWith(clearDate: true)),
                      ),
                      if (_errors.isNotEmpty || _saveError != null)
                        Semantics(
                          liveRegion: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 6,
                            children: [
                              for (final e in _errors)
                                _ErrorLine(AppStrings.formError(e)),
                              if (_saveError != null) _ErrorLine(_saveError!),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Pen `BottomBar`: 스크롤 밖 고정
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.contentMaxWidth,
                  ),
                  child: PrimaryButton(
                    label: isEdit
                        ? AppStrings.commonSave
                        : AppStrings.formSubmit,
                    onPressed: _saving ? null : _submit,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pen `ChipGroup_*`: 라벨 + 칩 Wrap (좁은 폭에서 줄바꿈)
class _ChipGroup<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  const _ChipGroup({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        _FieldLabel(label),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final v in values)
              AppChip(
                label: labelOf(v),
                selected: v == selected,
                onTap: () => onSelected(v),
              ),
          ],
        ),
      ],
    );
  }
}

/// Pen `TimeSpecGroup`: 라벨 + 스테퍼 2개 + 안내 (+ 20분 초과 시 부분 리허설 고지)
class _TimeSpecGroup extends StatelessWidget {
  final PresentationDraft draft;
  final ValueChanged<PresentationDraft> onChanged;

  const _TimeSpecGroup({required this.draft, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final steppers = [
      StepperField(
        label: AppStrings.formTalkLabel,
        value: draft.talkMinutes.toInt(),
        unit: AppStrings.formMinuteUnit,
        min: AppConfig.talkMinutesMin,
        max: AppConfig.talkMinutesMax,
        onChanged: (v) => onChanged(draft.copyWith(talkMinutes: v)),
      ),
      StepperField(
        label: AppStrings.formQaLabel,
        value: draft.qaMinutes.toInt(),
        unit: AppStrings.formMinuteUnit,
        min: AppConfig.qaMinutesMin,
        max: AppConfig.qaMinutesMax,
        onChanged: (v) => onChanged(draft.copyWith(qaMinutes: v)),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        _FieldLabel(AppStrings.formTimeSpecLabel),
        LayoutBuilder(
          builder: (context, constraints) {
            // 스테퍼 하나에 필요한 최소 폭: 여백 16 + 라벨 + (−·+ 48px 히트 영역 2개) + 값. 이보다 좁으면
            // 라벨이 두 줄로 꺾이므로 세로로 쌓는다 (390 폭 포함 · 디자인 예외, 48px 히트 영역 우선).
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final stacked =
                (constraints.maxWidth - AppSpacing.md) / 2 < 184 * scale;
            return stacked
                ? Column(spacing: AppSpacing.md, children: steppers)
                : Row(
                    spacing: AppSpacing.md,
                    children: [for (final s in steppers) Expanded(child: s)],
                  );
          },
        ),
        Text(
          AppStrings.formTimeHint,
          style: AppTheme.body(
            fontSize: 12,
            color: AppColors.textTertiary,
            height: 1.5,
          ),
        ),
        if (draft.exceedsRecordingCap)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.sm,
              children: [
                const Icon(
                  LucideIcons.triangleAlert,
                  size: 16,
                  color: AppColors.warning,
                ),
                Expanded(
                  child: Text(
                    AppStrings.formPartialNotice(draft.talkMinutes.toInt()),
                    style: AppTheme.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Pen `Field_발표날짜`: 값(또는 자리표시자) + 달력 아이콘, 값이 있으면 지우기 버튼. 아래 안내 문구.
class _DateField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DateField({
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        _FieldLabel(AppStrings.formDateLabel),
        Semantics(
          button: true,
          label:
              '${AppStrings.formDateLabel}, ${date?.koreanFullDate ?? AppStrings.formDatePlaceholder}',
          child: Material(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        date?.koreanFullDate ?? AppStrings.formDatePlaceholder,
                        style: AppTheme.body(
                          fontSize: 15,
                          color: date == null
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (date != null)
                      IconButton(
                        onPressed: onClear,
                        tooltip: AppStrings.formDateClear,
                        icon: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.only(right: AppSpacing.lg),
                      child: Icon(
                        LucideIcons.calendar,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Text(
          AppStrings.formDateHint,
          style: AppTheme.body(
            fontSize: 12,
            color: AppColors.textTertiary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTheme.body(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
  );
}

class _ErrorLine extends StatelessWidget {
  final String text;
  const _ErrorLine(this.text);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppSpacing.sm,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(LucideIcons.circleAlert, size: 16, color: AppColors.danger),
      ),
      Expanded(
        child: Text(
          text,
          style: AppTheme.body(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.danger,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}
