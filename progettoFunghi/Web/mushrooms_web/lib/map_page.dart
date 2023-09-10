import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import 'server.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key
	});

	@override
	State<MapPage> createState() => _MapPagePageState();
}

class _MapPagePageState extends State<MapPage> {
	
  final List<Widget> _listViewChildren = [];
  late MapController _mapController;
  final List<Widget> _layers = [];
  double _latitude = 44.267946, _longitude = 10.503911, _zoom = 12;
  final double _maxZoom = 18, _minZoom = 1;
  Widget loadingWidget = const Center(child: CircularProgressIndicator());

	@override
	void initState() {
		super.initState();

    _mapController = MapController();

    _layers.add(
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.app',
      )
    );

    Server.getStationsInfo().then<void>((stations) {
      if(mounted){
        setState(() {
          for (final station in stations.keys){
            var lastUpdateDatetime = DateTime.fromMillisecondsSinceEpoch(int.parse(stations[station]!['lastUpdate']) * 1000);
            var lastUpdateString = DateFormat('dd/MM/yyyy HH:mm').format(lastUpdateDatetime);
            var sensorsString = "";

            for (final sensor in stations[station]!['sensors']) {
              sensorsString += "$sensor, ";
            }

            if (sensorsString.isNotEmpty){
              sensorsString = sensorsString.substring(0, sensorsString.length - 2);
            }
            else{
              sensorsString = "Nessun sensore disponibile";
            }

            _listViewChildren.add(
              Card(
                child: ListTile(
                  title: Text("$station. Altitudine: ${stations[station]!['altitude']} m. Ultimo aggiornamento: $lastUpdateString. Sensori: $sensorsString"),
                  onTap: (){
                    moveCenterOfMap(stations[station]!["latitude"], stations[station]!["longitude"]);
                    if (mounted){
                      setState(() {
                        _layers.clear();
                        _layers.add(
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          )
                        );
                        _layers.add(
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: LatLng(stations[station]!["latitude"], stations[station]!["longitude"]),
                                color: Colors.red.withOpacity(0.7),
                                borderColor: Colors.black,
                                borderStrokeWidth: 2,
                                radius: 300,
                                useRadiusInMeter: true,
                              ),
                            ],
                          ),
                        );
                      });
                    }
                  },
                ),
              ),
            );
          }

          loadingWidget = ListView(
            scrollDirection: Axis.vertical,
            children: [
              ..._listViewChildren
            ],
          );
        });
      }
    }).catchError((error) async {
      if (error is AuthenticationException){
        Server.signOut();
        await showDialog(context: context, 
        builder: (BuildContext context){
          return AlertDialog(
            title: const Text('Attenzione'),
            content: const Text(
              'Login scaduto. Effettuare nuovamente il login.'
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
        if(mounted){
          Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
        }
      }
      else{
        if (mounted){
          setState(() {
            loadingWidget = const Center(child: Text("Errore sconosciuto durante il caricamento delle stazioni."));
          });
        }
        print(error);
      }
    });
	}

  @override
  void dispose(){
    _mapController.dispose();
    super.dispose();
  }

  void moveCenterOfMap(double latitude, double longitude) {
    _latitude = latitude;
    _longitude = longitude;
     _mapController.move(LatLng(latitude, longitude), _zoom);
  }

  void zoomInMap() {
    if (_zoom < _maxZoom){
      _zoom += 1;
    }
    _mapController.move(LatLng(_latitude, _longitude), _zoom);
  }

  void zoomOutMap() {
    if (_zoom > _minZoom){
      _zoom -= 1;
    }
    _mapController.move(LatLng(_latitude, _longitude), _zoom);
  }

	@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: const LatLng(44.267946, 10.503911),
                  zoom: 12,
                  interactiveFlags: InteractiveFlag.all
                ),
                nonRotatedChildren: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 2.0, top: 2.0, right: 2.0),
                          child: FloatingActionButton(
                            heroTag: 'zoomInButton',
                            mini: true,
                            backgroundColor: Colors.grey.withOpacity(0.4),
                            onPressed: () {
                              zoomInMap();
                            },
                            child: const Icon(Icons.zoom_in, color: Colors.black)
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: FloatingActionButton(
                            heroTag: 'zoomOutButton',
                            mini: true,
                            backgroundColor: Colors.grey.withOpacity(0.4),
                            onPressed: () {
                              zoomOutMap();
                            },
                            child: const Icon(Icons.zoom_out, color: Colors.black)
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                children: _layers,
              )
            ),
            Expanded(
              child: loadingWidget
            )
          ]
        )
      )
    );
  }
}
