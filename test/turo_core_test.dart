import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turo_core/turo_core.dart';

void main() {
  /*test('tries to set LED brightness', () {
    final rosBridge = RosBridge('localhost', 9090);
    rosBridge.setBrightness(255);
  });


   */
  test("sending UDP helo message", () {
    final udp = UDP(InternetAddress("255.255.255.255"), 6000);
    udp.listen();
  });

  /*test("send WIFI credentials as a http post msg", () async {
    final wifi = WIFI();
    await wifi.sendCredentials("Balls", "Cock");
  });
   */
}
