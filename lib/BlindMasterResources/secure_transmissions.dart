import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

String local = Platform.isAndroid ? '10.0.2.2' : 'localhost';
String fromDevice = '192.168.1.190';

String host = local;
int port = 3000;
String socketString = "$scheme://$host:$port";
String scheme = 'http';

Future<http.Response?> secureGet(String path, {Map<String, dynamic>? queryParameters}) async{
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');
  if (token == null) return null;

  final uri = Uri(
    scheme: scheme,
    host: host,
    port: port,      // your host
    path: path,               // your path
    queryParameters: queryParameters?.map((key, value) => MapEntry(key, value.toString())),
  );

  return await http
    .get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    )
    .timeout(const Duration(seconds: 10)); // 🚀 Timeout added
}

Future<http.Response?> securePost(Map<String, dynamic> payload, String path) async{
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');
  if (token == null) return null;

  final uri = Uri(
    scheme: scheme,
    host: host,
    port: port,      // your host
    path: path,               // your path
  );

  return await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: json.encode(payload),
  )
  .timeout(const Duration(seconds: 10)); // 🚀 Timeout added
}

Future<http.Response> regularGet(String path) async {
  final uri = Uri(
    scheme: scheme,
    host: host,
    port: port,      // your host
    path: path,               // your path
  );

  return await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
    }
  )
  .timeout(const Duration(seconds: 10)); // 🚀 Timeout added
}

Future<http.Response> regularPost(Map<String, dynamic> payload, String path) async{
  final uri = Uri(
    scheme: scheme,
    host: host,
    port: port,      // your host
    path: path,      // your path
  );

  return await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
    },
    body: json.encode(payload)
  ).timeout(const Duration(seconds: 10)); // 🚀 Timeout added
}

Future<IO.Socket?> connectSocket() async {
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');
  if (token == null) return null;

  final socket = IO.io(
    socketString,
    IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .disableAutoConnect().build(),
  );

  socket.connect();

  return socket;
}