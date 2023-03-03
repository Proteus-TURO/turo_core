library turo_core;

import 'package:roslibdart/roslibdart.dart';
import 'package:turo_core/exceptions/data_type_exception.dart';

class RosBridge {
  late Ros _ros;
  late Topic _serialLed;
  late Topic _serialDrive;

  RosBridge(String ipAddress, int port) {
    _ros = Ros(url: 'ws://$ipAddress:$port');
    _serialLed = Topic(ros: _ros, name: '/serial/led', type: 'std_msgs/UInt8');
    _serialDrive =
        Topic(ros: _ros, name: '/serial/drive', type: 'geometry_msgs/Twist');
    _ros.connect();
  }

  Future<void> setBrightness(int brightness) async {
    if (brightness < 0 || brightness > 255) {
      throw DataTypeException("Brightness value must be between 0 and 255");
    }
    Map<String, dynamic> json = {'data': brightness};
    await _serialLed.publish(json);
  }

  Future<void> setVelocity(double x, double y, double z) async {
    Map<String, dynamic> linear = {'x': x, 'y': y, 'z': 0.0};
    Map<String, dynamic> angular = {'x': 0.0, 'y': 0.0, 'z': z};
    Map<String, dynamic> twist = {'linear': linear, 'angular': angular};
    await _serialDrive.publish(twist);
  }
}
