// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'party_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PartyEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartyEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PartyEvent()';
}


}

/// @nodoc
class $PartyEventCopyWith<$Res>  {
$PartyEventCopyWith(PartyEvent _, $Res Function(PartyEvent) __);
}


/// Adds pattern-matching-related methods to [PartyEvent].
extension PartyEventPatterns on PartyEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Shake value)?  shake,TResult Function( _Tick value)?  tick,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Shake() when shake != null:
return shake(_that);case _Tick() when tick != null:
return tick(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Shake value)  shake,required TResult Function( _Tick value)  tick,}){
final _that = this;
switch (_that) {
case _Shake():
return shake(_that);case _Tick():
return tick(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Shake value)?  shake,TResult? Function( _Tick value)?  tick,}){
final _that = this;
switch (_that) {
case _Shake() when shake != null:
return shake(_that);case _Tick() when tick != null:
return tick(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<Move> allMoves,  int durationMs)?  shake,TResult Function( DateTime now)?  tick,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Shake() when shake != null:
return shake(_that.allMoves,_that.durationMs);case _Tick() when tick != null:
return tick(_that.now);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<Move> allMoves,  int durationMs)  shake,required TResult Function( DateTime now)  tick,}) {final _that = this;
switch (_that) {
case _Shake():
return shake(_that.allMoves,_that.durationMs);case _Tick():
return tick(_that.now);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<Move> allMoves,  int durationMs)?  shake,TResult? Function( DateTime now)?  tick,}) {final _that = this;
switch (_that) {
case _Shake() when shake != null:
return shake(_that.allMoves,_that.durationMs);case _Tick() when tick != null:
return tick(_that.now);case _:
  return null;

}
}

}

/// @nodoc


class _Shake implements PartyEvent {
  const _Shake(final  List<Move> allMoves, this.durationMs): _allMoves = allMoves;
  

 final  List<Move> _allMoves;
 List<Move> get allMoves {
  if (_allMoves is EqualUnmodifiableListView) return _allMoves;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allMoves);
}

 final  int durationMs;

/// Create a copy of PartyEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShakeCopyWith<_Shake> get copyWith => __$ShakeCopyWithImpl<_Shake>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Shake&&const DeepCollectionEquality().equals(other._allMoves, _allMoves)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_allMoves),durationMs);

