library turo_core;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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

class UDP {
  late InternetAddress ip;
  late int port;

  UDP(this.ip, this.port);

  Future<void> sendUDPBroadcast(String message, int port) async {
    final broadcast = InternetAddress('255.255.255.255');
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    final messageBytes = utf8.encode(message);

    socket.listen((event) {
      if (event == RawSocketEvent.write) {
        if (kDebugMode) {
          print('Broadcast message sent successfully');
        }
      }
    });

    socket.send(messageBytes, broadcast, port);
    await Future.delayed(const Duration(milliseconds: 100));
    socket.close();
  }
}
