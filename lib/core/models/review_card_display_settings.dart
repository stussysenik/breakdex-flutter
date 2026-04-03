class ReviewCardDisplaySettings {
  const ReviewCardDisplaySettings({
    this.showTitle = true,
    this.showState = true,
    this.showCategory = true,
    this.showComboTimeline = true,
    this.showComboStepName = true,
    this.showPlaybackControls = true,
  });

  static const defaults = ReviewCardDisplaySettings();

  final bool showTitle;
  final bool showState;
  final bool showCategory;
  final bool showComboTimeline;
  final bool showComboStepName;
  final bool showPlaybackControls;

  ReviewCardDisplaySettings copyWith({
    bool? showTitle,
    bool? showState,
    bool? showCategory,
    bool? showComboTimeline,
    bool? showComboStepName,
    bool? showPlaybackControls,
  }) {
    return ReviewCardDisplaySettings(
      showTitle: showTitle ?? this.showTitle,
      showState: showState ?? this.showState,
      showCategory: showCategory ?? this.showCategory,
      showComboTimeline: showComboTimeline ?? this.showComboTimeline,
      showComboStepName: showComboStepName ?? this.showComboStepName,
      showPlaybackControls:
          showPlaybackControls ?? this.showPlaybackControls,
    );
  }
}
