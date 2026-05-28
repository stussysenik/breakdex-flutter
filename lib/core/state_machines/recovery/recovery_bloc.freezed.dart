// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recovery_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecoveryEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecoveryEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecoveryEvent()';
}


}

/// @nodoc
class $RecoveryEventCopyWith<$Res>  {
$RecoveryEventCopyWith(RecoveryEvent _, $Res Function(RecoveryEvent) __);
}


/// Adds pattern-matching-related methods to [RecoveryEvent].
extension RecoveryEventPatterns on RecoveryEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _StartScan value)?  startScan,TResult Function( _DiscardOrphans value)?  discardOrphans,TResult Function( _RecoverOrphans value)?  recoverOrphans,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StartScan() when startScan != null:
return startScan(_that);case _DiscardOrphans() when discardOrphans != null:
return discardOrphans(_that);case _RecoverOrphans() when recoverOrphans != null:
return recoverOrphans(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _StartScan value)  startScan,required TResult Function( _DiscardOrphans value)  discardOrphans,required TResult Function( _RecoverOrphans value)  recoverOrphans,}){
final _that = this;
switch (_that) {
case _StartScan():
return startScan(_that);case _DiscardOrphans():
return discardOrphans(_that);case _RecoverOrphans():
return recoverOrphans(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _StartScan value)?  startScan,TResult? Function( _DiscardOrphans value)?  discardOrphans,TResult? Function( _RecoverOrphans value)?  recoverOrphans,}){
final _that = this;
switch (_that) {
case _StartScan() when startScan != null:
return startScan(_that);case _DiscardOrphans() when discardOrphans != null:
return discardOrphans(_that);case _RecoverOrphans() when recoverOrphans != null:
return recoverOrphans(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  startScan,TResult Function( List<String> files)?  discardOrphans,TResult Function( List<String> files)?  recoverOrphans,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StartScan() when startScan != null:
return startScan();case _DiscardOrphans() when discardOrphans != null:
return discardOrphans(_that.files);case _RecoverOrphans() when recoverOrphans != null:
return recoverOrphans(_that.files);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  startScan,required TResult Function( List<String> files)  discardOrphans,required TResult Function( List<String> files)  recoverOrphans,}) {final _that = this;
switch (_that) {
case _StartScan():
return startScan();case _DiscardOrphans():
return discardOrphans(_that.files);case _RecoverOrphans():
return recoverOrphans(_that.files);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  startScan,TResult? Function( List<String> files)?  discardOrphans,TResult? Function( List<String> files)?  recoverOrphans,}) {final _that = this;
switch (_that) {
case _StartScan() when startScan != null:
return startScan();case _DiscardOrphans() when discardOrphans != null:
return discardOrphans(_that.files);case _RecoverOrphans() when recoverOrphans != null:
return recoverOrphans(_that.files);case _:
  return null;

}
}

}

/// @nodoc


class _StartScan implements RecoveryEvent {
  const _StartScan();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StartScan);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecoveryEvent.startScan()';
}


}




/// @nodoc


class _DiscardOrphans implements RecoveryEvent {
  const _DiscardOrphans(final  List<String> files): _files = files;
  

 final  List<String> _files;
 List<String> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of RecoveryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscardOrphansCopyWith<_DiscardOrphans> get copyWith => __$DiscardOrphansCopyWithImpl<_DiscardOrphans>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscardOrphans&&const DeepCollectionEquality().equals(other._files, _files));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'RecoveryEvent.discardOrphans(files: $files)';
}


}

