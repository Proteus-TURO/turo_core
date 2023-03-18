library turo_core;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:http/http.dart' as http;
import 'package:roslibdart/roslibdart.dart';
import 'package:turo_core/exceptions/data_type_exception.dart';

class RosBridge {
  late Ros _ros;
  late Topic _serialLed;
  late Topic _serialDrive;
  late Topic _serialLightAssistant;

  RosBridge(String ipAddress, int port) {
    _ros = Ros(url: 'ws://$ipAddress:$port');
    _serialLed = Topic(ros: _ros, name: '/serial/led', type: 'std_msgs/UInt8');
    _serialDrive =
        Topic(ros: _ros, name: '/serial/drive', type: 'geometry_msgs/Twist');
    _serialLightAssistant =
        Topic(ros: _ros, name: "/serial/led/threshold", type: "std_msgs/UInt8");
    _ros.connect();
  }

  Future<void> setBrightness(int brightness) async {
    if (brightness < 0 || brightness > 255) {
      throw DataTypeException("Brightness value must be between 0 and 255");
    }
    Map<String, dynamic> json = {'data': brightness};
    await _serialLed.publish(json);
  }

  Future<void> setAutomaticLight(int threshold) async {
    if (threshold < 0 || threshold > 255) {
      throw DataTypeException("Brightness value must be between 0 and 255");
    }
    await _serialLightAssistant.publish(threshold);
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

  Future<void> sendUDPBroadcast(String message) async {
    final broadcast = ip;
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    socket.broadcastEnabled = true;
    final messageBytes = utf8.encode(message);

    socket.listen((event) {
      Datagram? dg = socket.receive();
      if (dg != null) {
        if (kDebugMode) {
          print("received ${dg.data}");
        }
      }

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

  Future<void> listen() async {
    RawDatagramSocket socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);

    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram != null) {
          final message = String.fromCharCodes(datagram.data);
          if (kDebugMode) {
            print('Received UDP broadcast message: $message');
          }
        }
      }
    });
  }
}

class WIFI {
  Future<void> sendCredentials(String ssid, String password) async {
    final response = await http.post(
        Uri.parse('http://localhost:6000/api/wifi'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'ssid': ssid, 'password': password}));

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print("So toll");
      }
    } else {
      if (kDebugMode) {
        print("Fehler mehler");
      }
    }
  }
}

class VideoStream extends HookWidget {
  ValueNotifier<bool>? _isRunning;
  late String _stream;
  late double _height;
  late double _width;
  late BoxFit _boxFit;
  double? _compression;
  double? _scale;

  VideoStream(String ip, int port, String urlPath, String topic,
      {double? height,
      double? width,
      BoxFit boxFit = BoxFit.contain,
      double? scale,
      double? compression,
      super.key}) {
    _stream = 'http://$ip:$port/$urlPath?topic=$topic';

    height ??= double.maxFinite;
    width ??= double.maxFinite;

    _height = height;
    _width = width;
    _boxFit = boxFit;
    _compression = compression;
    _scale = scale;
  }

  void reload() {
    if (_isRunning != null) {
      _isRunning!.value = !_isRunning!.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    _isRunning = useState(true);
    var widget = Mjpeg(
        width: _width,
        height: _height,
        fit: _boxFit,
        isLive: _isRunning!.value,
        error: (context, error, stack) {
          return Center(
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Oops, something went wrong!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ));
        },
        stream: _stream,
        // Jo nt const mochn, weil donn donoch compression und scale nt hinzugefügt werden kenn
        headers: {
          'ApiKey':
              '9zY9ylYgnCa5j2L2tjV1W0B5qL5ZOEnNIcwdbIFrsqAJdYsZPzBgWdKH7nigecgX'
        });

    if (_compression != null) {
      widget.headers.putIfAbsent('Compression', () => _compression.toString());
    }

    if (_scale != null) {
      widget.headers.putIfAbsent('Scale', () => _scale.toString());
    }

    return widget;
  }
}

class HeloTuroData {
  late String name = "Turo 1";
  late int bridgePort = 8080;
  late int videStreamPort = 5000;
  late String ip;

  HeloTuroData(String jsonString, String ip) {
    Map<String, dynamic> decodedJson = jsonDecode(jsonString);
    if (decodedJson.containsKey('name')) {
      this.name = decodedJson['name'];
    }
    if (decodedJson.containsKey('bridge')) {
      this.bridgePort = decodedJson['bridge'];
    }
    if (decodedJson.containsKey('video_stream')) {
      this.videStreamPort = decodedJson['video_stream'];
    }

    this.ip = ip;
  }
}

class HeloTuroReceiver extends StatefulWidget {
  late Function onChildTab;
  HeloTuroReceiver(Function onChildTab, {super.key}) {
    this.onChildTab = onChildTab;
  }

  @override
  State<HeloTuroReceiver> createState() => _HeloTuroReceiverState();
}

class _HeloTuroReceiverState extends State<HeloTuroReceiver> {
  List<HeloTuroData> cars = [];

  @override
  void initState() {
    super.initState();
    _bindUDPSocket();
  }

  void _bindUDPSocket() async {
    RawDatagramSocket udpSocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 6274);
    udpSocket.listen((RawSocketEvent event) {
      Datagram? datagram = udpSocket.receive();
      if (datagram != null) {
        var jsonString = utf8.decode(datagram.data);
        var ip = datagram.address.address;
        var heloTuroData = HeloTuroData(jsonString, ip);
        var existingIndex = cars.indexWhere((element) => element.ip == ip);

        if (existingIndex != -1) {
          return;
        }

        setState(() {
          cars.add(heloTuroData);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const ScrollPhysics(),
      itemCount: cars.length + 1,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        if (index == cars.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final car = cars[index];
        return ListTile(
            leading: Icon(Icons.directions_car),
            title: Text(car.name),
            subtitle: Text('IP: ${car.ip}'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => widget.onChildTab(car));
      },
    );
  }
}
