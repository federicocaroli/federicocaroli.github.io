import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multiselect/multiselect.dart';
import 'server.dart';
import 'tab_bar.dart';

bool _isLargeScreen(BuildContext context) {
	return MediaQuery.of(context).size.width > 960.0;
}

class MeteoPage extends StatefulWidget {
  const MeteoPage({
    super.key
	});

	@override
	State<MeteoPage> createState() => _MeteoPagePageState();
}

class _MeteoPagePageState extends State<MeteoPage> {
	
	TextEditingController dateInput = TextEditingController();
	int startTimestamp = -1;
	int endTimestamp = -1;
  List<String> selectedStations = [];
  List<String> availableStations = [];
  Map<String, dynamic> stationsData = {};
  Widget body = Container();

	@override
	void initState() {
		super.initState();
		startTimestamp = (DateTime.now().millisecondsSinceEpoch/1000).round();
		endTimestamp = (DateTime.now().millisecondsSinceEpoch/1000).round() + 86400;
		dateInput.text = 'Da ${DateFormat('dd/MM/yyyy').format(DateTime.now())} a ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'; //set the initial value of text field
    
    Server.getStationsInfo().then<void>((result) {
      if (mounted){
        setState(() {
          availableStations = result.keys.toList();
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
        print(error);
        await showDialog(context: context, 
        builder: (BuildContext context){
          return AlertDialog(
            title: const Text('Attenzione'),
            content: const Text(
              'Errore sconosciuto durante il caricamento delle stazioni.'
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
      }
    });
	}

  @override
  void dispose(){
    dateInput.dispose();
    super.dispose();
  }

  Widget buildForLargeScreen(){
    if (stationsData.isEmpty){
      body = Container(
            padding: const EdgeInsets.fromLTRB(40, 80, 40, 80),
            width: MediaQuery.of(context).size.width*0.4,
            child: TextButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.fromLTRB(0, 20, 0, 20)),
                mouseCursor: MaterialStateMouseCursor.textable,
              ),
              onPressed: (){
                Server.getExcelFile()
                  .catchError((error) async {
                    print(error);
                    await showDialog(context: context, 
                    builder: (BuildContext context){
                      return AlertDialog(
                        title: const Text('Attenzione'),
                        content: const Text(
                          'Errore scoccuro durante il download del file.'
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
                  });
              },
              child: const Text("Scaricati dati ultimo mese", style: TextStyle(color: Colors.grey, fontSize: 15, decoration: TextDecoration.underline))
            )
          );
    }
    else {
      body = TabbarStations(stationsData: stationsData);
    }

    return Scaffold(
			body: Column(
				children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: Colors.black)),
              ),
              height: MediaQuery.of(context).size.height * 0.1,
              width: MediaQuery.of(context).size.width,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  width: 320,
						      child:
                    TextField(
                      controller: dateInput,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.calendar_today), //icon of text field
                        labelText: "Periodo" //label text of field
                      ),
                      readOnly: true,
                      //set it true, so that user will not able to edit text
                      onTap: () async {
                        DateTimeRange? pickedPeriod = await showDateRangePicker(
                          context: context,
                          locale: const Locale('it', 'IT'),
                          firstDate: DateTime(2023, 5, 1),
                          lastDate: DateTime.now(),
                          initialEntryMode: DatePickerEntryMode.calendarOnly,
                          builder: (context, child){
                            return Column(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(top: 50.0),
                                  child: SizedBox(
                                    height: 600,
                                    width: 700,
                                    child: child,
                                  ),
                                ),
                              ],
                            );
                          }
                        );

                        if (pickedPeriod != null && startTimestamp != (pickedPeriod.start.millisecondsSinceEpoch/1000).round() && endTimestamp != ((pickedPeriod.end.millisecondsSinceEpoch/1000).round() + 86400)) {
                          String formattedDate = 'Da ${DateFormat('dd/MM/yyyy').format(pickedPeriod.start)} a ${DateFormat('dd/MM/yyyy').format(pickedPeriod.end)}';
                          if (mounted){
                            setState(() {
                              dateInput.text = formattedDate;
                              startTimestamp = (pickedPeriod.start.millisecondsSinceEpoch/1000).round();
                              endTimestamp = (pickedPeriod.end.millisecondsSinceEpoch/1000).round() + 86400;
                            });
                          }
                        } 
                      }
                    )
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  width: 500,
                  child: DropDownMultiSelect(
                      options: availableStations,
                      selectedValues: selectedStations,
                      onChanged: (list){
                        if (mounted){
                          setState(() {
                            selectedStations = list;
                          });
                        }
                      },
                      whenEmpty: 'Seleziona le stazioni',
                    ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  width: 250,
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
                    ),
                    onPressed: (){
                      if (selectedStations.isNotEmpty){
                        Server.getStationsData(startTimestamp, endTimestamp, selectedStations).then((result) {
                          if (mounted){
                            setState(() {
                              stationsData = result;
                              body = TabbarStations(stationsData: stationsData);
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
                            print(error);
                            await showDialog(context: context, 
                            builder: (BuildContext context){
                              return AlertDialog(
                                title: const Text('Attenzione'),
                                content: const Text(
                                  'Errore scoccuro durante il caricamento dei dati.'
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
                          }
                        });
                      }
                    },
                    child: const Text("Cerca", style: TextStyle(color: Colors.white, fontSize: 20))
                  )
                )
                ]
              ),
            ),
            Expanded(
              child: body
            )
				],
			),
		);
  }

