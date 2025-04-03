import 'package:flutter_baijiayun_platform_interface/flutter_baijiayun_platform_interface.dart';

import 'baijiayun.g.dart';

class BaijiayunApiAndroidPlatform extends BaijiayunApiPlatform {
  static final _api = BaijiayunApi();
  @override
  Future<void> initialize() {
    return _api.initialize();
  }

  @override
  Future<void> setPrivateDomainPrefix(String prefix) {
    return _api.setPrivateDomainPrefix(prefix);
  }
}
