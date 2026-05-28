// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SyncEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncEvent()';
}


}

/// @nodoc
class $SyncEventCopyWith<$Res>  {
$SyncEventCopyWith(SyncEvent _, $Res Function(SyncEvent) __);
}


/// Adds pattern-matching-related methods to [SyncEvent].
extension SyncEventPatterns on SyncEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _StartSync value)?  startSync,TResult Function( _ProgressUpdated value)?  progressUpdated,TResult Function( _PhaseCompleted value)?  phaseCompleted,TResult Function( _Failed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StartSync() when startSync != null:
return startSync(_that);case _ProgressUpdated() when progressUpdated != null:
return progressUpdated(_that);case _PhaseCompleted() when phaseCompleted != null:
return phaseCompleted(_that);case _Failed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _StartSync value)  startSync,required TResult Function( _ProgressUpdated value)  progressUpdated,required TResult Function( _PhaseCompleted value)  phaseCompleted,required TResult Function( _Failed value)  failed,}){
final _that = this;
switch (_that) {
case _StartSync():
return startSync(_that);case _ProgressUpdated():
return progressUpdated(_that);case _PhaseCompleted():
return phaseCompleted(_that);case _Failed():
return failed(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _StartSync value)?  startSync,TResult? Function( _ProgressUpdated value)?  progressUpdated,TResult? Function( _PhaseCompleted value)?  phaseCompleted,TResult? Function( _Failed value)?  failed,}){
final _that = this;
switch (_that) {
case _StartSync() when startSync != null:
return startSync(_that);case _ProgressUpdated() when progressUpdated != null:
return progressUpdated(_that);case _PhaseCompleted() when phaseCompleted != null:
return phaseCompleted(_that);case _Failed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  startSync,TResult Function( int current,  int total,  String item)?  progressUpdated,TResult Function()?  phaseCompleted,TResult Function( AppFailure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StartSync() when startSync != null:
return startSync();case _ProgressUpdated() when progressUpdated != null:
return progressUpdated(_that.current,_that.total,_that.item);case _PhaseCompleted() when phaseCompleted != null:
return phaseCompleted();case _Failed() when failed != null:
return failed(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  startSync,required TResult Function( int current,  int total,  String item)  progressUpdated,required TResult Function()  phaseCompleted,required TResult Function( AppFailure failure)  failed,}) {final _that = this;
switch (_that) {
case _StartSync():
return startSync();case _ProgressUpdated():
return progressUpdated(_that.current,_that.total,_that.item);case _PhaseCompleted():
return phaseCompleted();case _Failed():
return failed(_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  startSync,TResult? Function( int current,  int total,  String item)?  progressUpdated,TResult? Function()?  phaseCompleted,TResult? Function( AppFailure failure)?  failed,}) {final _that = this;
switch (_that) {
case _StartSync() when startSync != null:
return startSync();case _ProgressUpdated() when progressUpdated != null:
return progressUpdated(_that.current,_that.total,_that.item);case _PhaseCompleted() when phaseCompleted != null:
return phaseCompleted();case _Failed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _StartSync implements SyncEvent {
  const _StartSync();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StartSync);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncEvent.startSync()';
}


}




/// @nodoc


class _ProgressUpdated implements SyncEvent {
  const _ProgressUpdated(this.current, this.total, this.item);
  

 final  int current;
 final  int total;
 final  String item;

/// Create a copy of SyncEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressUpdatedCopyWith<_ProgressUpdated> get copyWith => __$ProgressUpdatedCopyWithImpl<_ProgressUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgressUpdated&&(identical(other.current, current) || other.current == current)&&(identical(other.total, total) || other.total == total)&&(identical(other.item, item) || other.item == item));
}


@override
int get hashCode => Object.hash(runtimeType,current,total,item);

@override
String toString() {
  return 'SyncEvent.progressUpdated(current: $current, total: $total, item: $item)';
}


}

/// @nodoc
abstract mixin class _$ProgressUpdatedCopyWith<$Res> implements $SyncEventCopyWith<$Res> {
  factory _$ProgressUpdatedCopyWith(_ProgressUpdated value, $Res Function(_ProgressUpdated) _then) = __$ProgressUpdatedCopyWithImpl;
@useResult
$Res call({
 int current, int total, String item
});




}
/// @nodoc
class __$ProgressUpdatedCopyWithImpl<$Res>
    implements _$ProgressUpdatedCopyWith<$Res> {
  __$ProgressUpdatedCopyWithImpl(this._self, this._then);

  final _ProgressUpdated _self;
  final $Res Function(_ProgressUpdated) _then;

/// Create a copy of SyncEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? current = null,Object? total = null,Object? item = null,}) {
  return _then(_ProgressUpdated(
null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int,null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _PhaseCompleted implements SyncEvent {
  const _PhaseCompleted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PhaseCompleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncEvent.phaseCompleted()';
}


}




/// @nodoc


class _Failed implements SyncEvent {
  const _Failed(this.failure);
  

 final  AppFailure failure;

/// Create a copy of SyncEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FailedCopyWith<_Failed> get copyWith => __$FailedCopyWithImpl<_Failed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Failed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SyncEvent.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$FailedCopyWith<$Res> implements $SyncEventCopyWith<$Res> {
  factory _$FailedCopyWith(_Failed value, $Res Function(_Failed) _then) = __$FailedCopyWithImpl;
@useResult
$Res call({
 AppFailure failure
});


$AppFailureCopyWith<$Res> get failure;

}
/// @nodoc
class __$FailedCopyWithImpl<$Res>
    implements _$FailedCopyWith<$Res> {
  __$FailedCopyWithImpl(this._self, this._then);

  final _Failed _self;
  final $Res Function(_Failed) _then;

/// Create a copy of SyncEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(_Failed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure,
  ));
}

/// Create a copy of SyncEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppFailureCopyWith<$Res> get failure {
  
  return $AppFailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc
mixin _$SyncState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncState()';
}


}

