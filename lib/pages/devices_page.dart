import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:ramstech/pages/update_device.dart';
import 'package:ramstech/services/firebase_auth_service.dart';
import 'package:ramstech/services/firestoreServices.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<DeviceModel> _userDevices = [];
  bool _loading = true;

  int _totalDevices = 0;
  int _activeDevices = 0;
  int _offlineDevices = 0;

  @override
  void initState() {
    super.initState();
    _fetchDeviceStats();
  }

  Future<void> _fetchDeviceStats() async {
    final userId = FirebaseAuthMethod.user?.uid;
    if (userId == null) return;

    final devices = await FirestoreService.getUserDevices(userId);
    final now = DateTime.now();

    int active = 0;
    int offline = 0;

    for (final device in devices) {
      if (device.lastSeen != null &&
          now.difference(device.lastSeen!).inMinutes < 4) {
        active++;
      } else {
        offline++;
      }
    }

    setState(() {
      _userDevices = devices;
      _totalDevices = devices.length;
      _activeDevices = active;
      _offlineDevices = offline;
      _loading = false;
    });
  }

  Future<void> _deleteDevice(DeviceModel device) async {
    final userId = FirebaseAuthMethod.user?.uid;
    if (userId == null) return;

    try {
      await FirestoreService.removeDeviceFromUser(
        userId: userId,
        deviceId: device.macAddress,
      );
      await _fetchDeviceStats();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Device deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete device: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildStatsCard(isDark),
                  ListTile(
                    title: Text('Devices'),
                    trailing: TextButton.icon(
                      icon: Icon(Icons.sort),
                      onPressed: () {},
                      label: Text('Filter'),
                    ),
                  ),
                  Expanded(
                    child: _userDevices.isEmpty
                        ? Center(child: Text('No devices found.'))
                        : ListView.builder(
                            itemCount: _userDevices.length,
                            itemBuilder: (context, index) {
                              final device = _userDevices[index];
                              final isOnline = device.lastSeen != null &&
                                  DateTime.now()
                                          .difference(device.lastSeen!)
                                          .inMinutes <
                                      4;
                              final statusText =
                                  isOnline ? 'Online' : 'Offline';
                              final statusColor =
                                  isOnline ? Colors.lightGreen : Colors.orange;

                              return ListTile(
                                contentPadding:
                                    EdgeInsets.only(left: 16, right: 0),
                                leading: Icon(Icons.devices),
                                title: Text(
                                  device.name?.isNotEmpty == true
                                      ? device.name!
                                      : 'Device ${index + 1}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.grey[900]),
                                ),
                                subtitle: Text(
                                  device.macAddress.length >= 7
                                      ? device.macAddress.substring(0, 7) +
                                          '***********'
                                      : device.macAddress,
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600]),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {},
                                      icon: Icon(Icons.circle,
                                          color: statusColor, size: 14),
                                      label: Text(
                                        statusText,
                                        style: TextStyle(
                                            color: statusColor, fontSize: 13),
                                      ),
                                      style: TextButton.styleFrom(
                                        minimumSize: Size.zero,
                                        padding: EdgeInsets.zero,
                                        foregroundColor: statusColor,
                                      ),
                                    ),
                                    PopupMenuButton(
                                      itemBuilder: (context) {
                                        return [
                                          PopupMenuItem(
                                            onTap: () {
                                              Future.delayed(
                                                  Duration.zero,
                                                  () => showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          return AlertDialog(
                                                            title: Text(
                                                                'Share Device'),
                                                            content: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  device.macAddress
                                                                              .length >=
                                                                          7
                                                                      ? device.macAddress.substring(
                                                                              0,
                                                                              7) +
                                                                          '*********'
                                                                      : device
                                                                          .macAddress,
                                                                ),
                                                                PrettyQrView
                                                                    .data(
                                                                  data: device
                                                                      .macAddress,
                                                                  decoration:
                                                                      const PrettyQrDecoration(
                                                                    background:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child:
                                                                    Text('OK'),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ));
                                            },
                                            child: Text("Share"),
                                          ),
                                          PopupMenuItem(
                                            onTap: () {
                                              Future.delayed(
                                                  Duration.zero,
                                                  () => showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          return AlertDialog(
                                                            title: Text(
                                                                'Delete Device'),
                                                            content: Text(
                                                                'Are you sure you want to delete this device?'),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context),
                                                                child: Text(
                                                                    'Cancel'),
                                                              ),
                                                              TextButton(
                                                                onPressed:
                                                                    () async {
                                                                  Navigator.pop(
                                                                      context);
                                                                  await _deleteDevice(
                                                                      device);
                                                                },
                                                                style: TextButton
                                                                    .styleFrom(
                                                                        foregroundColor:
                                                                            Colors.red),
                                                                child: Text(
                                                                    'Delete'),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ));
                                            },
                                            child: Text("Delete"),
                                          ),
                                        ];
                                      },
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    final stats = [
      {'label': 'Devices', 'value': '$_totalDevices', 'icon': Icons.devices},
      {'label': 'Active', 'value': '$_activeDevices', 'icon': Icons.power},
      {
        'label': 'Offline',
        'value': '$_offlineDevices',
        'icon': Icons.power_off
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Device Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              TextButton(
                onPressed: () {
                  _fetchDeviceStats();
                },
                child: Text(
                  'Refresh',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.grey[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: stats.map((stat) {
              return _buildStatItem(
                label: stat['label'] as String,
                value: stat['value'] as String,
                icon: stat['icon'] as IconData,
                isDark: isDark,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UpdateDevice()));
              },
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Device',
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    Color color = Colors.blue;
    if (label == 'Active') color = Colors.green;
    if (label == 'Offline') color = Colors.orange;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
