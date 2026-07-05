import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/design/spacing.dart';
import '../../../core/design/typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/diagnostics.dart';
import 'library_video_picker_sheet.dart';

/// The pinned capture affordance: text field, "+ video", accent send.
/// One action — jot it down. Every send appends one immutable journal row.
class JotComposer extends ConsumerStatefulWidget {
  const JotComposer({super.key, required this.comboId});

  final String comboId;

  @override
  ConsumerState<JotComposer> createState() => _JotComposerState();
}

class _JotComposerState extends ConsumerState<JotComposer> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;

    final log = StageLogger.begin('JotComposer._send',
        subsystem: 'ComboJourney',
        context: {'comboId': widget.comboId, 'length': body.length});
    try {
      unawaited(HapticFeedback.mediumImpact());
      await ref.read(comboNoteEntriesDaoProvider).addEntry(
            id: const Uuid().v4(),
            comboId: widget.comboId,
            body: body,
          );
      log.stage('jotWritten');
      // Evidence-based plan completion: a jot today completes today's plan.
      await ref.read(comboPlansDaoProvider).stampCompletionsFromEvidence();
      log.stage('completionsStamped');
      _controller.clear();
      log.complete();
    } on Object catch (e, stack) {
      log.fail(e, stack);
      _showError("Couldn't save your jot. Try again.");
    }
  }

  /// Surfaces a failed write to the user instead of swallowing it silently.
  void _showError(final String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _attachVideo() async {
    await LibraryVideoPickerSheet.show(
      context,
      comboId: widget.comboId,
      onVideoPicked: (final relativePath, final hash) async {
        if (!mounted) return;

        final log = StageLogger.begin('JotComposer._attachVideo',
            subsystem: 'ComboJourney',
            context: {'comboId': widget.comboId, 'path': relativePath});
        try {
          final basename = p.basename(relativePath);
          final typed = _controller.text.trim();
          final label = basename.isNotEmpty ? basename : 'Video';
          await ref.read(comboNoteEntriesDaoProvider).addEntry(
                id: const Uuid().v4(),
                comboId: widget.comboId,
                body: typed.isNotEmpty ? typed : 'Linked $label',
                videoPath: relativePath,
                videoHash: hash,
              );
          log.stage('refWritten');
          await ref.read(comboPlansDaoProvider).stampCompletionsFromEvidence();
          log.stage('completionsStamped');
          _controller.clear();
          unawaited(HapticFeedback.mediumImpact());
          log.complete();
        } on Object catch (e, stack) {
          log.fail(e, stack);
          _showError("Couldn't link the video. Try again.");
        }
      },
    );
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // "+ video" — verb-labelled, ≥48dp hit area
          GestureDetector(
            onTap: _attachVideo,
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              alignment: Alignment.center,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                '+ video',
                style: AppTypography.caption.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              style: AppTypography.bodySmall
                  .copyWith(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Jot it down…',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: colorScheme.secondary.withValues(alpha: 0.6),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Send — 44dp accent circle inside a ≥48dp hit area
          GestureDetector(
            onTap: _hasText ? _send : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: AppMotion.fast02,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hasText
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.3),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