  Widget buildForMediumSmallScreen(){
    return Scaffold(
			body: Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
				children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width*0.8,
            margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
            child: const Text(
              "Periodo:",
              style: TextStyle(fontSize: 15)
            )
          ),
          Container(
            width: MediaQuery.of(context).size.width*0.8,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
            child:
              TextField(
                controller: dateInput,
                decoration: const InputDecoration(
                  icon: Icon(Icons.calendar_today), //icon of text field
                  labelText: "Periodo" //label text of field
                ),
                readOnly: true,
                //set it true, so that user will not able to edit text
                onTap: () async {
                  DateTimeRange? pickedPeriod = await showDateRangePicker(
                    context: context,
                    locale: const Locale('it', 'IT'),
                    firstDate: DateTime(2023, 5, 1),
                    lastDate: DateTime.now(),
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                    builder: (context, child){
                      return Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 50.0),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height*0.7,
                              width: MediaQuery.of(context).size.width*0.7,
                              child: child,
                            ),
                          ),
                        ],
                      );
                    }
                  );

                  if (pickedPeriod != null && startTimestamp != (pickedPeriod.start.millisecondsSinceEpoch/1000).round() && endTimestamp != ((pickedPeriod.end.millisecondsSinceEpoch/1000).round() + 86400)) {
                    String formattedDate = 'Da ${DateFormat('dd/MM/yyyy').format(pickedPeriod.start)} a ${DateFormat('dd/MM/yyyy').format(pickedPeriod.end)}';
                    if (mounted){
                      setState(() {
                        dateInput.text = formattedDate;
                        startTimestamp = (pickedPeriod.start.millisecondsSinceEpoch/1000).round();
                        endTimestamp = (pickedPeriod.end.millisecondsSinceEpoch/1000).round() + 86400;
                      });
                    }
                  } 
                }
              )
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            width: MediaQuery.of(context).size.width*0.8,
            child: const Text(
              "Stazioni:",
              style: TextStyle(fontSize: 15)
            )
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
            width: MediaQuery.of(context).size.width*0.8,
            child: DropDownMultiSelect(
                options: availableStations,
                selectedValues: selectedStations,
                onChanged: (list){
                  if (mounted){
                    setState(() {
                      selectedStations = list;
                    });
                  }
                },
                whenEmpty: 'Seleziona le stazioni',
              ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
            width: MediaQuery.of(context).size.width*0.8,
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
                padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.fromLTRB(0, 20, 0, 20))
              ),
              onPressed: (){
                if (selectedStations.isNotEmpty){
                  Server.getStationsData(startTimestamp, endTimestamp, selectedStations).then((result) {
                    stationsData = result;
                    if (mounted){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => DataViewer(stationsData: stationsData)));
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
                      print(error);
                      await showDialog(context: context, 
                      builder: (BuildContext context){
                        return AlertDialog(
                          title: const Text('Attenzione'),
                          content: const Text(
                            'Errore scoccuro durante il caricamento dei dati.'
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
                    }
                  });
                }
              },
              child: const Text("Cerca", style: TextStyle(color: Colors.white, fontSize: 20))
            )
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            width: MediaQuery.of(context).size.width*0.8,
            child: TextButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.fromLTRB(0, 20, 0, 20)),
                mouseCursor: MaterialStateMouseCursor.textable,
              ),
              onPressed: (){
                Server.getExcelFile()
                  .catchError((error) async {
                    print(error);
                    await showDialog(context: context, 
                    builder: (BuildContext context){
                      return AlertDialog(
                        title: const Text('Attenzione'),
                        content: const Text(
                          'Errore scoccuro durante il download del file.'
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
                  });
              },
              child: const Text("Scaricati dati ultimo mese", style: TextStyle(color: Colors.grey, fontSize: 15, decoration: TextDecoration.underline))
            )
          )
				],
			)
      )
		);
  }

	@override
	Widget build(BuildContext context) {
		if (_isLargeScreen(context)){
      return buildForLargeScreen();
    }
    return buildForMediumSmallScreen();
	}
}

class DataViewer extends StatefulWidget {
  
  final Map<String, dynamic> stationsData;

  const DataViewer({
    required this.stationsData,
    super.key
  });

  @override
	State<DataViewer> createState() => _DataViewerState();
}

class _DataViewerState extends State<DataViewer> {
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.lightGreen,
          leading: BackButton(onPressed: () => Navigator.of(context).pop())
        ),
        body: TabbarStations(stationsData: widget.stationsData)
      );
    }
}