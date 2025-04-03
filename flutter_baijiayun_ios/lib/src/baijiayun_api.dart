import 'package:flutter_baijiayun_platform_interface/flutter_baijiayun_platform_interface.dart';

import 'baijiayun.g.dart';

class BaijiayunApiIOSPlatform extends BaijiayunApiPlatform {
  static final _api = BaijiayunApi();

  @override
  Future<void> initialize() {
    return Future.value();
  }

  @override
  Future<void> setPrivateDomainPrefix(String prefix) {
    return _api.setPrivateDomainPrefix(prefix);
  }
}