/// @nodoc
class $SyncStateCopyWith<$Res>  {
$SyncStateCopyWith(SyncState _, $Res Function(SyncState) __);
}


/// Adds pattern-matching-related methods to [SyncState].
extension SyncStatePatterns on SyncState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Idle value)?  idle,TResult Function( _Authenticating value)?  authenticating,TResult Function( _PushingMetadata value)?  pushingMetadata,TResult Function( _UploadingVideos value)?  uploadingVideos,TResult Function( _PullingRemote value)?  pullingRemote,TResult Function( _ReconcilingLegacy value)?  reconcilingLegacy,TResult Function( _DownloadingVideos value)?  downloadingVideos,TResult Function( _ReconcilingAlbums value)?  reconcilingAlbums,TResult Function( _Complete value)?  complete,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Authenticating() when authenticating != null:
return authenticating(_that);case _PushingMetadata() when pushingMetadata != null:
return pushingMetadata(_that);case _UploadingVideos() when uploadingVideos != null:
return uploadingVideos(_that);case _PullingRemote() when pullingRemote != null:
return pullingRemote(_that);case _ReconcilingLegacy() when reconcilingLegacy != null:
return reconcilingLegacy(_that);case _DownloadingVideos() when downloadingVideos != null:
return downloadingVideos(_that);case _ReconcilingAlbums() when reconcilingAlbums != null:
return reconcilingAlbums(_that);case _Complete() when complete != null:
return complete(_that);case _Error() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Idle value)  idle,required TResult Function( _Authenticating value)  authenticating,required TResult Function( _PushingMetadata value)  pushingMetadata,required TResult Function( _UploadingVideos value)  uploadingVideos,required TResult Function( _PullingRemote value)  pullingRemote,required TResult Function( _ReconcilingLegacy value)  reconcilingLegacy,required TResult Function( _DownloadingVideos value)  downloadingVideos,required TResult Function( _ReconcilingAlbums value)  reconcilingAlbums,required TResult Function( _Complete value)  complete,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Idle():
return idle(_that);case _Authenticating():
return authenticating(_that);case _PushingMetadata():
return pushingMetadata(_that);case _UploadingVideos():
return uploadingVideos(_that);case _PullingRemote():
return pullingRemote(_that);case _ReconcilingLegacy():
return reconcilingLegacy(_that);case _DownloadingVideos():
return downloadingVideos(_that);case _ReconcilingAlbums():
return reconcilingAlbums(_that);case _Complete():
return complete(_that);case _Error():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Idle value)?  idle,TResult? Function( _Authenticating value)?  authenticating,TResult? Function( _PushingMetadata value)?  pushingMetadata,TResult? Function( _UploadingVideos value)?  uploadingVideos,TResult? Function( _PullingRemote value)?  pullingRemote,TResult? Function( _ReconcilingLegacy value)?  reconcilingLegacy,TResult? Function( _DownloadingVideos value)?  downloadingVideos,TResult? Function( _ReconcilingAlbums value)?  reconcilingAlbums,TResult? Function( _Complete value)?  complete,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Authenticating() when authenticating != null:
return authenticating(_that);case _PushingMetadata() when pushingMetadata != null:
return pushingMetadata(_that);case _UploadingVideos() when uploadingVideos != null:
return uploadingVideos(_that);case _PullingRemote() when pullingRemote != null:
return pullingRemote(_that);case _ReconcilingLegacy() when reconcilingLegacy != null:
return reconcilingLegacy(_that);case _DownloadingVideos() when downloadingVideos != null:
return downloadingVideos(_that);case _ReconcilingAlbums() when reconcilingAlbums != null:
return reconcilingAlbums(_that);case _Complete() when complete != null:
return complete(_that);case _Error() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  authenticating,TResult Function( int current,  int total,  String item)?  pushingMetadata,TResult Function( int current,  int total,  String item)?  uploadingVideos,TResult Function()?  pullingRemote,TResult Function()?  reconcilingLegacy,TResult Function( int current,  int total,  String item)?  downloadingVideos,TResult Function()?  reconcilingAlbums,TResult Function()?  complete,TResult Function( AppFailure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Authenticating() when authenticating != null:
return authenticating();case _PushingMetadata() when pushingMetadata != null:
return pushingMetadata(_that.current,_that.total,_that.item);case _UploadingVideos() when uploadingVideos != null:
return uploadingVideos(_that.current,_that.total,_that.item);case _PullingRemote() when pullingRemote != null:
return pullingRemote();case _ReconcilingLegacy() when reconcilingLegacy != null:
return reconcilingLegacy();case _DownloadingVideos() when downloadingVideos != null:
return downloadingVideos(_that.current,_that.total,_that.item);case _ReconcilingAlbums() when reconcilingAlbums != null:
return reconcilingAlbums();case _Complete() when complete != null:
return complete();case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  authenticating,required TResult Function( int current,  int total,  String item)  pushingMetadata,required TResult Function( int current,  int total,  String item)  uploadingVideos,required TResult Function()  pullingRemote,required TResult Function()  reconcilingLegacy,required TResult Function( int current,  int total,  String item)  downloadingVideos,required TResult Function()  reconcilingAlbums,required TResult Function()  complete,required TResult Function( AppFailure failure)  error,}) {final _that = this;
switch (_that) {
case _Idle():
return idle();case _Authenticating():
return authenticating();case _PushingMetadata():
return pushingMetadata(_that.current,_that.total,_that.item);case _UploadingVideos():
return uploadingVideos(_that.current,_that.total,_that.item);case _PullingRemote():
return pullingRemote();case _ReconcilingLegacy():
return reconcilingLegacy();case _DownloadingVideos():
return downloadingVideos(_that.current,_that.total,_that.item);case _ReconcilingAlbums():
return reconcilingAlbums();case _Complete():
return complete();case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  authenticating,TResult? Function( int current,  int total,  String item)?  pushingMetadata,TResult? Function( int current,  int total,  String item)?  uploadingVideos,TResult? Function()?  pullingRemote,TResult? Function()?  reconcilingLegacy,TResult? Function( int current,  int total,  String item)?  downloadingVideos,TResult? Function()?  reconcilingAlbums,TResult? Function()?  complete,TResult? Function( AppFailure failure)?  error,}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Authenticating() when authenticating != null:
return authenticating();case _PushingMetadata() when pushingMetadata != null:
return pushingMetadata(_that.current,_that.total,_that.item);case _UploadingVideos() when uploadingVideos != null:
return uploadingVideos(_that.current,_that.total,_that.item);case _PullingRemote() when pullingRemote != null:
return pullingRemote();case _ReconcilingLegacy() when reconcilingLegacy != null:
return reconcilingLegacy();case _DownloadingVideos() when downloadingVideos != null:
return downloadingVideos(_that.current,_that.total,_that.item);case _ReconcilingAlbums() when reconcilingAlbums != null:
return reconcilingAlbums();case _Complete() when complete != null:
return complete();case _Error() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _Idle implements SyncState {
  const _Idle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Idle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncState.idle()';
}


}




