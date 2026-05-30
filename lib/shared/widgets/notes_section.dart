import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/colors.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/providers.dart';

/// Inline notes editor with markdown rendering and @mention links.
///
/// Two modes:
/// - **Read**: renders markdown with tappable @mention links. Constrained to
///   150px with a "Show more" toggle. Tap to enter edit mode.
/// - **Edit**: raw TextField with auto-save (1s debounce). Focus loss returns
///   to read mode and flushes any pending save.
class NotesSection extends ConsumerStatefulWidget {
  const NotesSection({
    super.key,
    required this.notes,
    required this.onChanged,
  });

  final String? notes;
  final ValueChanged<String> onChanged;

  @override
  ConsumerState<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends ConsumerState<NotesSection> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _editing = false;
  bool _expanded = false;

  /// The last value we persisted (or the initial value). Tracked so we only
  /// call onChanged when the text actually differs.
  String _lastSaved = '';

  @override
  void initState() {
    super.initState();
    _lastSaved = widget.notes ?? '';
    _controller = TextEditingController(text: _lastSaved);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant NotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync the controller text when NOT editing — prevents cursor jump
    // while the user is typing and the StreamBuilder rebuilds.
    if (!_editing && widget.notes != oldWidget.notes) {
      final incoming = widget.notes ?? '';
      _controller.text = incoming;
      _lastSaved = incoming;
    }
  }

  @override
  void dispose() {
    _flushPendingSave();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editing) {
      _flushPendingSave();
      setState(() => _editing = false);
    }
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      _save(value);
    });
  }

  void _save(String value) {
    if (value == _lastSaved) return;
    _lastSaved = value;
    widget.onChanged(value);
  }

  void _flushPendingSave() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      _save(_controller.text);
    }
  }

  void _enterEditMode() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) return _buildEditor(context);
    return _buildReader(context)
        .animate(key: ValueKey('notes-reader-${widget.notes}'))
        .fadeIn(duration: 200.ms);
  }

  // ---------------------------------------------------------------------------
  // Read mode
  // ---------------------------------------------------------------------------

  Widget _buildReader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = widget.notes;
    final isEmpty = text == null || text.trim().isEmpty;

    if (isEmpty) {
      return GestureDetector(
        onTap: _enterEditMode,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.15),
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            'Add notes...',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _enterEditMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOTES',
            style: AppTypography.sectionHeader.copyWith(
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ConstrainedMarkdown(
            text: text,
            expanded: _expanded,
            onMentionTap: _navigateToMention,
            onOverflowChanged: (overflows) {
              // Only show toggle when content overflows
              if (overflows != _showToggle) {
                setState(() => _showToggle = overflows);
              }
            },
          ),
          if (_showToggle)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  _expanded ? 'Show less' : 'Show more',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _showToggle = false;

  // ---------------------------------------------------------------------------
  // Edit mode
  // ---------------------------------------------------------------------------

  Widget _buildEditor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'NOTES',
                style: AppTypography.sectionHeader.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _flushPendingSave();
                setState(() => _editing = false);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: null,
          minLines: 3,
          onChanged: _onTextChanged,
          style: AppTypography.bodySmall.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Write notes... Use @move-name to link',
            hintStyle: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary.withValues(alpha: 0.4),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.sm),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // @mention navigation
  // ---------------------------------------------------------------------------

  void _navigateToMention(String href) {
    if (href.startsWith('/')) {
      context.push('/moves$href');
    }
  }
}

// =============================================================================
// _ConstrainedMarkdown — renders markdown, detects overflow, constrains height
// =============================================================================

class _ConstrainedMarkdown extends ConsumerStatefulWidget {
  const _ConstrainedMarkdown({
    required this.text,
    required this.expanded,
    required this.onMentionTap,
    required this.onOverflowChanged,
  });

  final String text;
  final bool expanded;
  final ValueChanged<String> onMentionTap;
  final ValueChanged<bool> onOverflowChanged;

  @override
  ConsumerState<_ConstrainedMarkdown> createState() =>
      _ConstrainedMarkdownState();
}

class _ConstrainedMarkdownState extends ConsumerState<_ConstrainedMarkdown> {
  static const _collapsedHeight = 150.0;
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  @override
  void didUpdateWidget(covariant _ConstrainedMarkdown old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.expanded != widget.expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
    }
  }

  void _checkOverflow() {
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      widget.onOverflowChanged(box.size.height > _collapsedHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hidden unconstrained copy for measurement
        Offstage(
          offstage: true,
          child: _MentionMarkdownBody(
            key: _contentKey,
            data: widget.text,
            onMentionTap: widget.onMentionTap,
          ),
        ),
        // Visible constrained copy
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.hardEdge,
          constraints: BoxConstraints(
            maxHeight: widget.expanded ? double.infinity : _collapsedHeight,
          ),
          decoration: const BoxDecoration(), // needed for clipBehavior
          child: _MentionMarkdownBody(
            data: widget.text,
            onMentionTap: widget.onMentionTap,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _MentionMarkdownBody — markdown renderer with @mention preprocessing
// =============================================================================

class _MentionMarkdownBody extends ConsumerWidget {
  const _MentionMarkdownBody({
    super.key,
    required this.data,
    required this.onMentionTap,
  });

  final String data;
  final ValueChanged<String> onMentionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<String>(
      future: _resolveMentions(ref, data),
      builder: (context, snapshot) {
        final resolved = snapshot.data ?? data;
        return MarkdownBody(
          data: resolved,
          selectable: false,
          onTapLink: (text, href, title) {
            if (href != null) onMentionTap(href);
          },
          styleSheet: MarkdownStyleSheet(
            p: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurface,
            ),
            a: AppTypography.bodySmall.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
            h1: AppTypography.titleSmall.copyWith(
              color: colorScheme.onSurface,
            ),
            h2: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            listBullet: AppTypography.bodySmall.copyWith(
              color: colorScheme.secondary,
            ),
            code: AppTypography.caption.copyWith(
              color: AppColors.accent,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
        );
      },
    );
  }

  /// Replaces `@some-name` with markdown links if the name matches a move or combo.
  static Future<String> _resolveMentions(WidgetRef ref, String text) async {
    final mentionPattern = RegExp(r'@([\w-]+)');
    final matches = mentionPattern.allMatches(text);
    if (matches.isEmpty) return text;

    final moves = await ref.read(moveRepositoryProvider).getAll();
    final combos = await ref.read(comboRepositoryProvider).getAll();

    // Build lookup: lowercase name → (type, id)
    final lookup = <String, (String, String)>{};
    for (final m in moves) {
      lookup[m.name.toLowerCase()] = ('move', m.id);
    }
    for (final c in combos) {
      lookup[c.name.toLowerCase()] = ('combo', c.id);
    }

    var result = text;
    // Process in reverse so string offsets stay valid
    for (final match in matches.toList().reversed) {
      final mentionName = match.group(1)!;
      final entry = lookup[mentionName.toLowerCase()];
      if (entry != null) {
        final (type, id) = entry;
        final link = '[@$mentionName](/$type/$id)';
        result = result.replaceRange(match.start, match.end, link);
      }
    }

    return result;
  }
}
