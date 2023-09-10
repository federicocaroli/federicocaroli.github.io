import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:universal_html/html.dart';

class AuthenticationException implements Exception {
  AuthenticationException();
}

class Server {
  
  static final dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.177:8001',
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