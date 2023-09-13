// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

bool _isLargeScreen(BuildContext context) {
	return MediaQuery.of(context).size.width > 960.0;
}

bool _isMediumScreen(BuildContext context) {
	return MediaQuery.of(context).size.width > 640.0;
}

/// See bottomNavigationBarItem or NavigationRailDestination
class AdaptiveScaffoldDestination {
	final String title;
	final IconData icon;

	const AdaptiveScaffoldDestination({
		required this.title,
		required this.icon,
	});
}

/// A widget that adapts to the current display size, displaying a [Drawer],
/// [NavigationRail], or [BottomNavigationBar]. Navigation destinations are
/// defined in the [destinations] parameter.
class AdaptiveScaffold extends StatefulWidget {
	final Widget? title;
	final List<Widget> actions;
	final Widget? body;
	final int currentIndex;
	final List<AdaptiveScaffoldDestination> destinations;
	final ValueChanged<int>? onNavigationIndexChange;
	final FloatingActionButton? floatingActionButton;

	const AdaptiveScaffold({
		this.title,
		this.body,
		this.actions = const [],
		required this.currentIndex,
		required this.destinations,
		this.onNavigationIndexChange,
		this.floatingActionButton,
		super.key,
	});

	@override
	State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
	@override
	Widget build(BuildContext context) {
		// Show a Drawer
		if (_isLargeScreen(context)) {
			return Row(
				children: [
					Drawer(
						child: ListView(
							padding: EdgeInsets.zero,
							children: [
								SizedBox(
									height: 250,
									child: DrawerHeader(
										child: Center(
											child: widget.title,
										),
									),
								),
								for (var d in widget.destinations)
									ListTile(
										iconColor: Colors.lightGreen,
										textColor: Colors.lightGreen,
										leading: Icon(d.icon, color: Colors.black,),
										title: Text(d.title, style: const TextStyle(color: Colors.black)),
										selected:
												widget.destinations.indexOf(d) == widget.currentIndex,
										onTap: () => _destinationTapped(d),
									),
							],
						),
					),
					VerticalDivider(
						width: 1,
						thickness: 1,
						color: Colors.grey[300],
					),
					Expanded(
						child: Scaffold(
							appBar: AppBar(
								backgroundColor: Colors.lightGreen,
								actions: widget.actions,
							),
							body: widget.body,
							floatingActionButton: widget.floatingActionButton,
						),
					),
				],
			);
		}

		// Show a navigation rail
		if (_isMediumScreen(context)) {
			return Scaffold(
				appBar: AppBar(
				  title: const Text("MushroomsWeb", style: TextStyle(color: Colors.black)),
					actions: widget.actions,
          backgroundColor: Colors.lightGreen,
				),
				body: Row(
					children: [
						NavigationRail(
							leading: widget.floatingActionButton,
							destinations: [
								...widget.destinations.map(
									(d) => NavigationRailDestination(
										icon: Icon(d.icon, color: Colors.black,),
										label: Text(d.title, style: const TextStyle(color: Colors.black)),
									),
								),
							],
							selectedIndex: widget.currentIndex,
							onDestinationSelected: widget.onNavigationIndexChange ?? (_) {},
						),
						VerticalDivider(
							width: 1,
							thickness: 1,
							color: Colors.grey[300],
						),
						Expanded(
							child: widget.body!,
						),
					],
				),
			);
		}

		// Show a bottom app bar
		return Scaffold(
			body: widget.body,
			appBar: AppBar(
				title: const Text("MushroomsWeb", style: TextStyle(color: Colors.black)),
				actions: widget.actions,
        backgroundColor: Colors.lightGreen,
			),
			bottomNavigationBar: BottomNavigationBar(
				items: [
					...widget.destinations.map(
						(d) => BottomNavigationBarItem(
              backgroundColor: Colors.lightGreen,
							icon: Icon(d.icon, color: Colors.black,),
							label: d.title,
						),
					),
				],
				currentIndex: widget.currentIndex,
				onTap: widget.onNavigationIndexChange,
			),
			floatingActionButton: widget.floatingActionButton,
		);
	}

	void _destinationTapped(AdaptiveScaffoldDestination destination) {
		var idx = widget.destinations.indexOf(destination);
		if (idx != widget.currentIndex) {
			widget.onNavigationIndexChange!(idx);
		}
	}
}
