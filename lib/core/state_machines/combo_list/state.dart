import 'package:flutter/foundation.dart';

sealed class ComboListState {
  const ComboListState();
}

class ComboViewBasic extends ComboListState {
  const ComboViewBasic();
}

class ComboViewPractice extends ComboListState {
  const ComboViewPractice();
}
