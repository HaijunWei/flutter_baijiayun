// Autogenerated from Pigeon (v22.7.2), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, prefer_null_aware_operators, omit_local_variable_types, unused_shown_name, unnecessary_import, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer, immutable, protected;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;

PlatformException _createConnectionError(String channelName) {
  return PlatformException(
    code: 'channel-error',
    message: 'Unable to establish connection on channel: "$channelName".',
  );
}

List<Object?> wrapResponse({Object? result, PlatformException? error, bool empty = false}) {
  if (empty) {
    return <Object?>[];
  }
  if (error == null) {
    return <Object?>[result];
  }
  return <Object?>[error.code, error.message, error.details];
}
/// An immutable object that serves as the base class for all ProxyApis and
/// can provide functional copies of itself.
///
/// All implementers are expected to be [immutable] as defined by the annotation
/// and override [pigeon_copy] returning an instance of itself.
@immutable
abstract class PigeonInternalProxyApiBaseClass {
  /// Construct a [PigeonInternalProxyApiBaseClass].
  PigeonInternalProxyApiBaseClass({
    this.pigeon_binaryMessenger,
    PigeonInstanceManager? pigeon_instanceManager,
  }) : pigeon_instanceManager =
            pigeon_instanceManager ?? PigeonInstanceManager.instance;

  /// Sends and receives binary data across the Flutter platform barrier.
  ///
  /// If it is null, the default BinaryMessenger will be used, which routes to
  /// the host platform.
  @protected
  final BinaryMessenger? pigeon_binaryMessenger;

  /// Maintains instances stored to communicate with native language objects.
  final PigeonInstanceManager pigeon_instanceManager;

  /// Instantiates and returns a functionally identical object to oneself.
  ///
  /// Outside of tests, this method should only ever be called by
  /// [PigeonInstanceManager].
  ///
  /// Subclasses should always override their parent's implementation of this
  /// method.
  @protected
  PigeonInternalProxyApiBaseClass pigeon_copy();
}

/// Maintains instances used to communicate with the native objects they
/// represent.
///
/// Added instances are stored as weak references and their copies are stored
/// as strong references to maintain access to their variables and callback
/// methods. Both are stored with the same identifier.
///
/// When a weak referenced instance becomes inaccessible,
/// [onWeakReferenceRemoved] is called with its associated identifier.
///
/// If an instance is retrieved and has the possibility to be used,
/// (e.g. calling [getInstanceWithWeakReference]) a copy of the strong reference
/// is added as a weak reference with the same identifier. This prevents a
/// scenario where the weak referenced instance was released and then later
/// returned by the host platform.
class PigeonInstanceManager {
  /// Constructs a [PigeonInstanceManager].
  PigeonInstanceManager({required void Function(int) onWeakReferenceRemoved}) {
    this.onWeakReferenceRemoved = (int identifier) {
      _weakInstances.remove(identifier);
      onWeakReferenceRemoved(identifier);
    };
    _finalizer = Finalizer<int>(this.onWeakReferenceRemoved);
  }

  // Identifiers are locked to a specific range to avoid collisions with objects
  // created simultaneously by the host platform.
  // Host uses identifiers >= 2^16 and Dart is expected to use values n where,
  // 0 <= n < 2^16.
  static const int _maxDartCreatedIdentifier = 65536;

  /// The default [PigeonInstanceManager] used by ProxyApis.
  ///
  /// On creation, this manager makes a call to clear the native
  /// InstanceManager. This is to prevent identifier conflicts after a host
  /// restart.
  static final PigeonInstanceManager instance = _initInstance();

  // Expando is used because it doesn't prevent its keys from becoming
  // inaccessible. This allows the manager to efficiently retrieve an identifier
  // of an instance without holding a strong reference to that instance.
  //
  // It also doesn't use `==` to search for identifiers, which would lead to an
  // infinite loop when comparing an object to its copy. (i.e. which was caused
  // by calling instanceManager.getIdentifier() inside of `==` while this was a
  // HashMap).
  final Expando<int> _identifiers = Expando<int>();
  final Map<int, WeakReference<PigeonInternalProxyApiBaseClass>> _weakInstances =
      <int, WeakReference<PigeonInternalProxyApiBaseClass>>{};
  final Map<int, PigeonInternalProxyApiBaseClass> _strongInstances = <int, PigeonInternalProxyApiBaseClass>{};
  late final Finalizer<int> _finalizer;
  int _nextIdentifier = 0;

