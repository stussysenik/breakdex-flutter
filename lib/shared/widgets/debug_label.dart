import 'package:flutter/material.dart';

class TaggedBuilder extends StatelessWidget {
  const TaggedBuilder({
    super.key,
    required this.tag,
    required this.builder,
    this.defaultWidget,
  });

  final String tag;
  final Widget Function(BuildContext) builder;
  final Widget? defaultWidget;

  @override
  Widget build(final BuildContext context) {
    late final Widget child;
    try {
      child = builder(context);
    } on Object catch (_) {
      child = defaultWidget ?? const SizedBox.shrink();
    }
    return _TaggedWidget(tag: tag, child: child);
  }
}

class _TaggedWidget extends InheritedWidget {
  const _TaggedWidget({required this.tag, required super.child});

  final String tag;

  @override
  bool updateShouldNotify(final _TaggedWidget old) => tag != old.tag;
}
