import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ramstech/auth/login_page.dart';
import 'package:ramstech/models/upload_model.dart';
import 'package:ramstech/pages/history_page.dart';
import 'package:ramstech/pages/profile_page.dart';
import 'package:ramstech/services/firebase_auth_service.dart';
import 'package:ramstech/services/firebase_database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:ramstech/pages/update_device.dart';
import 'package:ramstech/services/firestore_services.dart'; // Add this import
import 'package:ramstech/widgets/avatar.dart';
import 'package:ramstech/services/version_check_service.dart';
import 'package:ramstech/pages/update_page.dart';

enum ChartMetric { pms, humidity, temperature, aqi }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  UploadModel? _lastData;
  late TabController _tabController;
  ChartMetric _selectedMetric = ChartMetric.pms;
  // final List<UploadModel> _historicalData = [];

  // Add these for device selection
  List<DeviceModel> _userDevices = [];
  DeviceModel? _selectedDevice;
  bool _loadingDevices = true;

  bool _updateAvailable = false;
  String? _latestVersion;

  final GlobalKey _pmKey = GlobalKey();
  final GlobalKey _humidityKey = GlobalKey();
  final GlobalKey _tempKey = GlobalKey();
  final GlobalKey _aqiKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _deviceKey = GlobalKey();
  final GlobalKey _recommendationsKey = GlobalKey();
  final GlobalKey _historyKey = GlobalKey();
  TutorialCoachMark? _tutorialCoachMark;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedMetric = ChartMetric.values[_tabController.index];
      });
    });
    _fetchUserDevices();
    _checkForUpdate(); // <-- Add this
  }

  Future<void> _checkForUpdate() async {
    try {
      // Replace with your actual GitHub owner/repo
      final latest = await VersionService.getLatestGitHubVersion(
        owner: 'Altertech01', // <-- your GitHub username/org
        repo: 'ramstech', // <-- your repo name
      );
      final current = await VersionService.getCurrentVersion();
      if (latest != null && latest != current) {
        setState(() {
          _updateAvailable = true;
          _latestVersion = latest;
        });
      }
    } catch (_) {
      // Ignore errors for now
    }
  }

  Future<void> _fetchUserDevices() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loadingDevices = true);
    try {
      final devices = await FirestoreService.getUserDevices(user.uid);
      setState(() {
        _userDevices = devices;
        if (_userDevices.isNotEmpty) {
          _selectedDevice ??= _userDevices.first;
        }
      });
    } finally {
      setState(() => _loadingDevices = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tutorialCoachMark?.finish();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Main content
          _buildMainContent(context),
          // Update banner
          if (_updateAvailable)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: MaterialBanner(
                backgroundColor: Colors.yellow[700],
                content: Text(
                  'A new update ($_latestVersion) is available!',
                  style: const TextStyle(color: Colors.black),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UpdatePage()),
                      );
                    },
                    child: const Text('Update'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _updateAvailable = false;
                      });
                    },
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          // return _buildLoadingState();
        }

        if (!authSnapshot.hasData) {
          return _buildUnauthenticatedState();
        }

