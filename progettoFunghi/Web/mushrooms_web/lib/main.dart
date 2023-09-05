import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'home.dart';
import 'server.dart';

void main() {
	runApp(const Mushrooms());
}

class Mushrooms extends StatelessWidget {
	const Mushrooms({super.key});

	// This widget is the root of your application.
	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			localizationsDelegates: const [
				GlobalMaterialLocalizations.delegate,
				GlobalWidgetsLocalizations.delegate,
				GlobalCupertinoLocalizations.delegate,
			],
			supportedLocales: const [
				Locale('it', 'IT'), 
			],
			routes: {
				'/': (context) => const SignUpScreen(),
			},
			title: 'MushroomsWeb',
		);
	}
}

class SignUpScreen extends StatelessWidget {
	const SignUpScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return const Scaffold(
			backgroundColor: Colors.white,
			body: Center(
				child: SizedBox(
					width: 400,
					child: Card(
						elevation: 0,
						child: SignUpForm(),
					),
				),
			),
		);
	}
}

class SignUpForm extends StatefulWidget {
	const SignUpForm({super.key});

	@override
	State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
	final _usernameTextController = TextEditingController();
	final _passwordTextController = TextEditingController();
	String _error = "";

	void setError(String msg){
		setState(() {
			_error = msg;
		});
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Colors.white,
			body: Column(
				mainAxisSize: MainAxisSize.min,
				children: [
					Padding(
						padding: const EdgeInsets.fromLTRB(0,50,0,50),
						child: Center(
							child: Container(
									width: 500,
									height: 250,
									decoration: BoxDecoration(
										color: Colors.lightGreen,
										borderRadius: BorderRadius.circular(40.0)
									),
									child: Image.asset('assets/images/logo.jpeg', scale: 0.5)),
						),
					),
					Padding(
						padding: const EdgeInsets.all(8),
						child: TextField(
							controller: _usernameTextController,
							decoration: const InputDecoration(hintText: 'Username'),
						),
					),
					Padding(
						padding: const EdgeInsets.all(8),
						child: TextField(
							obscureText: true,
							controller: _passwordTextController,
							decoration: const InputDecoration(hintText: 'Password'),
						),
					),
					Padding(
						padding: const EdgeInsets.only(top: 10),
						child: Container(
							height: 50,
							width: 250,
							decoration: BoxDecoration(
									color: Colors.lightGreen, borderRadius: BorderRadius.circular(20)),
							child: TextButton(
								onPressed: () async {
                  try {
                    String token = await Server.checkCredential(_usernameTextController.text, _passwordTextController.text);
                    if (token != ""){
                      setError("");
                      if(mounted){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage(username: _usernameTextController.text, token: token)));
                      }
                    }
                    else{
  										setError("Credenziali errate");
                    }
                  }
                  catch(err){
                    setError("Errore sconosciuto. $err");
                  }
								},
								child: const Text(
									'Login',
									style: TextStyle(color: Colors.white, fontSize: 25),
								),
							),
						)
					),
					Align(
						alignment: Alignment.centerRight,
						child:Padding(
							padding: const EdgeInsets.only(top: 15),
							child: Text(_error, style: const TextStyle(color: Colors.red))
						)
					)
				]
			),
		);
	}
}