@override
String toString() {
  return 'PartyEvent.shake(allMoves: $allMoves, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class _$ShakeCopyWith<$Res> implements $PartyEventCopyWith<$Res> {
  factory _$ShakeCopyWith(_Shake value, $Res Function(_Shake) _then) = __$ShakeCopyWithImpl;
@useResult
$Res call({
 List<Move> allMoves, int durationMs
});




}
/// @nodoc
class __$ShakeCopyWithImpl<$Res>
    implements _$ShakeCopyWith<$Res> {
  __$ShakeCopyWithImpl(this._self, this._then);

  final _Shake _self;
  final $Res Function(_Shake) _then;

/// Create a copy of PartyEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? allMoves = null,Object? durationMs = null,}) {
  return _then(_Shake(
null == allMoves ? _self._allMoves : allMoves // ignore: cast_nullable_to_non_nullable
as List<Move>,null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _Tick implements PartyEvent {
  const _Tick(this.now);
  

 final  DateTime now;

/// Create a copy of PartyEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TickCopyWith<_Tick> get copyWith => __$TickCopyWithImpl<_Tick>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tick&&(identical(other.now, now) || other.now == now));
}


@override
int get hashCode => Object.hash(runtimeType,now);

@override
String toString() {
  return 'PartyEvent.tick(now: $now)';
}


}

/// @nodoc
abstract mixin class _$TickCopyWith<$Res> implements $PartyEventCopyWith<$Res> {
  factory _$TickCopyWith(_Tick value, $Res Function(_Tick) _then) = __$TickCopyWithImpl;
@useResult
$Res call({
 DateTime now
});




}
/// @nodoc
class __$TickCopyWithImpl<$Res>
    implements _$TickCopyWith<$Res> {
  __$TickCopyWithImpl(this._self, this._then);

  final _Tick _self;
  final $Res Function(_Tick) _then;

/// Create a copy of PartyEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? now = null,}) {
  return _then(_Tick(
null == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$PartyState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartyState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PartyState()';
}


}

/// @nodoc
class $PartyStateCopyWith<$Res>  {
$PartyStateCopyWith(PartyState _, $Res Function(PartyState) __);
}


/// Adds pattern-matching-related methods to [PartyState].
extension PartyStatePatterns on PartyState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Idle value)?  idle,TResult Function( _Cycling value)?  cycling,TResult Function( _Revealing value)?  revealing,TResult Function( _Revealed value)?  revealed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Cycling() when cycling != null:
return cycling(_that);case _Revealing() when revealing != null:
return revealing(_that);case _Revealed() when revealed != null:
return revealed(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Idle value)  idle,required TResult Function( _Cycling value)  cycling,required TResult Function( _Revealing value)  revealing,required TResult Function( _Revealed value)  revealed,}){
final _that = this;
switch (_that) {
case _Idle():
return idle(_that);case _Cycling():
return cycling(_that);case _Revealing():
return revealing(_that);case _Revealed():
return revealed(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Idle value)?  idle,TResult? Function( _Cycling value)?  cycling,TResult? Function( _Revealing value)?  revealing,TResult? Function( _Revealed value)?  revealed,}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Cycling() when cycling != null:
return cycling(_that);case _Revealing() when revealing != null:
return revealing(_that);case _Revealed() when revealed != null:
return revealed(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( List<Move> allMoves,  Move currentMove,  Move finalMove,  DateTime startTime,  DateTime lastFlip,  int durationMs)?  cycling,TResult Function( Move move)?  revealing,TResult Function( Move move)?  revealed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Cycling() when cycling != null:
return cycling(_that.allMoves,_that.currentMove,_that.finalMove,_that.startTime,_that.lastFlip,_that.durationMs);case _Revealing() when revealing != null:
return revealing(_that.move);case _Revealed() when revealed != null:
return revealed(_that.move);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( List<Move> allMoves,  Move currentMove,  Move finalMove,  DateTime startTime,  DateTime lastFlip,  int durationMs)  cycling,required TResult Function( Move move)  revealing,required TResult Function( Move move)  revealed,}) {final _that = this;
switch (_that) {
case _Idle():
return idle();case _Cycling():
return cycling(_that.allMoves,_that.currentMove,_that.finalMove,_that.startTime,_that.lastFlip,_that.durationMs);case _Revealing():
return revealing(_that.move);case _Revealed():
return revealed(_that.move);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( List<Move> allMoves,  Move currentMove,  Move finalMove,  DateTime startTime,  DateTime lastFlip,  int durationMs)?  cycling,TResult? Function( Move move)?  revealing,TResult? Function( Move move)?  revealed,}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Cycling() when cycling != null:
return cycling(_that.allMoves,_that.currentMove,_that.finalMove,_that.startTime,_that.lastFlip,_that.durationMs);case _Revealing() when revealing != null:
return revealing(_that.move);case _Revealed() when revealed != null:
return revealed(_that.move);case _:
  return null;

}
}

}

/// @nodoc


class _Idle implements PartyState {
  const _Idle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Idle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PartyState.idle()';
}


}




/// @nodoc


class _Cycling implements PartyState {
  const _Cycling({required final  List<Move> allMoves, required this.currentMove, required this.finalMove, required this.startTime, required this.lastFlip, required this.durationMs}): _allMoves = allMoves;
  

 final  List<Move> _allMoves;
 List<Move> get allMoves {
  if (_allMoves is EqualUnmodifiableListView) return _allMoves;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allMoves);
}

 final  Move currentMove;
 final  Move finalMove;
 final  DateTime startTime;
 final  DateTime lastFlip;
 final  int durationMs;

/// Create a copy of PartyState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CyclingCopyWith<_Cycling> get copyWith => __$CyclingCopyWithImpl<_Cycling>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Cycling&&const DeepCollectionEquality().equals(other._allMoves, _allMoves)&&(identical(other.currentMove, currentMove) || other.currentMove == currentMove)&&(identical(other.finalMove, finalMove) || other.finalMove == finalMove)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.lastFlip, lastFlip) || other.lastFlip == lastFlip)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_allMoves),currentMove,finalMove,startTime,lastFlip,durationMs);

