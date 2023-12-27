import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:modbus_simulator/src/rust/api/simple.dart';
import 'package:modbus_simulator/src/rust/api/modbus_server.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modbus_simulator/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ipTextEditingController = useTextEditingController();
    final portTextEditingController = useTextEditingController();

    final isModbusServerRunning = useState(false);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          body: Column(
        children: <Widget>[
          HeaderComponent(isModbusServerRunning: isModbusServerRunning),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              const Text(
                'Protocol: TCP',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: ipTextEditingController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'IP Address',
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: portTextEditingController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Port',
                    ),
                  ),
                ),
              ),
              IconButton(
                  onPressed: () async {
                    var socketAddress =
                        "${ipTextEditingController.text}:${portTextEditingController.text}";
                    var notify = await getNotify();
                    serverContext(socketAddr: socketAddress, notify: notify);
                    isModbusServerRunning.value = true;
                  },
                  icon: const Icon(Icons.play_arrow)),
              const SizedBox(width: 10),
              IconButton(
                  onPressed: () {
                    stopServer();
                    isModbusServerRunning.value = false;
                  },
                  icon: const Icon(Icons.stop))
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
    required this.isModbusServerRunning,
  });

  final ValueNotifier<bool> isModbusServerRunning;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text(
          'Modbus Simulator',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(
            Icons.circle,
            size: 30,
            color: isModbusServerRunning.value ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}