/// @nodoc


class _Authenticating implements SyncState {
  const _Authenticating();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Authenticating);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncState.authenticating()';
}


}




/// @nodoc


class _PushingMetadata implements SyncState {
  const _PushingMetadata(this.current, this.total, this.item);
  

 final  int current;
 final  int total;
 final  String item;

/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushingMetadataCopyWith<_PushingMetadata> get copyWith => __$PushingMetadataCopyWithImpl<_PushingMetadata>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushingMetadata&&(identical(other.current, current) || other.current == current)&&(identical(other.total, total) || other.total == total)&&(identical(other.item, item) || other.item == item));
}


@override
int get hashCode => Object.hash(runtimeType,current,total,item);

@override
String toString() {
  return 'SyncState.pushingMetadata(current: $current, total: $total, item: $item)';
}


}

/// @nodoc
abstract mixin class _$PushingMetadataCopyWith<$Res> implements $SyncStateCopyWith<$Res> {
  factory _$PushingMetadataCopyWith(_PushingMetadata value, $Res Function(_PushingMetadata) _then) = __$PushingMetadataCopyWithImpl;
@useResult
$Res call({
 int current, int total, String item
});




}
/// @nodoc
class __$PushingMetadataCopyWithImpl<$Res>
    implements _$PushingMetadataCopyWith<$Res> {
  __$PushingMetadataCopyWithImpl(this._self, this._then);

  final _PushingMetadata _self;
  final $Res Function(_PushingMetadata) _then;

/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? current = null,Object? total = null,Object? item = null,}) {
  return _then(_PushingMetadata(
null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int,null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _UploadingVideos implements SyncState {
  const _UploadingVideos(this.current, this.total, this.item);
  

 final  int current;
 final  int total;
 final  String item;

/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadingVideosCopyWith<_UploadingVideos> get copyWith => __$UploadingVideosCopyWithImpl<_UploadingVideos>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadingVideos&&(identical(other.current, current) || other.current == current)&&(identical(other.total, total) || other.total == total)&&(identical(other.item, item) || other.item == item));
}


@override
int get hashCode => Object.hash(runtimeType,current,total,item);

@override
String toString() {
  return 'SyncState.uploadingVideos(current: $current, total: $total, item: $item)';
}


}

/// @nodoc
abstract mixin class _$UploadingVideosCopyWith<$Res> implements $SyncStateCopyWith<$Res> {
  factory _$UploadingVideosCopyWith(_UploadingVideos value, $Res Function(_UploadingVideos) _then) = __$UploadingVideosCopyWithImpl;
@useResult
$Res call({
 int current, int total, String item
});




}
/// @nodoc
class __$UploadingVideosCopyWithImpl<$Res>
    implements _$UploadingVideosCopyWith<$Res> {
  __$UploadingVideosCopyWithImpl(this._self, this._then);

  final _UploadingVideos _self;
  final $Res Function(_UploadingVideos) _then;

/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? current = null,Object? total = null,Object? item = null,}) {
  return _then(_UploadingVideos(
null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int,null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _PullingRemote implements SyncState {
  const _PullingRemote();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PullingRemote);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncState.pullingRemote()';
}


}




/// @nodoc


class _ReconcilingLegacy implements SyncState {
  const _ReconcilingLegacy();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReconcilingLegacy);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncState.reconcilingLegacy()';
}


}




