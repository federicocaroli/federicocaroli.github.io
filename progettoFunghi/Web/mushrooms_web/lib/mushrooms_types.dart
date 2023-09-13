import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'mushrooms.dart' as mushrooms;

bool _isLargeScreen(BuildContext context) {
	return MediaQuery.of(context).size.width > 960.0;
}

bool _isMediumScreen(BuildContext context) {
	return MediaQuery.of(context).size.width > 640.0;
}

class MushroomsTypesPage extends StatefulWidget {
  const MushroomsTypesPage({
    super.key
	});

	@override
	State<MushroomsTypesPage> createState() => _MushroomsTypesPageState();
}

class _MushroomsTypesPageState extends State<MushroomsTypesPage> {

  Map<String, int> activePagePerMushroom = {};

  List<Widget> indicators(imagesLength, currentIndex, size) {
    return List<Widget>.generate(imagesLength, (index) {
      return Container(
        margin: const EdgeInsets.all(3),
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: currentIndex == index ? Colors.black : Colors.black26,
            shape: BoxShape.circle),
      );
    });
}

  List<Widget> buildMushroom(BuildContext context, String name, String description, List<String> images){
    if (_isLargeScreen(context) == true){
      return [
          Container(
            height: 30,
            margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            child: Center(
              child: Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black))
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 0, 30, 0),
                    margin: const EdgeInsets.fromLTRB(30, 20, 0, 0),
                    child: Text(description.replaceAll('  ', ''), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
                  )
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: Column(
                    children: [
                      CarouselSlider.builder(
                        itemCount: images.length,
                        itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) => Container(
                              margin: const EdgeInsets.all(10),
                              child: Image.asset("assets/mushrooms/${images[itemIndex]}", fit: BoxFit.scaleDown),
                            ),
                        options: CarouselOptions(
                          height: 200, 
                          autoPlay: true, 
                          enlargeCenterPage: true, 
                          enableInfiniteScroll: false,
                          onPageChanged: (int page, CarouselPageChangedReason reason) {
                            if(mounted){
                              setState(() {
                                activePagePerMushroom[name] = page;
                              });
                            }
                          }
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: indicators(images.length, activePagePerMushroom[name]!, 10)
                      )
                    ],
                  )
                )
              ),
            ],
          )
        ];
    }
    else {
      return [
          Container(
            height: 30,
            margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            child: Center(
              child: Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black))
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 30, 0),
            margin: const EdgeInsets.fromLTRB(30, 20, 0, 0),
            child: Text(description.replaceAll('  ', ''), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black))
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
            child: Center(
              child: Column(
                children: [
                  CarouselSlider.builder(
                    itemCount: images.length,
                    itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) => Container(
                          margin: const EdgeInsets.all(10),
                          child: Image.asset("assets/mushrooms/${images[itemIndex]}", fit: BoxFit.scaleDown),
                        ),
                    options: CarouselOptions(
                      height: 200, 
                      autoPlay: true, 
                      enlargeCenterPage: true, 
                      enableInfiniteScroll: false,
                      onPageChanged: (int page, CarouselPageChangedReason reason) {
                        if(mounted){
                          setState(() {
                            activePagePerMushroom[name] = page;
                          });
                        }
                      }
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: indicators(images.length, activePagePerMushroom[name]!, 5)
                  )
                ],
              )
            ),
          )
        ];
    }
  }

  List<Widget> buildListOfMushrooms(BuildContext context){
    List<Widget> listOfMushrooms = [];
    for (var mushroom in mushrooms.listOfMushrooms){
      if(activePagePerMushroom.containsKey(mushroom['name']) == false){
        activePagePerMushroom[mushroom['name']] = 0;
      }
      listOfMushrooms.addAll(
        buildMushroom(context, mushroom['name'], mushroom['description'], mushroom['images'])
      );
    }
    return listOfMushrooms;
  }

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Colors.white,
			body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
            child: Center(
              child: Text("Funghi interessanti", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black))
            ),
          ),
          ...buildListOfMushrooms(context),
          const SizedBox(
            height: 100,
          )
        ]
      )
		);
	}
}