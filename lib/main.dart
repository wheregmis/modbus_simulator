import 'package:flutter/material.dart';
import 'package:modbus_simulator/src/rust/api/simple.dart';
import 'package:modbus_simulator/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          body: Column(
        children: <Widget>[
          const HeaderComponent(),
          Row(
            children: <Widget>[
              const Text(
                'Protocol: TCP',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'IP Address',
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Port',
                    ),
                  ),
                ),
              ),
              IconButton(onPressed: () {}, icon: Icon(Icons.play_arrow)),
              IconButton(onPressed: () {}, icon: Icon(Icons.stop))
            ],
          )
        ],
      )),
    );
  }
}

class HeaderComponent extends StatelessWidget {
  const HeaderComponent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Modbus Simulator',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(width: 10),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(
            Icons.settings_display,
            size: 30,
          ),
        ),
      ],
    );
  }
}
