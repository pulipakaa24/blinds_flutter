import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

String local = Platform.isAndroid ? '10.0.2.2' : 'localhost';
String fromDevice = '192.168.1.190';

String scheme = 'http';
String host = local;
int port = 3000;
String priv = "$scheme://$host:$port";

String pub = "https://wahwa.com";

String socketString = pub;

Future<http.Response?> secureGet(String path, {Map<String, dynamic>? queryParameters}) async{
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');
  if (token == null) return null;

  final uri = Uri.parse(socketString).replace(
    path: path,
    queryParameters: queryParameters?.map((key, value) => MapEntry(key, value.toString())),
  );

  var response = await http
    .get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    )
    .timeout(const Duration(seconds: 10));
  
  // Retry once if rate limited
  if (response.statusCode == 429) {
    await Future.delayed(const Duration(seconds: 1));
    response = await http
      .get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      )
      .timeout(const Duration(seconds: 10));
  }
  
  return response;
}

Future<http.Response?> securePost(Map<String, dynamic> payload, String path) async{
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');
  if (token == null) return null;

  final uri = Uri.parse(socketString).replace(
    path: path,
  );

  var response = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: json.encode(payload),
  )
  .timeout(const Duration(seconds: 10));
  
  // Retry once if rate limited
  if (response.statusCode == 429) {
    await Future.delayed(const Duration(seconds: 1));
    response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    )
    .timeout(const Duration(seconds: 10));
  }
  
  return response;
}

Future<http.Response?> secureDelete(String path) async{
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');
  if (token == null) return null;

  final uri = Uri.parse(socketString).replace(
    path: path,
  );

  var response = await http.delete(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  )
  .timeout(const Duration(seconds: 10));
  
  // Retry once if rate limited
  if (response.statusCode == 429) {
    await Future.delayed(const Duration(seconds: 1));
    response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    )
    .timeout(const Duration(seconds: 10));
  }
  
  return response;
}

Future<http.Response> regularGet(String path) async {
  final uri = Uri.parse(socketString).replace(
    path: path,
  );

  var response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
    }
  )
  .timeout(const Duration(seconds: 10));
  
  // Retry once if rate limited
  if (response.statusCode == 429) {
    await Future.delayed(const Duration(seconds: 1));
    response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
      }
    )
    .timeout(const Duration(seconds: 10));
  }
  
  return response;
}

Future<http.Response> regularPost(Map<String, dynamic> payload, String path) async{
  final uri = Uri.parse(socketString).replace(
    path: path,
  );

  var response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
    },
    body: json.encode(payload)
  ).timeout(const Duration(seconds: 10));
  
  // Retry once if rate limited
  if (response.statusCode == 429) {
    await Future.delayed(const Duration(seconds: 1));
    response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(payload)
    ).timeout(const Duration(seconds: 10));
  }
  
  return response;
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