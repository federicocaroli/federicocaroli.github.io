import 'package:dio/dio.dart';
import 'dart:convert';

class Server {
  
  static final dio = Dio(
    BaseOptions(
      baseUrl: 'http://federicocaroli.hopto.org:8000',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    )
  );

	static Future<String> checkCredential(String username, String password) async {
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
        return response.data['token'];
      }

      return "";
    }
    on DioException catch(dioError){
      if (dioError.response != null){
        if (dioError.response!.statusCode == 403){
          return "";
        }
      }

      throw Exception('Problema sconosciuto. $dioError');
    } catch (e) {
      throw Exception('Problema sconosciuto. $e');
    }
  }

  static Future<Map<String, Map>> getStationsInfo(String username, String token) async {
    try{
      var response = await dio.post(
        '/get_stations',
        data: jsonEncode({}),
        options: Options(headers: {Headers.contentTypeHeader: 'application/json; charset=UTF-8', 'username': username, 'token': token}, responseType: ResponseType.json)
      ).timeout(const Duration(seconds: 5));

      Map<String, Map> stations = {};

      if (response.statusCode == 200) {
        for (final station in response.data.keys){
          stations[station] = {"latitude": response.data[station]["latitude"], "longitude": response.data[station]["longitude"], "altitude": response.data[station]["altitude"], "lastUpdate": response.data[station]["lastUpdate"]};
        }
        return stations;
      }
      else {
        throw Exception('Failed to load stations. Status code: ${response.statusCode}');
      }
    }
    catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getStationsData(String username, String token, int startTimestamp, int endTimestamp, List<String> selectedStations) async {
    try{
      var response = await dio.post(
        '/get_data_of_stations',
        data: jsonEncode({"stations": selectedStations, "startTimestamp": startTimestamp, "endTimestamp": endTimestamp}),
        options: Options(headers: {Headers.contentTypeHeader: 'application/json; charset=UTF-8', 'username': username, 'token': token}, responseType: ResponseType.json)
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return Map.castFrom(response.data);
      }
      else {
        throw Exception('Failed to load stations. Status code: ${response.statusCode}');
      }
    }
    catch (e) {
      rethrow;
    }
  }
}