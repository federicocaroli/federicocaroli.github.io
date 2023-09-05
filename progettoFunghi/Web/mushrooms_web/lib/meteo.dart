import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multiselect/multiselect.dart';
import 'server.dart';
import 'tab_bar.dart';

class MeteoPage extends StatefulWidget {
  final String username;
  final String token;
	
  const MeteoPage({
		required this.username,
    required this.token,
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

	@override
	void initState() {
		super.initState();
		startTimestamp = (DateTime.now().millisecondsSinceEpoch/1000).round();
		endTimestamp = (DateTime.now().millisecondsSinceEpoch/1000).round() + 86400;
		dateInput.text = 'Da ${DateFormat('dd/MM/yyyy').format(DateTime.now())} a ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'; //set the initial value of text field
    Server.getStationsInfo(widget.username, widget.token).then((result) {
      setState(() {
        availableStations = result.keys.toList();
      });
    }).catchError((err){
      print(err);
    });
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: Column(
				children: <Widget>[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
						      height: 70,
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
                          setState(() {
                            dateInput.text = formattedDate;
                            startTimestamp = (pickedPeriod.start.millisecondsSinceEpoch/1000).round();
                            endTimestamp = (pickedPeriod.end.millisecondsSinceEpoch/1000).round() + 86400;
                          });
                        } 
                      }
                    )
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  height: 70,
                  width: 500,
                  child: DropDownMultiSelect(
                      options: availableStations,
                      selectedValues: selectedStations,
                      onChanged: (list){
                        setState(() {
                          selectedStations = list;
                        });
                      },
                      whenEmpty: 'Seleziona le stazioni',
                    ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  height: 70,
                  width: 250,
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
                    ),
                    onPressed: (){
                      if (selectedStations.isNotEmpty){
                        Server.getStationsData(widget.username, widget.token, startTimestamp, endTimestamp, selectedStations).then((result) {
                          setState(() {
                            stationsData = result;
                          });
                        }).catchError((err){
                          print(err);
                        });
                      }
                    },
                    child: const Text("Cerca", style: TextStyle(color: Colors.white, fontSize: 20))
                  )
                )
              ]
            ),
            Expanded(
              child: TabbarStations(stationsData: stationsData),
            )
				],
			),
		);
	}
}
