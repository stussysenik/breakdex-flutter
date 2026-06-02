import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state_machines/combo_list/machine.dart';
import '../../../core/state_machines/combo_list/state.dart';
import '../../../core/state_machines/combo_list/event.dart';

class ComboListNotifier extends Notifier<ComboListState> {
  late final ComboListMachine _machine;

  @override
  ComboListState build() {
    _machine = ComboListMachine();
    return _machine.state;
  }

  void send(final ComboListEvent event) {
    _machine.send(event);
    state = _machine.state;
  }
}

final comboListProvider = NotifierProvider<ComboListNotifier, ComboListState>(
  ComboListNotifier.new,
);
