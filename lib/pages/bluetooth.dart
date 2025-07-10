import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';

class ESP32ConfigScreen extends StatefulWidget {
  const ESP32ConfigScreen({super.key});

  @override
  _ESP32ConfigScreenState createState() => _ESP32ConfigScreenState();
}

class _ESP32ConfigScreenState extends State<ESP32ConfigScreen> {
  // BLE Service and Characteristic UUIDs from your ESP32 code
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHARACTERISTIC_UUID_SSID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String CHARACTERISTIC_UUID_PASS =
      "beb5483e-36e1-4688-b7f5-ea07361b26a9";

  FlutterBluePlus flutterBlue = FlutterBluePlus();
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? ssidCharacteristic;
  BluetoothCharacteristic? passwordCharacteristic;

  List<BluetoothDevice> devicesList = [];
  bool isScanning = false;
  bool isConnected = false;
  bool isConfiguring = false;

  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<BluetoothConnectionState>? connectionSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    connectionSubscription?.cancel();
    ssidController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _initializeBluetooth() async {
    // Request permissions
    await _requestPermissions();

    // Check if Bluetooth is supported
    if (await FlutterBluePlus.isSupported == false) {
      _showSnackBar("Bluetooth not supported by this device");
      return;
    }

    // Listen to Bluetooth state changes
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        _showSnackBar("Bluetooth is ready");
      } else if (state == BluetoothAdapterState.off) {
        _showSnackBar("Please turn on Bluetooth");
      }
    });
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    if (!allGranted) {
      _showSnackBar("Please grant all permissions for Bluetooth functionality");
    }
  }

  Future<void> _startScan() async {
    if (isScanning) return;

    // Check if Bluetooth is on
    BluetoothAdapterState adapterState =
        await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _showSnackBar("Please turn on Bluetooth first");
      return;
    }

    setState(() {
      isScanning = true;
      devicesList.clear();
    });

    try {
      // Start scanning WITHOUT service filter first to see all devices
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 15),
        // Remove service filter to see all devices
        // withServices: [Guid(SERVICE_UUID)],
      );

      // Listen to scan results
      scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (!devicesList.any(
            (device) => device.remoteId == result.device.remoteId,
          )) {
            setState(() {
              devicesList.add(result.device);
            });
            // Debug: Print all discovered devices
            print(
              "Found device: ${result.device.localName} (${result.device.remoteId})",
            );
            print("Services: ${result.advertisementData.serviceUuids}");
          }
        }
      });

      // Wait for scan to complete
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
      _showSnackBar("Scan completed. Found ${devicesList.length} devices.");
    } catch (e) {
      _showSnackBar("Error during scanning: $e");
      print("Scan error: $e");
    } finally {
      setState(() {
        isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      _showSnackBar(
        "Connecting to ${device.localName.isEmpty ? device.remoteId : device.localName}...",
      );

      // Connect to device
      await device.connect(timeout: Duration(seconds: 15));

      // Listen to connection state
      connectionSubscription = device.connectionState.listen((
        BluetoothConnectionState state,
      ) {
        if (state == BluetoothConnectionState.connected) {
          setState(() {
            isConnected = true;
            connectedDevice = device;
          });
          _discoverServices();
        } else if (state == BluetoothConnectionState.disconnected) {
          setState(() {
            isConnected = false;
            connectedDevice = null;
            ssidCharacteristic = null;
            passwordCharacteristic = null;
          });
          _showSnackBar("Disconnected from device");
        }
      });
    } catch (e) {
      _showSnackBar("Connection failed: $e");
    }
  }

  Future<void> _discoverServices() async {
    if (connectedDevice == null) return;

    try {
      List<BluetoothService> services =
          await connectedDevice!.discoverServices();

      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() ==
            SERVICE_UUID.toLowerCase()) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() ==
                CHARACTERISTIC_UUID_SSID.toLowerCase()) {
              ssidCharacteristic = characteristic;
            } else if (characteristic.uuid.toString().toLowerCase() ==
                CHARACTERISTIC_UUID_PASS.toLowerCase()) {
              passwordCharacteristic = characteristic;
            }
          }
        }
      }

      if (ssidCharacteristic != null && passwordCharacteristic != null) {
        _showSnackBar("Connected successfully! Ready to configure WiFi.");
      } else {
        _showSnackBar("Error: Could not find required characteristics");
      }
    } catch (e) {
      _showSnackBar("Service discovery failed: $e");
    }
  }

  Future<void> _sendWiFiCredentials() async {
    if (ssidCharacteristic == null || passwordCharacteristic == null) {
      _showSnackBar("Device not properly connected");
      return;
    }

    if (ssidController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackBar("Please enter both SSID and password");
      return;
    }

    setState(() {
      isConfiguring = true;
    });

    try {
      // Send SSID
      await ssidCharacteristic!.write(utf8.encode(ssidController.text));
      await Future.delayed(
        Duration(milliseconds: 500),
      ); // Small delay between writes

      // Send Password
      await passwordCharacteristic!.write(utf8.encode(passwordController.text));

      _showSnackBar("WiFi credentials sent successfully!");

      // Clear the text fields for security
      ssidController.clear();
      passwordController.clear();
    } catch (e) {
      _showSnackBar("Failed to send credentials: $e");
    } finally {
      setState(() {
        isConfiguring = false;
      });
    }
  }

  Future<void> _disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ESP32 WiFi Configuration'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth,
                        size: 48,
                        color: isConnected ? Colors.green : Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        isConnected
                            ? 'Connected to: ${connectedDevice?.localName ?? connectedDevice?.remoteId}'
                            : 'Not Connected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isConnected ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Debug Card
              Card(
                elevation: 2,
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Troubleshooting Checklist:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('✓ Bluetooth is ON', style: TextStyle(fontSize: 12)),
                      Text(
                        '✓ Location services are ON',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '✓ All permissions granted',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '✓ ESP32 is powered and advertising',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '✓ ESP32 advertising hasn\'t expired (5 min)',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Looking for ESP32 with service: ${SERVICE_UUID}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Device List
              if (!isConnected) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available ESP32 Devices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isScanning ? null : _startScan,
                      child: isScanning
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Scan'),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Expanded(
                  child: devicesList.isEmpty
                      ? Center(
                          child: Text(
                            isScanning
                                ? 'Scanning for devices...'
                                : 'No devices found. Tap Scan to search.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: devicesList.length,
                          itemBuilder: (context, index) {
                            final device = devicesList[index];
                            String deviceName = device.localName.isEmpty
                                ? device.remoteId.toString()
                                : device.localName;

                            // Check if this might be your ESP32
                            bool isLikelyESP32 =
                                device.localName.contains("ESP32") ||
                                    device.localName.contains("esp32") ||
                                    device.remoteId.toString().contains(
                                          "your_mac_pattern",
                                        );

                            return Card(
                              color: isLikelyESP32 ? Colors.green[50] : null,
                              child: ListTile(
                                leading: Icon(
                                  Icons.devices,
                                  color: isLikelyESP32 ? Colors.green : null,
                                ),
                                title: Text(
                                  deviceName,
                                  style: TextStyle(
                                    fontWeight: isLikelyESP32
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(device.remoteId.toString()),
                                    if (isLikelyESP32)
                                      Text(
                                        "Likely ESP32 Device",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _connectToDevice(device),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        isLikelyESP32 ? Colors.green : null,
                                  ),
                                  child: Text('Connect'),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],

              // WiFi Configuration Form
              if (isConnected) ...[
                Text(
                  'WiFi Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: ssidController,
                  decoration: InputDecoration(
                    labelText: 'WiFi SSID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wifi),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'WiFi Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isConfiguring ? null : _sendWiFiCredentials,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isConfiguring
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Configuring...'),
                          ],
                        )
                      : Text(
                          'Send WiFi Credentials',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _disconnectDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Disconnect',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