  /// Called when a weak referenced instance is removed by [removeWeakReference]
  /// or becomes inaccessible.
  late final void Function(int) onWeakReferenceRemoved;

  static PigeonInstanceManager _initInstance() {
    WidgetsFlutterBinding.ensureInitialized();
    final _PigeonInternalInstanceManagerApi api = _PigeonInternalInstanceManagerApi();
    // Clears the native `PigeonInstanceManager` on the initial use of the Dart one.
    api.clear();
    final PigeonInstanceManager instanceManager = PigeonInstanceManager(
      onWeakReferenceRemoved: (int identifier) {
        api.removeStrongReference(identifier);
      },
    );
    _PigeonInternalInstanceManagerApi.setUpMessageHandlers(instanceManager: instanceManager);
    VideoPlayer.pigeon_setUpMessageHandlers(pigeon_instanceManager: instanceManager);
    return instanceManager;
  }

  /// Adds a new instance that was instantiated by Dart.
  ///
  /// In other words, Dart wants to add a new instance that will represent
  /// an object that will be instantiated on the host platform.
  ///
  /// Throws assertion error if the instance has already been added.
  ///
  /// Returns the randomly generated id of the [instance] added.
  int addDartCreatedInstance(PigeonInternalProxyApiBaseClass instance) {
    final int identifier = _nextUniqueIdentifier();
    _addInstanceWithIdentifier(instance, identifier);
    return identifier;
  }

  /// Removes the instance, if present, and call [onWeakReferenceRemoved] with
  /// its identifier.
  ///
  /// Returns the identifier associated with the removed instance. Otherwise,
  /// `null` if the instance was not found in this manager.
  ///
  /// This does not remove the strong referenced instance associated with
  /// [instance]. This can be done with [remove].
  int? removeWeakReference(PigeonInternalProxyApiBaseClass instance) {
    final int? identifier = getIdentifier(instance);
    if (identifier == null) {
      return null;
    }

    _identifiers[instance] = null;
    _finalizer.detach(instance);
    onWeakReferenceRemoved(identifier);

    return identifier;
  }

  /// Removes [identifier] and its associated strongly referenced instance, if
  /// present, from the manager.
  ///
  /// Returns the strong referenced instance associated with [identifier] before
  /// it was removed. Returns `null` if [identifier] was not associated with
  /// any strong reference.
  ///
  /// This does not remove the weak referenced instance associated with
  /// [identifier]. This can be done with [removeWeakReference].
  T? remove<T extends PigeonInternalProxyApiBaseClass>(int identifier) {
    return _strongInstances.remove(identifier) as T?;
  }

  /// Retrieves the instance associated with identifier.
  ///
  /// The value returned is chosen from the following order:
  ///
  /// 1. A weakly referenced instance associated with identifier.
  /// 2. If the only instance associated with identifier is a strongly
  /// referenced instance, a copy of the instance is added as a weak reference
  /// with the same identifier. Returning the newly created copy.
  /// 3. If no instance is associated with identifier, returns null.
  ///
  /// This method also expects the host `InstanceManager` to have a strong
  /// reference to the instance the identifier is associated with.
  T? getInstanceWithWeakReference<T extends PigeonInternalProxyApiBaseClass>(int identifier) {
    final PigeonInternalProxyApiBaseClass? weakInstance = _weakInstances[identifier]?.target;

    if (weakInstance == null) {
      final PigeonInternalProxyApiBaseClass? strongInstance = _strongInstances[identifier];
      if (strongInstance != null) {
        final PigeonInternalProxyApiBaseClass copy = strongInstance.pigeon_copy();
        _identifiers[copy] = identifier;
        _weakInstances[identifier] = WeakReference<PigeonInternalProxyApiBaseClass>(copy);
        _finalizer.attach(copy, identifier, detach: copy);
        return copy as T;
      }
      return strongInstance as T?;
    }

    return weakInstance as T;
  }

  /// Retrieves the identifier associated with instance.
  int? getIdentifier(PigeonInternalProxyApiBaseClass instance) {
    return _identifiers[instance];
  }

