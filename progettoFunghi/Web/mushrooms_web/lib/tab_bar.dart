import 'package:flutter/material.dart';

class TabbarStations extends StatefulWidget {
  final Map<String, dynamic> stationsData;

  const TabbarStations({required this.stationsData, super.key});

  @override
  State<TabbarStations> createState() => _TabbarStationsState();
}

class _TabbarStationsState extends State<TabbarStations> {
  
  List<Widget> _listOfTabs() {
    List<Widget> tabs = [];
    for (var station in widget.stationsData.keys) {
      tabs.add(Tab(
        child: Container(
          width: 200,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.redAccent, width: 1)),
          child: Align(alignment: Alignment.center, child: Text(station)),
        ),
      ));
    }
    return tabs;
  }
  
  List<Widget> _listOfTabsView() {
    List<Widget> tabsView = [];

    for (final station in widget.stationsData.keys) {

      List<Widget> stationColumnWidgets = [];

      for (final date in widget.stationsData[station].keys){

        int numOfCategories = 0;

        stationColumnWidgets.add(
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Center(
              child: Text(date)
            )
          )
        );

        if (widget.stationsData[station][date].containsKey("error")){
          stationColumnWidgets.add(
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Center(
                child: Text(widget.stationsData[station][date]["error"])
              )
            )
          );
        }
        else if(widget.stationsData[station][date].containsKey("columns") == false || widget.stationsData[station][date].containsKey("rows") == false){
          stationColumnWidgets.add(
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: const Center(
                child: Text("Nessuna colonna o riga fornita")
              )
            )
          );
        }
        else {
          List<TableRow> dateRows = [];
          List<Widget> categoryRow = [];

          numOfCategories = widget.stationsData[station][date]["columns"].length;

          for (final category in widget.stationsData[station][date]["columns"]){
            categoryRow.add(TableCell(child: Center(child: Text(category))));
          }

          dateRows.add(
            TableRow(
              children: categoryRow
            )
          );

          for (var i = 0; i < widget.stationsData[station][date]["rows"].length; i++){
            List<Widget> dataRow = [];

            if (widget.stationsData[station][date]["rows"][0].length == numOfCategories){
              for (var j = 0; j < numOfCategories; j++){
                dataRow.add(TableCell(child: Center(child: Text(widget.stationsData[station][date]["rows"][i][j]))));
              }

              dateRows.add(
                TableRow(
                  children: dataRow
                )
              );
            }
          }

          stationColumnWidgets.add(
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Table(
                border: TableBorder.all(),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                defaultColumnWidth: const FlexColumnWidth(),
                children: dateRows
              )
            )
          );
        }

        stationColumnWidgets.add(
          Container(
            height: 20,
            width: 20,
          )
        );
      }

      tabsView.add(
        ListView(
          controller: ScrollController(),
          
          children: stationColumnWidgets
        )
      );

    }

    return tabsView;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
      length: widget.stationsData.keys.length,
      child: NestedScrollView(
        scrollDirection: Axis.vertical,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter( //headerSilverBuilder only accepts slivers
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
              child: SizedBox(
                  height: 60,
                  child:
                    TabBar(
                    unselectedLabelColor: Colors.redAccent,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.redAccent
                    ),
                    isScrollable: true,
                    tabs: _listOfTabs(),
                  )
              ),
            ),
          )
        ],
        body: TabBarView(
          children: _listOfTabsView(),
        )
      )
    )
  );
  }
}