@override
String toString() {
  return 'PartyState.cycling(allMoves: $allMoves, currentMove: $currentMove, finalMove: $finalMove, startTime: $startTime, lastFlip: $lastFlip, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class _$CyclingCopyWith<$Res> implements $PartyStateCopyWith<$Res> {
  factory _$CyclingCopyWith(_Cycling value, $Res Function(_Cycling) _then) = __$CyclingCopyWithImpl;
@useResult
$Res call({
 List<Move> allMoves, Move currentMove, Move finalMove, DateTime startTime, DateTime lastFlip, int durationMs
});




}
/// @nodoc
class __$CyclingCopyWithImpl<$Res>
    implements _$CyclingCopyWith<$Res> {
  __$CyclingCopyWithImpl(this._self, this._then);

  final _Cycling _self;
  final $Res Function(_Cycling) _then;

/// Create a copy of PartyState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? allMoves = null,Object? currentMove = null,Object? finalMove = null,Object? startTime = null,Object? lastFlip = null,Object? durationMs = null,}) {
  return _then(_Cycling(
allMoves: null == allMoves ? _self._allMoves : allMoves // ignore: cast_nullable_to_non_nullable
as List<Move>,currentMove: null == currentMove ? _self.currentMove : currentMove // ignore: cast_nullable_to_non_nullable
as Move,finalMove: null == finalMove ? _self.finalMove : finalMove // ignore: cast_nullable_to_non_nullable
as Move,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,lastFlip: null == lastFlip ? _self.lastFlip : lastFlip // ignore: cast_nullable_to_non_nullable
as DateTime,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _Revealing implements PartyState {
  const _Revealing({required this.move});
  

 final  Move move;

/// Create a copy of PartyState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevealingCopyWith<_Revealing> get copyWith => __$RevealingCopyWithImpl<_Revealing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Revealing&&(identical(other.move, move) || other.move == move));
}


@override
int get hashCode => Object.hash(runtimeType,move);

@override
String toString() {
  return 'PartyState.revealing(move: $move)';
}


}

/// @nodoc
abstract mixin class _$RevealingCopyWith<$Res> implements $PartyStateCopyWith<$Res> {
  factory _$RevealingCopyWith(_Revealing value, $Res Function(_Revealing) _then) = __$RevealingCopyWithImpl;
@useResult
$Res call({
 Move move
});




}
/// @nodoc
class __$RevealingCopyWithImpl<$Res>
    implements _$RevealingCopyWith<$Res> {
  __$RevealingCopyWithImpl(this._self, this._then);

  final _Revealing _self;
  final $Res Function(_Revealing) _then;

/// Create a copy of PartyState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? move = null,}) {
  return _then(_Revealing(
move: null == move ? _self.move : move // ignore: cast_nullable_to_non_nullable
as Move,
  ));
}


}

/// @nodoc


class _Revealed implements PartyState {
  const _Revealed({required this.move});
  

 final  Move move;

/// Create a copy of PartyState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevealedCopyWith<_Revealed> get copyWith => __$RevealedCopyWithImpl<_Revealed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Revealed&&(identical(other.move, move) || other.move == move));
}


@override
int get hashCode => Object.hash(runtimeType,move);

@override
String toString() {
  return 'PartyState.revealed(move: $move)';
}


}

/// @nodoc
abstract mixin class _$RevealedCopyWith<$Res> implements $PartyStateCopyWith<$Res> {
  factory _$RevealedCopyWith(_Revealed value, $Res Function(_Revealed) _then) = __$RevealedCopyWithImpl;
@useResult
$Res call({
 Move move
});




}
/// @nodoc
class __$RevealedCopyWithImpl<$Res>
    implements _$RevealedCopyWith<$Res> {
  __$RevealedCopyWithImpl(this._self, this._then);

  final _Revealed _self;
  final $Res Function(_Revealed) _then;

/// Create a copy of PartyState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? move = null,}) {
  return _then(_Revealed(
move: null == move ? _self.move : move // ignore: cast_nullable_to_non_nullable
as Move,
  ));
}


}

// dart format on
