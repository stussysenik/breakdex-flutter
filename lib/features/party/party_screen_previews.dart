// GENERATED preview entries for PartyScreen. Safe to edit — add @Preview variants
// (sizes, brightness, seeded states) as you iterate on this screen.
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:breakdex/dev/preview_harness.dart';
import 'package:breakdex/features/party/bloc/party_bloc.dart';
import 'package:breakdex/features/party/party_screen.dart';

Widget _partyScreenWithBloc() => BlocProvider<PartyBloc>(
  create: (_) => PartyBloc(),
  child: const PartyScreen(),
);

@Preview(name: 'PartyScreen · light', group: 'party', wrapper: wrapLight)
Widget partyScreenLight() => _partyScreenWithBloc();

@Preview(name: 'PartyScreen · dark', group: 'party', wrapper: wrapDark)
Widget partyScreenDark() => _partyScreenWithBloc();
