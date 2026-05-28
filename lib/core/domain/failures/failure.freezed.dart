// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppFailure {

 String? get message;
/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppFailureCopyWith<AppFailure> get copyWith => _$AppFailureCopyWithImpl<AppFailure>(this as AppFailure, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppFailure(message: $message)';
}


}

/// @nodoc
abstract mixin class $AppFailureCopyWith<$Res>  {
  factory $AppFailureCopyWith(AppFailure value, $Res Function(AppFailure) _then) = _$AppFailureCopyWithImpl;
@useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$AppFailureCopyWithImpl<$Res>
    implements $AppFailureCopyWith<$Res> {
  _$AppFailureCopyWithImpl(this._self, this._then);

  final AppFailure _self;
  final $Res Function(AppFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = freezed,}) {
  return _then(_self.copyWith(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppFailure].
extension AppFailurePatterns on AppFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _NetworkFailure value)?  network,TResult Function( _DatabaseFailure value)?  database,TResult Function( _SyncFailure value)?  sync,TResult Function( _FileSystemFailure value)?  fileSystem,TResult Function( _UnexpectedFailure value)?  unexpected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NetworkFailure() when network != null:
return network(_that);case _DatabaseFailure() when database != null:
return database(_that);case _SyncFailure() when sync != null:
return sync(_that);case _FileSystemFailure() when fileSystem != null:
return fileSystem(_that);case _UnexpectedFailure() when unexpected != null:
return unexpected(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _NetworkFailure value)  network,required TResult Function( _DatabaseFailure value)  database,required TResult Function( _SyncFailure value)  sync,required TResult Function( _FileSystemFailure value)  fileSystem,required TResult Function( _UnexpectedFailure value)  unexpected,}){
final _that = this;
switch (_that) {
case _NetworkFailure():
return network(_that);case _DatabaseFailure():
return database(_that);case _SyncFailure():
return sync(_that);case _FileSystemFailure():
return fileSystem(_that);case _UnexpectedFailure():
return unexpected(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _NetworkFailure value)?  network,TResult? Function( _DatabaseFailure value)?  database,TResult? Function( _SyncFailure value)?  sync,TResult? Function( _FileSystemFailure value)?  fileSystem,TResult? Function( _UnexpectedFailure value)?  unexpected,}){
final _that = this;
switch (_that) {
case _NetworkFailure() when network != null:
return network(_that);case _DatabaseFailure() when database != null:
return database(_that);case _SyncFailure() when sync != null:
return sync(_that);case _FileSystemFailure() when fileSystem != null:
return fileSystem(_that);case _UnexpectedFailure() when unexpected != null:
return unexpected(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? message)?  network,TResult Function( String? message)?  database,TResult Function( String? message)?  sync,TResult Function( String? message)?  fileSystem,TResult Function( String? message)?  unexpected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NetworkFailure() when network != null:
return network(_that.message);case _DatabaseFailure() when database != null:
return database(_that.message);case _SyncFailure() when sync != null:
return sync(_that.message);case _FileSystemFailure() when fileSystem != null:
return fileSystem(_that.message);case _UnexpectedFailure() when unexpected != null:
return unexpected(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? message)  network,required TResult Function( String? message)  database,required TResult Function( String? message)  sync,required TResult Function( String? message)  fileSystem,required TResult Function( String? message)  unexpected,}) {final _that = this;
switch (_that) {
case _NetworkFailure():
return network(_that.message);case _DatabaseFailure():
return database(_that.message);case _SyncFailure():
return sync(_that.message);case _FileSystemFailure():
return fileSystem(_that.message);case _UnexpectedFailure():
return unexpected(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? message)?  network,TResult? Function( String? message)?  database,TResult? Function( String? message)?  sync,TResult? Function( String? message)?  fileSystem,TResult? Function( String? message)?  unexpected,}) {final _that = this;
switch (_that) {
case _NetworkFailure() when network != null:
return network(_that.message);case _DatabaseFailure() when database != null:
return database(_that.message);case _SyncFailure() when sync != null:
return sync(_that.message);case _FileSystemFailure() when fileSystem != null:
return fileSystem(_that.message);case _UnexpectedFailure() when unexpected != null:
return unexpected(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _NetworkFailure implements AppFailure {
  const _NetworkFailure([this.message]);
  

@override final  String? message;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkFailureCopyWith<_NetworkFailure> get copyWith => __$NetworkFailureCopyWithImpl<_NetworkFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppFailure.network(message: $message)';
}


}

/// @nodoc
abstract mixin class _$NetworkFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory _$NetworkFailureCopyWith(_NetworkFailure value, $Res Function(_NetworkFailure) _then) = __$NetworkFailureCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class __$NetworkFailureCopyWithImpl<$Res>
    implements _$NetworkFailureCopyWith<$Res> {
  __$NetworkFailureCopyWithImpl(this._self, this._then);

  final _NetworkFailure _self;
  final $Res Function(_NetworkFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(_NetworkFailure(
freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _DatabaseFailure implements AppFailure {
  const _DatabaseFailure([this.message]);
  

@override final  String? message;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DatabaseFailureCopyWith<_DatabaseFailure> get copyWith => __$DatabaseFailureCopyWithImpl<_DatabaseFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DatabaseFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppFailure.database(message: $message)';
}


}

/// @nodoc
abstract mixin class _$DatabaseFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory _$DatabaseFailureCopyWith(_DatabaseFailure value, $Res Function(_DatabaseFailure) _then) = __$DatabaseFailureCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class __$DatabaseFailureCopyWithImpl<$Res>
    implements _$DatabaseFailureCopyWith<$Res> {
  __$DatabaseFailureCopyWithImpl(this._self, this._then);

  final _DatabaseFailure _self;
  final $Res Function(_DatabaseFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(_DatabaseFailure(
freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _SyncFailure implements AppFailure {
  const _SyncFailure([this.message]);
  

@override final  String? message;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncFailureCopyWith<_SyncFailure> get copyWith => __$SyncFailureCopyWithImpl<_SyncFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppFailure.sync(message: $message)';
}


}

/// @nodoc
abstract mixin class _$SyncFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory _$SyncFailureCopyWith(_SyncFailure value, $Res Function(_SyncFailure) _then) = __$SyncFailureCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class __$SyncFailureCopyWithImpl<$Res>
    implements _$SyncFailureCopyWith<$Res> {
  __$SyncFailureCopyWithImpl(this._self, this._then);

  final _SyncFailure _self;
  final $Res Function(_SyncFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(_SyncFailure(
freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _FileSystemFailure implements AppFailure {
  const _FileSystemFailure([this.message]);
  

@override final  String? message;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileSystemFailureCopyWith<_FileSystemFailure> get copyWith => __$FileSystemFailureCopyWithImpl<_FileSystemFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileSystemFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppFailure.fileSystem(message: $message)';
}


}

/// @nodoc
abstract mixin class _$FileSystemFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory _$FileSystemFailureCopyWith(_FileSystemFailure value, $Res Function(_FileSystemFailure) _then) = __$FileSystemFailureCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class __$FileSystemFailureCopyWithImpl<$Res>
    implements _$FileSystemFailureCopyWith<$Res> {
  __$FileSystemFailureCopyWithImpl(this._self, this._then);

  final _FileSystemFailure _self;
  final $Res Function(_FileSystemFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(_FileSystemFailure(
freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _UnexpectedFailure implements AppFailure {
  const _UnexpectedFailure([this.message]);
  

@override final  String? message;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnexpectedFailureCopyWith<_UnexpectedFailure> get copyWith => __$UnexpectedFailureCopyWithImpl<_UnexpectedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnexpectedFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppFailure.unexpected(message: $message)';
}


}

/// @nodoc
abstract mixin class _$UnexpectedFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory _$UnexpectedFailureCopyWith(_UnexpectedFailure value, $Res Function(_UnexpectedFailure) _then) = __$UnexpectedFailureCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class __$UnexpectedFailureCopyWithImpl<$Res>
    implements _$UnexpectedFailureCopyWith<$Res> {
  __$UnexpectedFailureCopyWithImpl(this._self, this._then);

  final _UnexpectedFailure _self;
  final $Res Function(_UnexpectedFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(_UnexpectedFailure(
freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