  /// Adds a new instance that was instantiated by the host platform.
  ///
  /// In other words, the host platform wants to add a new instance that
  /// represents an object on the host platform. Stored with [identifier].
  ///
  /// Throws assertion error if the instance or its identifier has already been
  /// added.
  ///
  /// Returns unique identifier of the [instance] added.
  void addHostCreatedInstance(PigeonInternalProxyApiBaseClass instance, int identifier) {
    _addInstanceWithIdentifier(instance, identifier);
  }

  void _addInstanceWithIdentifier(PigeonInternalProxyApiBaseClass instance, int identifier) {
    assert(!containsIdentifier(identifier));
    assert(getIdentifier(instance) == null);
    assert(identifier >= 0);

    _identifiers[instance] = identifier;
    _weakInstances[identifier] = WeakReference<PigeonInternalProxyApiBaseClass>(instance);
    _finalizer.attach(instance, identifier, detach: instance);

    final PigeonInternalProxyApiBaseClass copy = instance.pigeon_copy();
    _identifiers[copy] = identifier;
    _strongInstances[identifier] = copy;
  }

  /// Whether this manager contains the given [identifier].
  bool containsIdentifier(int identifier) {
    return _weakInstances.containsKey(identifier) ||
        _strongInstances.containsKey(identifier);
  }

  int _nextUniqueIdentifier() {
    late int identifier;
    do {
      identifier = _nextIdentifier;
      _nextIdentifier = (_nextIdentifier + 1) % _maxDartCreatedIdentifier;
    } while (containsIdentifier(identifier));
    return identifier;
  }
}

/// Generated API for managing the Dart and native `PigeonInstanceManager`s.
class _PigeonInternalInstanceManagerApi {
  /// Constructor for [_PigeonInternalInstanceManagerApi].
  _PigeonInternalInstanceManagerApi({BinaryMessenger? binaryMessenger})
      : pigeonVar_binaryMessenger = binaryMessenger;

  final BinaryMessenger? pigeonVar_binaryMessenger;

  static const MessageCodec<Object?> pigeonChannelCodec = _PigeonCodec();

