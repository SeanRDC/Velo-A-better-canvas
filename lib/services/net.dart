// The app's HTTP calls. They go to the network as usual, except in demo mode, where the demo
// client answers them from mock data.
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'demo_mode.dart';

Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
    DemoMode.client?.get(url, headers: headers) ?? http.get(url, headers: headers);

Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    DemoMode.client?.post(url, headers: headers, body: body, encoding: encoding) ??
    http.post(url, headers: headers, body: body, encoding: encoding);

Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    DemoMode.client?.put(url, headers: headers, body: body, encoding: encoding) ??
    http.put(url, headers: headers, body: body, encoding: encoding);

Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    DemoMode.client?.delete(url, headers: headers, body: body, encoding: encoding) ??
    http.delete(url, headers: headers, body: body, encoding: encoding);

Future<http.StreamedResponse> send(http.BaseRequest request) => DemoMode.client?.send(request) ?? request.send();
