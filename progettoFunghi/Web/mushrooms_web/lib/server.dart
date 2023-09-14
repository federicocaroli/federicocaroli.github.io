import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:universal_html/html.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:permission_handler/permission_handler.dart';

class AuthenticationException implements Exception {
  AuthenticationException();
}

class Server {
  
  static final dio = Dio(
    BaseOptions(
      baseUrl: 'https://federicocaroli.hopto.org/server',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    )
  );

	static Future<bool> checkCredential(String username, String password) async {
    try{
      Response response = await dio.post(
        '/login',
        data: {
          'username': username,
          'password': password
        },
        options: Options(headers: {Headers.contentTypeHeader: 'application/json; charset=UTF-8'}, responseType: ResponseType.json)
      );
    
      if (response.statusCode == 200) {
        WebStorage.instance.username = username;
        WebStorage.instance.token = response.data['token'];

        return true;
      }
      else {
        throw Exception('Failed to login. Status code: ${response.statusCode}');
      }
    }
    on DioException catch(dioError){
      if (dioError.response != null){
        if (dioError.response!.statusCode == 403){
          signOut();
          throw AuthenticationException();
        }
      }

      throw Exception('Problema sconosciuto. $dioError');
    } catch (e) {
      throw Exception('Problema sconosciuto. $e');
    }
  }

  static Future<Map<String, Map>> getStationsInfo() async {
    try{
      await renewCookie();
    }
    catch (e){
      rethrow;
    }

    try{
      var response = await dio.post(
        '/get_stations',
        data: jsonEncode({}),
        options: Options(headers: {Headers.contentTypeHeader: 'application/json; charset=UTF-8', 'username': WebStorage.instance.username, 'token': WebStorage.instance.token}, responseType: ResponseType.json)
      );

      Map<String, Map> stations = {};

      if (response.statusCode == 200) {
        for (final station in response.data.keys){
          stations[station] = {"latitude": response.data[station]["latitude"], "longitude": response.data[station]["longitude"], "altitude": response.data[station]["altitude"], "lastUpdate": response.data[station]["lastUpdate"], "sensors": response.data[station]["sensors"]};
        }

        return stations;
      }
      else {
        throw Exception('Failed to load stations. Status code: ${response.statusCode}');
      }
    }
    on DioException catch(dioError){
      if (dioError.response != null){
        if (dioError.response!.statusCode == 403){
          signOut();
          throw AuthenticationException();
        }
      }

      throw Exception('Problema sconosciuto. $dioError');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getStationsData(int startTimestamp, int endTimestamp, List<String> selectedStations) async {
    try{
      await renewCookie();
    }
    catch (e){
      rethrow;
    }
    
    try{
      var response = await dio.post(
        '/get_data_of_stations',
        data: jsonEncode({"stations": selectedStations, "startTimestamp": startTimestamp, "endTimestamp": endTimestamp}),
        options: Options(headers: {Headers.contentTypeHeader: 'application/json; charset=UTF-8', 'username': WebStorage.instance.username, 'token': WebStorage.instance.token}, responseType: ResponseType.json)
      );

      if (response.statusCode == 200) {
        return Map.castFrom(response.data);
      }
      else {
        throw Exception('Failed to load stations. Status code: ${response.statusCode}');
      }
    }
    on DioException catch(dioError){
      if (dioError.response != null){
        if (dioError.response!.statusCode == 403){
          signOut();
          throw AuthenticationException();
        }
      }

      throw Exception('Problema sconosciuto. $dioError');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> getExcelFile() async {
    try{
      await renewCookie();
    }
    catch (e){
      rethrow;
    }
    
    try{
      if(kIsWeb){
        downloadWeb(url: 'https://federicocaroli.hopto.org/server/mushroomsDataExport.xlsx');
      }
      else{
        downloadMobile(url: 'https://federicocaroli.hopto.org/server/mushroomsDataExport.xlsx');
      }
    }
    on DioException catch(dioError){
      throw Exception('Problema sconosciuto. $dioError');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> downloadWeb({required String url}) async {
    html.window.open(url, "_blank");
  }

  static Future<bool> renewCookie() async {
    try {
      if(WebStorage.instance.token == "" || WebStorage.instance.username == ""){
        signOut();
        throw AuthenticationException();
      }

      var response = await dio.post(
        '/renew',
        data: jsonEncode({"username": WebStorage.instance.username, "token": WebStorage.instance.token}),
        options: Options(headers: {Headers.contentTypeHeader: 'application/json; charset=UTF-8'}, responseType: ResponseType.json)
      );

      if (response.statusCode == 200) {
        var payload = Map.castFrom(response.data);
        if ((payload["token"] ?? "") != "") {
          WebStorage.instance.token = payload["token"]!;
          return true;
        }
        else {
          signOut();
          throw AuthenticationException();
        }
      }
      else {
        throw Exception('Failed to check cookies. Status code: ${response.statusCode}');
      }
    }
    on DioException catch(dioError){
      if (dioError.response != null){
        if (dioError.response!.statusCode == 403){
          signOut();
          throw AuthenticationException();
        }
      }

      throw Exception('Problema sconosciuto. $dioError');
    }
    catch (e) {
      rethrow;
    }
  }

  static Future<void> downloadMobile({required String url}) async {
    // requests permission for downloading the file
    bool hasPermission = await _requestWritePermission();
    if (!hasPermission) return;

    // gets the directory where we will download the file.
    var dir = await getApplicationDocumentsDirectory();

    // You should put the name you want for the file here.
    // Take in account the extension.
    String fileName = 'mushroomsDataExport.xlsx';
    
    // downloads the file
    await dio.download(url, "${dir.path}/$fileName");
  }

  // requests storage permission
  static Future<bool> _requestWritePermission() async {
    await Permission.storage.request();
    return await Permission.storage.request().isGranted;
  }

  static void signOut(){
    WebStorage.instance.clear();
  }
}

class WebStorage {

  //Singleton
  WebStorage._internal();
  static final WebStorage instance = WebStorage._internal();
  factory WebStorage() {
    return instance;
  }

  void clear(){
    window.localStorage.clear();
  }

  String get token => window.localStorage['Token'] == null ? "" : window.localStorage['Token']!;
  set token(String token) => window.localStorage['Token'] = token;

  String get username => window.localStorage['Username'] == null ? "" : window.localStorage['Username']!;
  set username(String username) => window.localStorage['Username'] = username;
}