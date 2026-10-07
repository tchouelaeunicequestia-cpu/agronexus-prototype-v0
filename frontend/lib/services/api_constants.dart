import 'package:flutter/foundation.dart' show kIsWeb;

import 'runtime_platform.dart' show isAndroid;

String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:8080';
  } else if (isAndroid) {
    return 'http://192.168.1.133:8080'; // Updated to your PC's local network IP
  } else {
    return 'http://localhost:8080';
  }
}