  static void setUpMessageHandlers({
    bool pigeon_clearHandlers = false,
    BinaryMessenger? binaryMessenger,
    PigeonInstanceManager? instanceManager,
  }) {
    {
      final BasicMessageChannel<
          Object?> pigeonVar_channel = BasicMessageChannel<
              Object?>(
          'dev.flutter.pigeon.flutter_baijiayun_ios.PigeonInternalInstanceManager.removeStrongReference',
          pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (pigeon_clearHandlers) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.flutter_baijiayun_ios.PigeonInternalInstanceManager.removeStrongReference was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_identifier = (args[0] as int?);
          assert(arg_identifier != null,
              'Argument for dev.flutter.pigeon.flutter_baijiayun_ios.PigeonInternalInstanceManager.removeStrongReference was null, expected non-null int.');
          try {
            (instanceManager ?? PigeonInstanceManager.instance)
                .remove(arg_identifier!);
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          } catch (e) {
            return wrapResponse(
                error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
  }

  Future<void> removeStrongReference(int identifier) async {
    const String pigeonVar_channelName =
        'dev.flutter.pigeon.flutter_baijiayun_ios.PigeonInternalInstanceManager.removeStrongReference';
    final BasicMessageChannel<Object?> pigeonVar_channel =
        BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(<Object?>[identifier]) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else {
      return;
    }
  }

  /// Clear the native `PigeonInstanceManager`.
  ///
  /// This is typically called after a hot restart.
  Future<void> clear() async {
    const String pigeonVar_channelName =
        'dev.flutter.pigeon.flutter_baijiayun_ios.PigeonInternalInstanceManager.clear';
    final BasicMessageChannel<Object?> pigeonVar_channel =
        BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(null) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else {
      return;
    }
  }
}

class _PigeonInternalProxyApiBaseCodec extends _PigeonCodec {
 const _PigeonInternalProxyApiBaseCodec(this.instanceManager);
 final PigeonInstanceManager instanceManager;
 @override
 void writeValue(WriteBuffer buffer, Object? value) {
   if (value is PigeonInternalProxyApiBaseClass) {
     buffer.putUint8(128);
     writeValue(buffer, instanceManager.getIdentifier(value));
   } else {
     super.writeValue(buffer, value);
   }
 }
 @override
 Object? readValueOfType(int type, ReadBuffer buffer) {
   switch (type) {
     case 128:
       return instanceManager
           .getInstanceWithWeakReference(readValue(buffer)! as int);
     default:
       return super.readValueOfType(type, buffer);
   }
 }
}


enum VideoPlayerType {
  avPlayer,
  ijkPlayer,
}


class _PigeonCodec extends StandardMessageCodec {
  const _PigeonCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is int) {
      buffer.putUint8(4);
      buffer.putInt64(value);
    }    else if (value is VideoPlayerType) {
      buffer.putUint8(129);
      writeValue(buffer, value.index);
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 129: 
        final int? value = readValue(buffer) as int?;
        return value == null ? null : VideoPlayerType.values[value];
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}
class VideoPlayer extends PigeonInternalProxyApiBaseClass {
  VideoPlayer({
    super.pigeon_binaryMessenger,
    super.pigeon_instanceManager,
    required VideoPlayerType type,
  }) {
    final int pigeonVar_instanceIdentifier =
        pigeon_instanceManager.addDartCreatedInstance(this);
    final _PigeonInternalProxyApiBaseCodec pigeonChannelCodec =
        _pigeonVar_codecVideoPlayer;
    final BinaryMessenger? pigeonVar_binaryMessenger = pigeon_binaryMessenger;
    () async {
      const String pigeonVar_channelName =
          'dev.flutter.pigeon.flutter_baijiayun_ios.VideoPlayer.pigeon_defaultConstructor';
      final BasicMessageChannel<Object?> pigeonVar_channel =
          BasicMessageChannel<Object?>(
        pigeonVar_channelName,
        pigeonChannelCodec,
        binaryMessenger: pigeonVar_binaryMessenger,
      );
      final List<Object?>? pigeonVar_replyList = await pigeonVar_channel
              .send(<Object?>[pigeonVar_instanceIdentifier, type])
          as List<Object?>?;
      if (pigeonVar_replyList == null) {
        throw _createConnectionError(pigeonVar_channelName);
      } else if (pigeonVar_replyList.length > 1) {
        throw PlatformException(
          code: pigeonVar_replyList[0]! as String,
          message: pigeonVar_replyList[1] as String?,
          details: pigeonVar_replyList[2],
        );
      } else {
        return;
      }
    }();
  }

  /// Constructs [VideoPlayer] without creating the associated native object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies for an [PigeonInstanceManager].
  @protected
  VideoPlayer.pigeon_detached({
    super.pigeon_binaryMessenger,
    super.pigeon_instanceManager,
  });

  late final _PigeonInternalProxyApiBaseCodec _pigeonVar_codecVideoPlayer =
      _PigeonInternalProxyApiBaseCodec(pigeon_instanceManager);

  static void pigeon_setUpMessageHandlers({
    bool pigeon_clearHandlers = false,
    BinaryMessenger? pigeon_binaryMessenger,
    PigeonInstanceManager? pigeon_instanceManager,
    VideoPlayer Function()? pigeon_newInstance,
  }) {
    final _PigeonInternalProxyApiBaseCodec pigeonChannelCodec =
        _PigeonInternalProxyApiBaseCodec(
            pigeon_instanceManager ?? PigeonInstanceManager.instance);
    final BinaryMessenger? binaryMessenger = pigeon_binaryMessenger;
    {
      final BasicMessageChannel<
          Object?> pigeonVar_channel = BasicMessageChannel<
              Object?>(
          'dev.flutter.pigeon.flutter_baijiayun_ios.VideoPlayer.pigeon_newInstance',
          pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (pigeon_clearHandlers) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.flutter_baijiayun_ios.VideoPlayer.pigeon_newInstance was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final int? arg_pigeon_instanceIdentifier = (args[0] as int?);
          assert(arg_pigeon_instanceIdentifier != null,
              'Argument for dev.flutter.pigeon.flutter_baijiayun_ios.VideoPlayer.pigeon_newInstance was null, expected non-null int.');
          try {
            (pigeon_instanceManager ?? PigeonInstanceManager.instance)
                .addHostCreatedInstance(
              pigeon_newInstance?.call() ??
                  VideoPlayer.pigeon_detached(
                    pigeon_binaryMessenger: pigeon_binaryMessenger,
                    pigeon_instanceManager: pigeon_instanceManager,
                  ),
              arg_pigeon_instanceIdentifier!,
            );
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          } catch (e) {
            return wrapResponse(
                error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
  }

  Future<void> initialize() async {
    final _PigeonInternalProxyApiBaseCodec pigeonChannelCodec =
        _pigeonVar_codecVideoPlayer;
    final BinaryMessenger? pigeonVar_binaryMessenger = pigeon_binaryMessenger;
    const String pigeonVar_channelName =
        'dev.flutter.pigeon.flutter_baijiayun_ios.VideoPlayer.initialize';
    final BasicMessageChannel<Object?> pigeonVar_channel =
        BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(<Object?>[this]) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setOnlineVideo(
    String id,
    String token,
  ) async {
    final _PigeonInternalProxyApiBaseCodec pigeonChannelCodec =
        _pigeonVar_codecVideoPlayer;
    final BinaryMessenger? pigeonVar_binaryMessenger = pigeon_binaryMessenger;
    const String pigeonVar_channelName =
        'dev.flutter.pigeon.flutter_baijiayun_ios.VideoPlayer.setOnlineVideo';
    final BasicMessageChannel<Object?> pigeonVar_channel =
        BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList = await pigeonVar_channel
        .send(<Object?>[this, id, token]) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> play() async {
    final _PigeonInternalProxyApiBaseCodec pigeonChannelCodec =
        _pigeonVar_codecVideoPlayer;
    final BinaryMessenger? pigeonVar_binaryMessenger = pigeon_binaryMessenger;
    const String pigeonVar_channelName =
        'dev.flutter.pigeon.flutter_baijiayun_ios.VideoPlayer.play';
    final BasicMessageChannel<Object?> pigeonVar_channel =
        BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(<Object?>[this]) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> pause() async {
    final _PigeonInternalProxyApiBaseCodec pigeonChannelCodec =
        _pigeonVar_codecVideoPlayer;
    final BinaryMessenger? pigeonVar_binaryMessenger = pigeon_binaryMessenger;
    const String pigeonVar_channelName =
        'dev.flutter.pigeon.flutter_baijiayun_ios.VideoPlayer.pause';
    final BasicMessageChannel<Object?> pigeonVar_channel =
        BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(<Object?>[this]) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> stop() async {
    final _PigeonInternalProxyApiBaseCodec pigeonChannelCodec =
        _pigeonVar_codecVideoPlayer;
    final BinaryMessenger? pigeonVar_binaryMessenger = pigeon_binaryMessenger;
    const String pigeonVar_channelName =
        'dev.flutter.pigeon.flutter_baijiayun_ios.VideoPlayer.stop';
    final BasicMessageChannel<Object?> pigeonVar_channel =
        BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(<Object?>[this]) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> seekTo(int position) async {
    final _PigeonInternalProxyApiBaseCodec pigeonChannelCodec =
        _pigeonVar_codecVideoPlayer;
    final BinaryMessenger? pigeonVar_binaryMessenger = pigeon_binaryMessenger;
    const String pigeonVar_channelName =
        'dev.flutter.pigeon.flutter_baijiayun_ios.VideoPlayer.seekTo';
    final BasicMessageChannel<Object?> pigeonVar_channel =
        BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList = await pigeonVar_channel
        .send(<Object?>[this, position]) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    final _PigeonInternalProxyApiBaseCodec pigeonChannelCodec =
        _pigeonVar_codecVideoPlayer;
    final BinaryMessenger? pigeonVar_binaryMessenger = pigeon_binaryMessenger;
    const String pigeonVar_channelName =
        'dev.flutter.pigeon.flutter_baijiayun_ios.VideoPlayer.setPlaybackSpeed';
    final BasicMessageChannel<Object?> pigeonVar_channel =
        BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(<Object?>[this, speed]) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> setBackgroundPlay(bool backgroundPlay) async {
    final _PigeonInternalProxyApiBaseCodec pigeonChannelCodec =
        _pigeonVar_codecVideoPlayer;
    final BinaryMessenger? pigeonVar_binaryMessenger = pigeon_binaryMessenger;
    const String pigeonVar_channelName =
        'dev.flutter.pigeon.flutter_baijiayun_ios.VideoPlayer.setBackgroundPlay';
    final BasicMessageChannel<Object?> pigeonVar_channel =
        BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList = await pigeonVar_channel
        .send(<Object?>[this, backgroundPlay]) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else {
      return;
    }
  }

  @override
  VideoPlayer pigeon_copy() {
    return VideoPlayer.pigeon_detached(
      pigeon_binaryMessenger: pigeon_binaryMessenger,
      pigeon_instanceManager: pigeon_instanceManager,
    );
  }
}

