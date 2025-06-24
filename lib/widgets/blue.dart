import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class BluetoothPage extends StatelessWidget {
  const BluetoothPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Lottie.asset('assets/Lottie/Bluetooth.json'),
      ],
    ));
  }
}



// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:intl/intl.dart';

// class LogsPage extends StatefulWidget {
//   @override
//   _LogsPageState createState() => _LogsPageState();
// }

// class _LogsPageState extends State<LogsPage> {
//   double? _dailyAverage;
//   final DatabaseReference _database = FirebaseDatabase.instance.ref();

//   @override
//   void initState() {
//     super.initState();
//     _calculateDailyAverage();
//     // Optionally, set up a timer to recalculate every day
//     Timer.periodic(Duration(days: 1), (Timer t) => _calculateDailyAverage());
//   }

//   Future<void> _calculateDailyAverage() async {
//     final now = DateTime.now();
//     final formattedDate = DateFormat('yyyy-MM-dd').format(now);

//     final snapshot = await _database.child('pms25_data/$formattedDate').get();

//     setState(() {
//       if (snapshot.exists) {
//         final data = snapshot.value as Map<dynamic, dynamic>;

//         // Convert timestamp-value pairs to a list of values with timestamps
//         List<MapEntry<DateTime, double>> readings = [];

//         data.forEach((key, value) {
//           // Assuming the key is a timestamp string
//           try {
//             final timestamp = DateTime.parse(key.toString());
//             final pmValue = double.tryParse(value.toString()) ?? 0.0;
//             readings.add(MapEntry(timestamp, pmValue));
//           } catch (e) {
//             print('Error parsing data: $e');
//           }
//         });

//         if (readings.isNotEmpty) {
//           // Sort readings by timestamp
//           readings.sort((a, b) => a.key.compareTo(b.key));

//           // Calculate time-weighted average
//           double weightedSum = 0;
//           Duration totalDuration = Duration.zero;

//           for (int i = 0; i < readings.length - 1; i++) {
//             final duration = readings[i + 1].key.difference(readings[i].key);
//             weightedSum += readings[i].value * duration.inMinutes;
//             totalDuration += duration;
//           }

//           if (totalDuration.inMinutes > 0) {
//             _dailyAverage = weightedSum / totalDuration.inMinutes;
//           } else {
//             // If only one reading exists, use that value
//             _dailyAverage = readings.first.value;
//           }
//         } else {
//           _dailyAverage = 0;
//         }
//       } else {
//         _dailyAverage = null;
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Daily PMS2.5 Average'),
//       ),
//       body: Center(
//         child: _dailyAverage == null
//             ? Text('Loading...')
//             : Text(
//                 'Daily Average: ${_dailyAverage?.toStringAsFixed(2)} ug/m³',
//                 style: TextStyle(fontSize: 20),
//               ),
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';

// void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Firebase Timestamp Example',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: BluetoothPage(),
//     );
//   }
// }

// class BluetoothPage extends StatefulWidget {
//   const BluetoothPage({super.key});

//   @override
//   // ignore: library_private_types_in_public_api
//   _BluetoothPageState createState() => _BluetoothPageState();
// }

// class _BluetoothPageState extends State<BluetoothPage> {
//   final DatabaseReference _dbRef = FirebaseDatabase.instance.reference().child('firsTestSystem').child('devices');
//   String _dustDensity = '';
//   String _timestamp = '';

//   @override
//   void initState() {
//     super.initState();
//     _fetchData();
//   }

//   void _fetchData() {
//     _dbRef.once().then((DataSnapshot snapshot) {
//       Map<dynamic, dynamic> data = snapshot.value;
//       setState(() {
//         _dustDensity = data['PMS_25'].toString();
//         int timestampMillis = data['timestamp'];
//         DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
//         _timestamp = dateTime.toLocal().toString();
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Firebase Timestamp Example'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Text(
//               'Dust Density: $_dustDensity ug/m3',
//               style: TextStyle(fontSize: 20),
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Timestamp: $_timestamp',
//               style: TextStyle(fontSize: 20),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _fetchData,
//         tooltip: 'Fetch Data',
//         child: Icon(Icons.refresh),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';

// class BluetoothPage extends StatefulWidget {
//   const BluetoothPage({super.key});

//   @override
//   State<BluetoothPage> createState() => _BluetoothPageState();
// }

// class _BluetoothPageState extends State<BluetoothPage> {
//   final DatabaseReference _dbRef =
//       FirebaseDatabase.instance.ref().child('firsTestSystem').child('devices');
//   String _dustDensity = '';
//   String _timestamp = '';

//   @override
//   void initState() {
//     super.initState();
//     _fetchData();
//   }

//   Future<void> _fetchData() async {
//     try {
//       DatabaseEvent event = await _dbRef.once();
//       if (event.snapshot.value != null) {
//         Map<dynamic, dynamic> data =
//             event.snapshot.value as Map<dynamic, dynamic>;
//         setState(() {
//           _dustDensity = data['PMS_25']?.toString() ?? 'N/A';
//           int? timestampMillis = data['timestamp'] as int?;
//           if (timestampMillis != null) {
//             DateTime dateTime =
//                 DateTime.fromMillisecondsSinceEpoch(timestampMillis);
//             _timestamp = dateTime.toLocal().toString();
//           } else {
//             _timestamp = 'No timestamp available';
//           }
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _dustDensity = 'Error';
//         _timestamp = 'Error fetching data';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Air Quality Reading',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Dust Density: $_dustDensity µg/m³',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'Last Updated:\n$_timestamp',
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.bodyLarge,
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: _fetchData,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Refresh Data'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';

// class BluetoothPage extends StatefulWidget {
//   @override
//   _BluetoothPageState createState() => _BluetoothPageState();
// }

// class _BluetoothPageState extends State<BluetoothPage> {
//   final DatabaseReference databaseReference =
//       FirebaseDatabase.instance.ref();
//   String _timestamp = '';

//   @override
//   void initState() {
//     super.initState();
//     _getTimestamp();
//   }

//   void _getTimestamp() {
//     databaseReference.child('path_to_timestamp').onValue.listen((event) {
//       final dataSnapshot = event.snapshot;
//       setState(() {
//         _timestamp = dataSnapshot.value.toString();
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Firebase Timestamp'),
//       ),
//       body: Center(
//         child: Text('Timestamp: $_timestamp'),
//       ),
//     );
//   }
// }