<<<<<<< HEAD
            return CustomScrollView(
              controller: _scrollController, // <-- add this
=======
        // If still loading devices, show loading
        if (_loadingDevices) {
          return _buildLoadingState();
        }

        // If no devices, show a message
        if (_userDevices.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No devices found. Please add a device to view data.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return UpdateDevice();
                      },
                    ),
                  );
                },
                child: Text('Add device'),
              ),
              FilledButton(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                child: Text('Logout'),
              ),
            ],
          );
        }

        // Use selected device's MAC address for data streams
        final selectedMac = _selectedDevice?.macAddress ?? '';

        return StreamBuilder<UploadModel>(
          stream: FirebaseDatabaseMethods.getDeviceDataAsStream(selectedMac)
              .where((data) => data != null)
              .cast<UploadModel>(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _lastData = snapshot.data;
            }

            return CustomScrollView(
              controller: _scrollController, // <-- add this
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate the percentage collapsed (0 = expanded, 1 = collapsed)
                      final double collapsedHeight =
                          kToolbarHeight + MediaQuery.of(context).padding.top;
                      final double expandedHeight = 200;
                      final double t =
                          ((constraints.maxHeight - collapsedHeight) /
                                  (expandedHeight - collapsedHeight))
                              .clamp(0.0, 1.0);

                      return FlexibleSpaceBar(
                        title: t < 0.5 // Collapsed (show device name or MAC)
                            ? Text(
                                _selectedDevice?.name?.isNotEmpty == true
                                    ? '${_selectedDevice!.name}'
                                    : _selectedDevice?.macAddress ?? '',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            // Expanded (show "Air quality")
                            : Text(
                                'Air Quality Monitor',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade200,
                                Colors.blue.shade400,
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 60,
                                right: 20,
                                child: Icon(
                                  Icons.air,
                                  size: 120,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary
                                      .withOpacity(0.1),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Real-time Environmental Data',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                              .withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Stay informed, breathe better',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                              .withAlpha(125),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.help_outline),
                      onPressed: () async {
                        await _scrollController.animateTo(
                          0.0,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );

                        await Future.delayed(
                            Duration(seconds: 1)); // Wait 1 second

                        _showTutorial(); // Now call the tutorial
                      },
                      tooltip: 'Show Tutorial',
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Avatar(
                        key: _profileKey,
                        radius: 18,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfilePage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: _buildContent(context),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Authentication Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please sign in to access your air quality data',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              ),
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

//   Widget _buildAppBar(BuildContext context) {
//     return
// }

  Widget _buildContent(BuildContext context) {
    final data = _lastData;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device selector using buildQuickDeviceAccess
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _userDevices.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final device = _userDevices[index];
                final isOnline = device.lastSeen != null &&
                    DateTime.now().difference(device.lastSeen!).inMinutes < 4;
                final isSelected =
                    device.macAddress == _selectedDevice?.macAddress;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDevice = device;
                      // Update the defaultDeviceMac when device is selected
                      FirebaseDatabaseMethods.defaultDeviceMac =
                          device.macAddress;
                    });
                  },
                  child: Container(
                    key: _deviceKey,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[900],
                      borderRadius: BorderRadius.circular(50),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: _buildQuickDeviceAccess(
                        device.name?.isNotEmpty == true
                            ? device.name!
                            : '${device.macAddress.substring(0, 7)}...........',
                        Icons.devices,
                        isOnline),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildMetricsGrid(data),
          const SizedBox(height: 32),
          _buildRecommendationsCard(aqi: data?.aqi ?? 0),
          const SizedBox(height: 32),
          _buildHistoricalSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuickDeviceAccess(String label, IconData icon, bool isOnline) {
    return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            SizedBox(width: 4),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: isOnline ? Colors.lightGreen : Colors.amber,
              ),
            )
          ],
        ));
  }

  // Widget _buildDeviceSelector() {
  //   return Row(
  //     children: [
  //       const Icon(Icons.devices, size: 20),
  //       const SizedBox(width: 8),
  //       Expanded(
  //         child: DropdownButton<DeviceModel>(
  //           value: _selectedDevice,
  //           isExpanded: true,
  //           icon: const Icon(Icons.arrow_drop_down),
  //           underline:
  //               Container(height: 1, color: Theme.of(context).dividerColor),
  //           items: _userDevices.map((device) {
  //             return DropdownMenuItem<DeviceModel>(
  //               value: device,
  //               child: Text(
  //                 device.name?.isNotEmpty == true
  //                     ? device.name!
  //                     : device.macAddress,
  //                 overflow: TextOverflow.ellipsis,
  //               ),
  //             );
  //           }).toList(),
  //           onChanged: (device) {
  //             setState(() {
  //               _selectedDevice = device;
  //             });
  //           },
  //         ),
  //       ),
  //       IconButton(
  //         icon: Icon(Icons.add),
  //         onPressed: () {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) {
  //                 return UpdateDevice();
  //               },
  //             ),
  //           );
  //         },
  //       ),
  //     ],
  //   );
  // }

  Widget _buildMetricsGrid(UploadModel? data) {
    final metrics = [
      {
        'title': 'PM 2.5',
        'value': data?.pms?.toStringAsFixed(1) ?? '--',
        'unit': 'µg/m³',
        'icon': Icons.grain,
        'color': _getAQIColor(data?.pms ?? 0),
        'status': _getAQIStatus(data?.pms ?? 0),
      },
      {
        'title': 'Humidity',
        'value': data?.humidity?.toStringAsFixed(1) ?? '--',
        'unit': '%',
        'icon': Icons.water_drop,
        'color': _getHumidityColor(data?.humidity ?? 0),
        'status': _getHumidityStatus(data?.humidity ?? 0),
      },
      {
        'title': 'Temperature',
        'value': data?.temperature?.toStringAsFixed(1) ?? '--',
        'unit': '°C',
        'icon': Icons.thermostat,
        'color': _getTemperatureColor(data?.temperature ?? 0),
        'status': _getTemperatureStatus(data?.temperature ?? 0),
      },
      {
        'title': 'AQI',
        'value': data?.aqi?.toStringAsFixed(0) ?? '--',
        'unit': '',
        'icon': Icons.eco,
        'color': _getAQIColor(data?.aqi ?? 0),
        'status': data?.category ?? 'Unknown',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        final key = switch (index) {
          0 => _pmKey,
          1 => _humidityKey,
          2 => _tempKey,
          3 => _aqiKey,
          _ => null,
        };
        return Container(
          key: key,
          child: _buildMetricCard(
            title: metric['title'] as String,
            value: metric['value'] as String,
            unit: metric['unit'] as String,
            icon: metric['icon'] as IconData,
            color: metric['color'] as Color,
            status: metric['status'] as String,
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String status,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                children: [
                  TextSpan(text: value),
                  TextSpan(
                    text: unit.isNotEmpty ? ' $unit' : '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalSection() {
    return Container(
      key: _historyKey,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historical Data',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last 24 hours',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HistoryTab(selectedDevice: _selectedDevice),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildMetricTabs(),
            const SizedBox(height: 16),
            _buildChart(), // This will use the selected device
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        // indicatorPadding: EdgeInsetsGeometry.symmetric(horizontal: ),
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'PM 2.5'),
          Tab(text: 'Humidity'),
          Tab(text: 'Temperature'),
          Tab(text: 'AQI'),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final selectedMac = _selectedDevice?.macAddress ?? '';
    return SizedBox(
      height: 200,
      child: StreamBuilder<List<UploadModel>>(
        stream: FirebaseDatabaseMethods.getHistoricalDataAsStream(
          selectedMac,
          limit: 24,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No historical data available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final spots = _getDataPoints(data, _selectedMetric);

          return LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value % 6 == 0) {
                        final hours = (24 - (value / data.length) * 24).round();
                        return Text(
                          '${hours}h',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontSize: 10,
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: _getMetricColor(_selectedMetric),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _getMetricColor(_selectedMetric).withOpacity(0.1),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationsCard({required double aqi}) {
    String title;
    String message;
    Color color;

    if (aqi <= 50) {
      title = 'Air Quality: Good';
      message = 'Air quality is excellent. Enjoy outdoor activities!';
      color = Colors.green;
    } else if (aqi <= 100) {
      title = 'Air Quality: Moderate';
      message =
          'Air quality is acceptable. Sensitive individuals should take care.';
      color = Colors.yellow.shade700;
    } else if (aqi <= 150) {
      title = 'Air Quality: Unhealthy';
      message =
          'Air quality is unhealthy for sensitive groups. Limit outdoor exertion.';
      color = Colors.orange;
    } else if (aqi <= 200) {
      title = 'Air Quality: Very Unhealthy';
      message =
          'Everyone may experience health effects. Avoid outdoor activities.';
      color = Colors.red;
    } else {
      title = 'Air Quality: Hazardous';
      message = 'Health warnings of emergency conditions. Stay indoors!';
      color = Colors.purple;
    }

    return Container(
      key: _recommendationsKey,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.eco,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _signOut(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuthMethod.auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTutorial() {
    int currentTutorialStep = 0;
    final targets = _createTargets();
    if (targets.isNotEmpty) {
      _tutorialCoachMark = TutorialCoachMark(
        targets: targets,
        colorShadow: Colors.black,
        textSkip: "SKIP",
        paddingFocus: 10,
        opacityShadow: 0.8,
        hideSkip: false,
        useSafeArea: true,
        // onClickTarget: (target) {
        //   _handleTutorialStep(target);
        // },
        onClickTargetWithTapPosition: (target, tapDetails) {
          _handleTutorialStep(target);
        },
        onSkip: () {
          return true;
        },
      );
      _tutorialCoachMark?.show(context: context);
    }
  }

  void _handleTutorialStep(TargetFocus target) {
    // Check if this is the recommendations target and scroll

    if (target.identify == "Recommendation Tab") {
      // Add a small delay to let the tutorial UI update first
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(1000.0,
            duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
      });
    }
    //   if (target.identify == "Recommendation Tab") {
    //     // Add a small delay to let the tutorial UI update first
    //     Future.delayed(const Duration(milliseconds: 100), () {
    //       final keyContext = _recommendationsKey.currentContext;
    //       if (keyContext != null) {
    //         Scrollable.ensureVisible(
    //           keyContext,
    //           duration: const Duration(milliseconds: 500),
    //           curve: Curves.easeInOut,
    //           alignment: 0.3,
    //         );
    //       }
    //     });
    //   } else if (target.identify == "History") {
    //     // Add a small delay to let the tutorial UI update first
    //     Future.delayed(const Duration(milliseconds: 100), () {
    //       final keyContext = _historyKey.currentContext;
    //       if (keyContext != null) {
    //         Scrollable.ensureVisible(
    //           keyContext,
    //           duration: const Duration(milliseconds: 500),
    //           curve: Curves.easeInOut,
    //           alignment: 0.3,
    //         );
    //       }
    //     });
    //   }
  }

// Replace your _createTargets method with this updated version:
  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];

    // Only add targets if the keys are available and rendered
    if (_deviceKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "Devices",
          keyTarget: _deviceKey,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Devices: shows the number of devices connected to the account",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_pmKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "PM2.5",
          keyTarget: _pmKey,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "PM2.5: Fine particulate matter in the air (µg/m³). High values mean more pollution.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_humidityKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "Humidity",
          keyTarget: _humidityKey,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Humidity: The amount of water vapor in the air (%).",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_tempKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "Temperature",
          keyTarget: _tempKey,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Temperature: The current air temperature (°C).",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_aqiKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "AQI",
          keyTarget: _aqiKey,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "AQI: Air Quality Index. Summarizes air pollution level. Lower is better.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_profileKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "Profile",
          keyTarget: _profileKey,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Profile: Shows profile information and settings.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Remove the onTargetFocus from recommendations target
    if (_recommendationsKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "Recommendations Tab",
          keyTarget: _recommendationsKey,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Recommendations Tab: Shows recommendations based on air quality.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_historyKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "History",
          keyTarget: _historyKey,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "History tab: shows all historical data collected",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return targets;
  }

// Also add this method to properly dispose of the tutorial
// @override
// void dispose() {

//   super.dispose();
// }
  // Helper methods for status and colors
  Color _getAQIColor(double value) {
    if (value <= 50) return Colors.green;
    if (value <= 100) return Colors.yellow.shade600;
    if (value <= 150) return Colors.orange;
    if (value <= 200) return Colors.red;
    return Colors.purple;
  }

  String _getAQIStatus(double value) {
    if (value <= 50) return 'Good';
    if (value <= 100) return 'Moderate';
    if (value <= 150) return 'Unhealthy';
    if (value <= 200) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Color _getHumidityColor(double value) {
    if (value >= 30 && value <= 60) return Colors.green;
    if (value >= 20 && value <= 70) return Colors.yellow.shade600;
    return Colors.orange;
  }

  String _getHumidityStatus(double value) {
    if (value >= 30 && value <= 60) return 'Optimal';
    if (value >= 20 && value <= 70) return 'Moderate';
    if (value < 20) return 'Dry';
    return 'Humid';
  }

  Color _getTemperatureColor(double value) {
    if (value >= 18 && value <= 24) return Colors.green;
    if (value >= 15 && value <= 28) return Colors.yellow.shade600;
    return Colors.orange;
  }

  String _getTemperatureStatus(double value) {
    if (value >= 18 && value <= 24) return 'Comfortable';
    if (value < 18) return 'Cool';
    return 'Warm';
  }

  List<FlSpot> _getDataPoints(List<UploadModel> data, ChartMetric metric) {
    return data.asMap().entries.map((entry) {
      final value = switch (metric) {
        ChartMetric.pms => entry.value.pms,
        ChartMetric.humidity => entry.value.humidity,
        ChartMetric.temperature => entry.value.temperature,
        ChartMetric.aqi => entry.value.aqi ?? 0.0,
      };
      return FlSpot(entry.key.toDouble(), value ?? 0);
    }).toList();
  }

  Color _getMetricColor(ChartMetric metric) {
    return switch (metric) {
      ChartMetric.pms => Colors.blue,
      ChartMetric.humidity => Colors.orange,
      ChartMetric.temperature => Colors.red,
      ChartMetric.aqi => Colors.green,
    };
  }
}