/// @nodoc
abstract mixin class _$DiscardOrphansCopyWith<$Res> implements $RecoveryEventCopyWith<$Res> {
  factory _$DiscardOrphansCopyWith(_DiscardOrphans value, $Res Function(_DiscardOrphans) _then) = __$DiscardOrphansCopyWithImpl;
@useResult
$Res call({
 List<String> files
});




}
/// @nodoc
class __$DiscardOrphansCopyWithImpl<$Res>
    implements _$DiscardOrphansCopyWith<$Res> {
  __$DiscardOrphansCopyWithImpl(this._self, this._then);

  final _DiscardOrphans _self;
  final $Res Function(_DiscardOrphans) _then;

/// Create a copy of RecoveryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? files = null,}) {
  return _then(_DiscardOrphans(
null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class _RecoverOrphans implements RecoveryEvent {
  const _RecoverOrphans(final  List<String> files): _files = files;
  

 final  List<String> _files;
 List<String> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of RecoveryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecoverOrphansCopyWith<_RecoverOrphans> get copyWith => __$RecoverOrphansCopyWithImpl<_RecoverOrphans>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecoverOrphans&&const DeepCollectionEquality().equals(other._files, _files));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'RecoveryEvent.recoverOrphans(files: $files)';
}


}

/// @nodoc
abstract mixin class _$RecoverOrphansCopyWith<$Res> implements $RecoveryEventCopyWith<$Res> {
  factory _$RecoverOrphansCopyWith(_RecoverOrphans value, $Res Function(_RecoverOrphans) _then) = __$RecoverOrphansCopyWithImpl;
@useResult
$Res call({
 List<String> files
});




}
/// @nodoc
class __$RecoverOrphansCopyWithImpl<$Res>
    implements _$RecoverOrphansCopyWith<$Res> {
  __$RecoverOrphansCopyWithImpl(this._self, this._then);

  final _RecoverOrphans _self;
  final $Res Function(_RecoverOrphans) _then;

/// Create a copy of RecoveryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? files = null,}) {
  return _then(_RecoverOrphans(
null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$RecoveryState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecoveryState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecoveryState()';
}


}

/// @nodoc
class $RecoveryStateCopyWith<$Res>  {
$RecoveryStateCopyWith(RecoveryState _, $Res Function(RecoveryState) __);
}


/// Adds pattern-matching-related methods to [RecoveryState].
extension RecoveryStatePatterns on RecoveryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Idle value)?  idle,TResult Function( _Scanning value)?  scanning,TResult Function( _OrphansFound value)?  orphansFound,TResult Function( _Reconciling value)?  reconciling,TResult Function( _Done value)?  done,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Scanning() when scanning != null:
return scanning(_that);case _OrphansFound() when orphansFound != null:
return orphansFound(_that);case _Reconciling() when reconciling != null:
return reconciling(_that);case _Done() when done != null:
return done(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Idle value)  idle,required TResult Function( _Scanning value)  scanning,required TResult Function( _OrphansFound value)  orphansFound,required TResult Function( _Reconciling value)  reconciling,required TResult Function( _Done value)  done,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Idle():
return idle(_that);case _Scanning():
return scanning(_that);case _OrphansFound():
return orphansFound(_that);case _Reconciling():
return reconciling(_that);case _Done():
return done(_that);case _Error():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Idle value)?  idle,TResult? Function( _Scanning value)?  scanning,TResult? Function( _OrphansFound value)?  orphansFound,TResult? Function( _Reconciling value)?  reconciling,TResult? Function( _Done value)?  done,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Scanning() when scanning != null:
return scanning(_that);case _OrphansFound() when orphansFound != null:
return orphansFound(_that);case _Reconciling() when reconciling != null:
return reconciling(_that);case _Done() when done != null:
return done(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  scanning,TResult Function( List<String> orphanedFiles)?  orphansFound,TResult Function()?  reconciling,TResult Function()?  done,TResult Function( AppFailure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Scanning() when scanning != null:
return scanning();case _OrphansFound() when orphansFound != null:
return orphansFound(_that.orphanedFiles);case _Reconciling() when reconciling != null:
return reconciling();case _Done() when done != null:
return done();case _Error() when error != null:
return error(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  scanning,required TResult Function( List<String> orphanedFiles)  orphansFound,required TResult Function()  reconciling,required TResult Function()  done,required TResult Function( AppFailure failure)  error,}) {final _that = this;
switch (_that) {
case _Idle():
return idle();case _Scanning():
return scanning();case _OrphansFound():
return orphansFound(_that.orphanedFiles);case _Reconciling():
return reconciling();case _Done():
return done();case _Error():
return error(_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  scanning,TResult? Function( List<String> orphanedFiles)?  orphansFound,TResult? Function()?  reconciling,TResult? Function()?  done,TResult? Function( AppFailure failure)?  error,}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Scanning() when scanning != null:
return scanning();case _OrphansFound() when orphansFound != null:
return orphansFound(_that.orphanedFiles);case _Reconciling() when reconciling != null:
return reconciling();case _Done() when done != null:
return done();case _Error() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _Idle implements RecoveryState {
  const _Idle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Idle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecoveryState.idle()';
}


}




/// @nodoc


class _Scanning implements RecoveryState {
  const _Scanning();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Scanning);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecoveryState.scanning()';
}


}




/// @nodoc


class _OrphansFound implements RecoveryState {
  const _OrphansFound(final  List<String> orphanedFiles): _orphanedFiles = orphanedFiles;
  

 final  List<String> _orphanedFiles;
 List<String> get orphanedFiles {
  if (_orphanedFiles is EqualUnmodifiableListView) return _orphanedFiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orphanedFiles);
}


/// Create a copy of RecoveryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrphansFoundCopyWith<_OrphansFound> get copyWith => __$OrphansFoundCopyWithImpl<_OrphansFound>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrphansFound&&const DeepCollectionEquality().equals(other._orphanedFiles, _orphanedFiles));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_orphanedFiles));

@override
String toString() {
  return 'RecoveryState.orphansFound(orphanedFiles: $orphanedFiles)';
}


}

/// @nodoc
abstract mixin class _$OrphansFoundCopyWith<$Res> implements $RecoveryStateCopyWith<$Res> {
  factory _$OrphansFoundCopyWith(_OrphansFound value, $Res Function(_OrphansFound) _then) = __$OrphansFoundCopyWithImpl;
@useResult
$Res call({
 List<String> orphanedFiles
});




}
/// @nodoc
class __$OrphansFoundCopyWithImpl<$Res>
    implements _$OrphansFoundCopyWith<$Res> {
  __$OrphansFoundCopyWithImpl(this._self, this._then);

  final _OrphansFound _self;
  final $Res Function(_OrphansFound) _then;

/// Create a copy of RecoveryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? orphanedFiles = null,}) {
  return _then(_OrphansFound(
null == orphanedFiles ? _self._orphanedFiles : orphanedFiles // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class _Reconciling implements RecoveryState {
  const _Reconciling();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reconciling);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecoveryState.reconciling()';
}


}




/// @nodoc


class _Done implements RecoveryState {
  const _Done();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Done);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecoveryState.done()';
}


}




/// @nodoc


class _Error implements RecoveryState {
  const _Error(this.failure);
  

 final  AppFailure failure;

/// Create a copy of RecoveryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'RecoveryState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $RecoveryStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 AppFailure failure
});


$AppFailureCopyWith<$Res> get failure;

}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of RecoveryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(_Error(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure,
  ));
}

/// Create a copy of RecoveryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res> get failure {
  
  return $AppFailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
