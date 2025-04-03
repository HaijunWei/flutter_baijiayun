import 'package:flutter_baijiayun_platform_interface/flutter_baijiayun_platform_interface.dart';

class BaijiayunApi {
  static final BaijiayunApiPlatform _instance = BaijiayunApiPlatform.instance!;

  static Future<void> initialize() {
    return _instance.initialize();
  }

  static Future<void> setPrivateDomainPrefix(String prefix) {
    return _instance.setPrivateDomainPrefix(prefix);
  }
}
