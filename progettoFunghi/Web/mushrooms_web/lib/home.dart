// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import 'adaptive_scaffold.dart';
import 'meteo.dart';
import 'mapPage.dart';

class HomePage extends StatefulWidget {
	final String username;
  final String token;

	const HomePage({
		required this.username,
		required this.token,
		super.key,
	});

	@override
	State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
	int _pageIndex = 0;

	@override
	Widget build(BuildContext context) {
		return AdaptiveScaffold(
			title:  Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							Center(
								child: Image.asset('assets/images/logo.jpeg'),
							),
							const Padding(
								padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
								child: Text("MushroomsWeb", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.lightGreen))
							),
						]
					),
			actions: [
				Padding(
					padding: const EdgeInsets.all(8.0),
					child: TextButton(
						style: TextButton.styleFrom(foregroundColor: Colors.black, textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
						onPressed: () => _handleSignOut(),
						child: const Text('Sign Out'),
					),
				)
			],
			currentIndex: _pageIndex,
			destinations: const [
				AdaptiveScaffoldDestination(title: 'Home', icon: Icons.home),
        AdaptiveScaffoldDestination(title: 'Mappa', icon: Icons.map),
        AdaptiveScaffoldDestination(title: 'Prova2', icon: Icons.home),
			],
			body: _pageAtIndex(_pageIndex),
			onNavigationIndexChange: (newIndex) {
				setState(() {
					_pageIndex = newIndex;
				});
			},
		);
	}

	Future<void> _handleSignOut() async {
		var shouldSignOut = await (showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Sei sicuro di voler uscire?'),
				actions: [
					TextButton(
						child: const Text('No'),
						onPressed: () {
							Navigator.of(context).pop(false);
						},
					),
					TextButton(
						child: const Text('Sì'),
						onPressed: () {
							Navigator.of(context).pop(true);
						},
					),
				],
			),
		));

		if (shouldSignOut == null || !shouldSignOut) {
			return;
		}

		if (mounted) {
			Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
		}
	}

	Widget _pageAtIndex(int index) {
		if (index == 0) {
			return MeteoPage(username: widget.username, token: widget.token);
		}
    else if(index == 1){
      return MapPage(username: widget.username, token: widget.token);
    }
		else{
			return const Center(child: Text('Unknown Page'));
		}
	}
}