/// @nodoc


class _DownloadingVideos implements SyncState {
  const _DownloadingVideos(this.current, this.total, this.item);
  

 final  int current;
 final  int total;
 final  String item;

/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadingVideosCopyWith<_DownloadingVideos> get copyWith => __$DownloadingVideosCopyWithImpl<_DownloadingVideos>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadingVideos&&(identical(other.current, current) || other.current == current)&&(identical(other.total, total) || other.total == total)&&(identical(other.item, item) || other.item == item));
}


@override
int get hashCode => Object.hash(runtimeType,current,total,item);

@override
String toString() {
  return 'SyncState.downloadingVideos(current: $current, total: $total, item: $item)';
}


}

/// @nodoc
abstract mixin class _$DownloadingVideosCopyWith<$Res> implements $SyncStateCopyWith<$Res> {
  factory _$DownloadingVideosCopyWith(_DownloadingVideos value, $Res Function(_DownloadingVideos) _then) = __$DownloadingVideosCopyWithImpl;
@useResult
$Res call({
 int current, int total, String item
});




}
/// @nodoc
class __$DownloadingVideosCopyWithImpl<$Res>
    implements _$DownloadingVideosCopyWith<$Res> {
  __$DownloadingVideosCopyWithImpl(this._self, this._then);

  final _DownloadingVideos _self;
  final $Res Function(_DownloadingVideos) _then;

/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? current = null,Object? total = null,Object? item = null,}) {
  return _then(_DownloadingVideos(
null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int,null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ReconcilingAlbums implements SyncState {
  const _ReconcilingAlbums();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReconcilingAlbums);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncState.reconcilingAlbums()';
}


}




/// @nodoc


class _Complete implements SyncState {
  const _Complete();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Complete);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SyncState.complete()';
}


}




/// @nodoc


class _Error implements SyncState {
  const _Error(this.failure);
  

 final  AppFailure failure;

/// Create a copy of SyncState
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
  return 'SyncState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $SyncStateCopyWith<$Res> {
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

/// Create a copy of SyncState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(_Error(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure,
  ));
}

/// Create a copy of SyncState
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
