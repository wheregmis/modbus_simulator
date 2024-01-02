import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:modbus_simulator/src/rust/api/simple.dart';
import 'package:modbus_simulator/src/rust/api/modbus_server.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modbus_simulator/src/rust/frb_generated.dart';

final dataRowListProvider =
    StateProvider<List<DataRow>>((ref) => List<DataRow>.generate(
        10,
        (index) => DataRow(cells: [
              DataCell(Text((index).toString())),
              DataCell(Text((0).toString())),
              DataCell(Text((0).toString())),
              DataCell(Text((0).toString())),
              DataCell(Text((0).toString())),
              DataCell(Text((0).toString())),
              DataCell(Text((0).toString())),
              DataCell(Text((0).toString())),
              DataCell(Text((0).toString())),
              DataCell(Text((0).toString())),
            ])));

Future<void> main() async {
  await RustLib.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulHookConsumerWidget {
  const MyApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final ipTextEditingController = useTextEditingController();
    final portTextEditingController = useTextEditingController();

    final isModbusServerRunning = useState(false);

    void updateCell(int cellIndex, String newValue) {
      final dataRows = ref.read(dataRowListProvider.notifier);

      // Calculate the row and column index
      int rowIndex = cellIndex ~/ 10; // Integer division to get the row index
      int columnIndex =
          cellIndex % 10; // Modulo operation to get the column index

      DataRow rowToUpdate = dataRows.state[rowIndex]; // Get the row to update

      // Create a new DataRow with the updated value
      DataRow updatedRow = DataRow(cells: [
        for (int i = 0; i < rowToUpdate.cells.length; i++)
          if (i == columnIndex)
            DataCell(Text(newValue)) // The new value for the cell
          else
            rowToUpdate.cells[i], // Keep the old value for other cells
      ]);

      // Replace the old row with the updated one
      dataRows.state = List<DataRow>.from(dataRows.state)
        ..[rowIndex] = updatedRow;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modbus Simulator',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
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
                    try {
                      var notify = await getNotify();
                      serverContext(socketAddr: socketAddress, notify: notify);
                      isModbusServerRunning.value = true;
                    } catch (e) {
                      print(e);
                    }
                    // Sleep for 5 seconds
                    await Future.delayed(const Duration(seconds: 3));
                    var inputRegisters = await getInputRegisters();
                    for (var i = 0; i < inputRegisters.length; i++) {
                      updateCell(inputRegisters[i].$1,
                          inputRegisters[i].$2.toString());
                    }

                    print(inputRegisters);
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
          ),
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: <Widget>[
                  ButtonsTabBar(
                    // Customize the appearance and behavior of the tab bar

                    borderWidth: 2,
                    borderColor: Colors.black,
                    radius: 10,
                    center: true,
                    elevation: 2,
                    contentPadding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Color.fromARGB(255, 5, 127, 28),
                          Color.fromARGB(255, 24, 189, 74),
                          Color.fromARGB(255, 100, 220, 150),
                        ],
                      ),
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    unselectedLabelStyle: const TextStyle(color: Colors.black),
                    labelStyle: const TextStyle(color: Colors.white),

                    // Add your tabs here
                    tabs: const [
                      Tab(
                        text: "Discrete Inputs",
                      ),
                      Tab(
                        text: "Coils",
                      ),
                      Tab(
                        text: "Input Registers",
                      ),
                      Tab(
                        text: "Holding Registers",
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(children: [
                      Column(
                        children: [
                          Expanded(
                            child: DataTable2(
                                bottomMargin: 10,
                                horizontalMargin: 50,
                                // dividerThickness: 1,

                                border: TableBorder.all(),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      '0',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      '1',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      '2',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      '3',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      '4',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      '5',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      '6',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      '7',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      '8',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      '9',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                ],
                                rows: ref.watch(dataRowListProvider)),
                          ),
                        ],
                      ),
                      Container(
                        color: Colors.blue,
                      ),
                      Container(
                        color: Colors.green,
                      ),
                      Container(
                        color: Colors.yellow,
                      ),
                    ]),
                  ),
                ],
              ),
            ),
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
