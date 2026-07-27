import 'package:breakdex/core/state_machines/machine.dart';
import 'package:breakdex/core/state_machines/combo_list/state.dart';
import 'package:breakdex/core/state_machines/combo_list/event.dart';

final class ComboListMachine extends Machine<ComboListState, ComboListEvent> {
  ComboListMachine() : super(const ComboViewBasic());

  @override
  String get diagnosticsLabel => 'ComboList';

  @override
  ComboListState? transition(final ComboListState s, final ComboListEvent e) {
    return switch ((s, e)) {
      (_, SelectBasicView()) => const ComboViewBasic(),
      (_, SelectPracticeView()) => const ComboViewPractice(),
    };
  }
}
