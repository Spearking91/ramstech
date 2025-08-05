import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';

class Esp32Bluetooth extends StatefulWidget {
  const Esp32Bluetooth({super.key});

  @override
  _Esp32BluetoothState createState() => _Esp32BluetoothState();
}

class _Esp32BluetoothState extends State<Esp32Bluetooth> {
  // BLE Service and Characteristic UUIDs from your ESP32 code
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHARACTERISTIC_UUID_SSID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String CHARACTERISTIC_UUID_PASS =
      "beb5483e-36e1-4688-b7f5-ea07361b26a9";
  static const String CHARACTERISTIC_UUID_DEVICE_ID =
      "beb5483e-36e1-4688-b7f5-ea07361b26aa"; // New UUID

  FlutterBluePlus flutterBlue = FlutterBluePlus();
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? ssidCharacteristic;
  BluetoothCharacteristic? passwordCharacteristic;
  BluetoothCharacteristic? deviceIdCharacteristic; // New characteristic

  // Variable to store the secure device ID
  String? secureDeviceId;

  List<BluetoothDevice> devicesList = [];
  bool isScanning = false;
  bool isConnected = false;
  bool isConfiguring = false;
  bool showPassword = false;

  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  StreamSubscription<List<ScanResult>>? scanSubscription;
  StreamSubscription<BluetoothConnectionState>? connectionSubscription;
  StreamSubscription<List<int>>? deviceIdSubscription; // New subscription

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    connectionSubscription?.cancel();
    deviceIdSubscription?.cancel(); // Cancel device ID subscription
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
            } else if (characteristic.uuid.toString().toLowerCase() ==
                CHARACTERISTIC_UUID_DEVICE_ID.toLowerCase()) {
              deviceIdCharacteristic = characteristic;
              // Enable notifications for device ID
              await characteristic.setNotifyValue(true);

              // Listen for device ID notifications
              deviceIdSubscription =
                  characteristic.lastValueStream.listen((value) {
                if (value.isNotEmpty) {
                  String receivedDeviceId = utf8.decode(value);
                  setState(() {
                    secureDeviceId = receivedDeviceId;
                  });
                  print("Received Device ID: $receivedDeviceId");
                  _showSnackBar("Device ID received: $receivedDeviceId");
                }
              });

              // Also try to read the current value
              try {
                List<int> currentValue = await characteristic.read();
                if (currentValue.isNotEmpty) {
                  String currentDeviceId = utf8.decode(currentValue);
                  setState(() {
                    secureDeviceId = currentDeviceId;
                  });
                  print("Read Device ID: $currentDeviceId");
                }
              } catch (e) {
                print("Could not read device ID: $e");
              }
            }
          }
        }
      }

      if (ssidCharacteristic != null &&
          passwordCharacteristic != null &&
          deviceIdCharacteristic != null) {
        _showSnackBar(
            "Connected successfully! Device ID: ${secureDeviceId ?? 'Pending...'}");
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
      // Cancel device ID subscription before disconnecting
      deviceIdSubscription?.cancel();
      deviceIdSubscription = null;

      await connectedDevice!.disconnect();

      // Clear the device ID when disconnecting
      setState(() {
        secureDeviceId = null;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String? getSecureDeviceId() {
    return secureDeviceId;
  }

  // Method to return device ID when exiting
  void _exitWithDeviceId() {
    Navigator.pop(context, secureDeviceId);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return the device ID when back button is pressed
        Navigator.pop(context, secureDeviceId);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'ESP32 WiFi Setup',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => _exitWithDeviceId(),
          ),
          actions: [
            // Add a button to manually return device ID
            if (secureDeviceId != null)
              IconButton(
                icon: Icon(Icons.check),
                onPressed: () => _exitWithDeviceId(),
                tooltip: 'Use Device ID',
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status Card
              Container(
                margin: EdgeInsets.only(bottom: 24),
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isConnected
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        size: 40,
                        color: isConnected ? Colors.green : Colors.grey,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isConnected ? Colors.green : Colors.grey[600],
                      ),
                    ),
                    if (isConnected) ...[
                      SizedBox(height: 8),
                      Text(
                        connectedDevice?.localName ??
                            connectedDevice?.remoteId.toString() ??
                            '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      // Display the secure device ID
                      if (secureDeviceId != null) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.security,
                                      size: 16, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text(
                                    'Device ID',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                secureDeviceId!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              SizedBox(height: 8),
                              // Add a button to use this device ID
                              ElevatedButton.icon(
                                onPressed: () => _exitWithDeviceId(),
                                icon: Icon(Icons.check, size: 16),
                                label: Text('Use This Device ID'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              // Device Discovery Section
              if (!isConnected) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discover Devices',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: isScanning ? null : _startScan,
                      icon: isScanning
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.search, size: 18),
                      label: Text(isScanning ? 'Scanning...' : 'Scan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Device List
                if (devicesList.isEmpty)
                  Container(
                    padding: EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.devices,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          isScanning
                              ? 'Scanning for devices...'
                              : 'No devices found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!isScanning) ...[
                          SizedBox(height: 8),
                          Text(
                            'Tap scan to search for ESP32 devices',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  ...devicesList.map((device) {
                    String deviceName = device.localName.isEmpty
                        ? device.remoteId.toString()
                        : device.localName;

                    bool isLikelyESP32 = device.localName.contains("ESP32") ||
                        device.localName.contains("esp32") ||
                        device.remoteId.toString().contains("your_mac_pattern");

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isLikelyESP32 ? Colors.green : Colors.grey[200]!,
                          width: isLikelyESP32 ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isLikelyESP32
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.memory,
                            color: isLikelyESP32 ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Text(
                          deviceName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              device.remoteId.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (isLikelyESP32) ...[
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "ESP32 Device",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: FilledButton(
                          onPressed: () => _connectToDevice(device),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                isLikelyESP32 ? Colors.green : Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Connect'),
                        ),
                      ),
                    );
                  }),
              ],

              // WiFi Configuration Section
              if (isConnected) ...[
                Text(
                  'WiFi Configuration',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: ssidController,
                        decoration: InputDecoration(
                          labelText: 'Network Name (SSID)',
                          hintText: 'Enter your WiFi network name',
                          prefixIcon: Icon(Icons.wifi),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.blue, width: 2),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your WiFi password',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                              icon: Icon(showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.blue, width: 2),
                          ),
                        ),
                        obscureText: !showPassword,
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed:
                              isConfiguring ? null : _sendWiFiCredentials,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Configuring...'),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send, size: 20),
                                    SizedBox(width: 8),
                                    Text('Send Credentials'),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _disconnectDevice,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth_disabled, size: 20),
                        SizedBox(width: 8),
                        Text('Disconnect'),
                      ],
                    ),
                  ),
                ),
              ],

              // Troubleshooting Section
              SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline,
                            color: Colors.amber[700], size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Troubleshooting Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildTroubleshootingItem('Ensure Bluetooth is enabled'),
                    _buildTroubleshootingItem(
                        'Check if ESP32 advertising hasn\'t expired (1 min)'),
                    _buildTroubleshootingItem('Ensure Bluetooth is enabled'),
                    _buildTroubleshootingItem('Location services must be ON'),
                    _buildTroubleshootingItem('Grant all required permissions'),
                    _buildTroubleshootingItem(
                        'ESP32 should be powered and advertising'),
                    SizedBox(height: 8),
                    Text(
                      'Service UUID: $SERVICE_UUID',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber[700],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTroubleshootingItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void printDeviceId() {
    if (secureDeviceId != null) {
      print("Current Device ID: $secureDeviceId");
    } else {
      print("No device ID available");
    }
  }
}
