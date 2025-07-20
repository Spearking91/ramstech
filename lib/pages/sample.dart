// pubspec.yaml dependencies needed:
// dependencies:
//   flutter:
//     sdk: flutter
//   flutter_blue_plus: ^1.12.13
//   permission_handler: ^10.4.3

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 WiFi Config',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ESP32ConfigPage(),
    );
  }
}

class ESP32ConfigPage extends StatefulWidget {
  const ESP32ConfigPage({super.key});

  @override
  State<ESP32ConfigPage> createState() => _ESP32ConfigPageState();
}

class _ESP32ConfigPageState extends State<ESP32ConfigPage> {
  bool isScanning = false;
  bool isConnecting = false;
  bool isConnected = false;
  String statusMessage = "";
  String esp32Response = "";
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? wifiCharacteristic;
  BluetoothCharacteristic? statusCharacteristic;
  List<BluetoothDevice> devicesList = [];
  List<ScanResult> scanResults = [];
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    ssidController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> scanForDevices() async {
    setState(() {
      isScanning = true;
      scanResults.clear();
      statusMessage = "Scanning for ESP32 devices...";
    });
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          scanResults = results;
        });
      });
      await Future.delayed(const Duration(seconds: 5));
      await FlutterBluePlus.stopScan();
      setState(() {
        isScanning = false;
        statusMessage = scanResults.isEmpty
            ? "No ESP32 devices found"
            : "Select a device to connect";
      });
    } catch (e) {
      setState(() {
        isScanning = false;
        statusMessage = "Scan failed: $e";
      });
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
      statusMessage = "Connecting to ${device.localName}...";
    });
    try {
      await device.connect();
      setState(() {
        isConnected = true;
        connectedDevice = device;
        statusMessage = "Connected to ${device.localName}";
      });
      // Discover services and characteristics
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          // Replace with your ESP32's characteristic UUIDs
          if (characteristic.properties.write) {
            wifiCharacteristic = characteristic;
          }
          if (characteristic.properties.notify) {
            statusCharacteristic = characteristic;
            await characteristic.setNotifyValue(true);
            characteristic.value.listen((value) {
              setState(() {
                esp32Response = utf8.decode(value);
              });
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        isConnecting = false;
        statusMessage = "Failed to connect: $e";
      });
    }
  }

  Future<void> sendWiFiCredentials() async {
    if (!isConnected || wifiCharacteristic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not connected to ESP32")),
      );
      return;
    }

    if (ssidController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter WiFi SSID")),
      );
      return;
    }

    try {
      Map<String, String> wifiData = {
        'ssid': ssidController.text,
        'password': passwordController.text,
      };

      String jsonData = json.encode(wifiData);
      List<int> bytes = utf8.encode(jsonData);

      await wifiCharacteristic!.write(bytes);

      setState(() {
        statusMessage = "WiFi credentials sent to ESP32";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("WiFi credentials sent successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        statusMessage = "Failed to send credentials: $e";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      setState(() {
        isConnected = false;
        connectedDevice = null;
        wifiCharacteristic = null;
        statusCharacteristic = null;
        statusMessage = "Disconnected";
        esp32Response = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 WiFi Configuration'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: isConnected ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      size: 48,
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusMessage,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (connectedDevice != null)
                      Text(
                        "Device: ${connectedDevice!.name}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Device Discovery Section
            if (!isConnected) ...[
              ElevatedButton.icon(
                onPressed: isScanning ? null : scanForDevices,
                icon: isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label:
                    Text(isScanning ? 'Scanning...' : 'Scan for ESP32 Devices'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              const SizedBox(height: 16),

              // Device List
              if (scanResults.isNotEmpty) ...[
                const Text(
                  'Available ESP32 Devices:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...scanResults.map((result) => Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.bluetooth,
                          color:
                              result.rssi > -80 ? Colors.green : Colors.orange,
                        ),
                        title: Text(result.device.localName.isNotEmpty
                            ? result.device.localName
                            : 'Unknown Device'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MAC: ${result.device.remoteId}'),
                            Text('Signal: ${result.rssi} dBm'),
                          ],
                        ),
                        trailing: isConnecting
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.arrow_forward_ios),
                        onTap: isConnecting
                            ? null
                            : () => connectToDevice(result.device),
                      ),
                    )),
              ],
            ],

            // WiFi Configuration Section
            if (isConnected) ...[
              const Text(
                'WiFi Configuration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: ssidController,
                decoration: const InputDecoration(
                  labelText: 'WiFi SSID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wifi),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'WiFi Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: sendWiFiCredentials,
                      icon: const Icon(Icons.send),
                      label: const Text('Send WiFi Credentials'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: disconnect,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Disconnect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),

              // ESP32 Response Section
              if (esp32Response.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'ESP32 Response:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    esp32Response,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// Helper widget for common WiFi SSIDs
class WiFiPresetCard extends StatelessWidget {
  final String ssid;
  final VoidCallback onTap;

  const WiFiPresetCard({
    super.key,
    required this.ssid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.wifi),
        title: Text(ssid),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
