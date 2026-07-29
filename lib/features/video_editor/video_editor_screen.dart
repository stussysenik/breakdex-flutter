// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:breakdex/core/providers.dart';
import 'package:breakdex/core/services/settings_service.dart';
import 'package:breakdex/features/video_editor/robust_video_editor_view.dart';
import 'package:breakdex/features/video_editor/simplified_video_editor_screen.dart'
    show SimplifiedVideoEditorView;
import 'package:breakdex/features/video_editor/video_editor_controller.dart';
import 'package:breakdex/core/design/icons.dart';

class VideoEditorScreen extends ConsumerStatefulWidget {
  const VideoEditorScreen({super.key, required this.videoPath});

  final String videoPath;

  @override
  ConsumerState<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends ConsumerState<VideoEditorScreen> {
  late VideoEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoEditorController(
      videoPath: widget.videoPath,
      videoService: ref.read(videoServiceProvider),
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final useSimplified = ref.watch(useSimplifiedVideoEditorProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          HapticFeedback.mediumImpact();
          ref.read(useSimplifiedVideoEditorProvider.notifier).toggle();
        },
        backgroundColor: colorScheme.secondaryContainer,
        child: Icon(
          useSimplified
              ? AppIcon.grid.resolve(context)
              : AppIcon.video.resolve(context),
          color: colorScheme.onSecondaryContainer,
        ),
      ),
      body: SafeArea(
        child: useSimplified
            ? SimplifiedVideoEditorView(videoPath: widget.videoPath)
            : RobustVideoEditorView(controller: _controller),
      ),
    );
  }
}
