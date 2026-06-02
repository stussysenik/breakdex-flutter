import '../machine.dart';
import 'state.dart';
import 'event.dart';

final class ComboListMachine extends Machine<ComboListState, ComboListEvent> {
  ComboListMachine() : super(const ComboViewBasic());

  @override
  String get diagnosticsLabel => 'ComboList';

  @override
  ComboListState? transition(final ComboListState s, final ComboListEvent e) {
    return switch ((s, e)) {
      (_, SelectBasicView()) => const ComboViewBasic(),
      (_, SelectPracticeView()) => const ComboViewPractice(),
      _ => null,
    };
  }
}
