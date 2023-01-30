import 'package:flutter_test/flutter_test.dart';
import 'package:turo_core/turo_core.dart';

void main() {
  test('tries to set LED brightness', () {
    final rosBridge = RosBridge('localhost', 9090);
    rosBridge.setBrightness(255);
  });
}
