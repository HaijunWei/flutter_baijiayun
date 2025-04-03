import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class BaijiayunApiPlatform extends PlatformInterface {
  BaijiayunApiPlatform() : super(token: _token);

  static final Object _token = Object();

  static BaijiayunApiPlatform? _instance;

  static BaijiayunApiPlatform? get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BaijiayunApiPlatform] when
  /// they register themselves.
  static set instance(BaijiayunApiPlatform? instance) {
    if (instance == null) {
      throw AssertionError('Platform interfaces can only be set to a non-null instance');
    }

    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initialize() {
    throw UnimplementedError('initialize has not been implemented.');
  }

  Future<void> setPrivateDomainPrefix(String prefix) {
    throw UnimplementedError('setPrivateDomainPrefix has not been implemented.');
  }
}
