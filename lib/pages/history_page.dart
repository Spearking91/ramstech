import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramstech/models/upload_model.dart';
import 'package:ramstech/services/excel_export_service.dart';
import 'package:ramstech/services/firebase_database_service.dart';
import 'package:ramstech/services/firestore_services.dart';

enum DisplayMetric { temperature, humidity, pms, aqi }

class HistoryTab extends StatefulWidget {
  final DeviceModel? selectedDevice;
  const HistoryTab({super.key, this.selectedDevice});

  @override
  _HistoryTabState createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> with TickerProviderStateMixin {
  DisplayMetric _selectedMetric = DisplayMetric.temperature;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showChart = true;
  DeviceModel? _selectedDevice;
  UserModel? _selectedUser;

  @override
  void initState() {
    super.initState();
    _selectedDevice = widget.selectedDevice;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with device info
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? Colors.grey[850] : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historical Data',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                    ),
                  ),
                  // Show selected device info
                  if (_selectedDevice != null)
                    Text(
                      (_selectedUser ?.getDeviceName( _selectedDevice?.macAddress ?? '') ?.isNotEmpty == true)
                          ? _selectedUser!.getDeviceName(_selectedDevice!.macAddress)!
                          : _selectedDevice!.macAddress,
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Colors.grey[850]!, Colors.grey[800]!]
                        : [Colors.blue[50]!, Colors.white],
                  ),
                ),
              ),
            ),
            actions: [
              // View Toggle Button
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _showChart ? Icons.list : Icons.show_chart,
                    key: ValueKey(_showChart),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _showChart = !_showChart;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
                tooltip: _showChart ? 'Show List View' : 'Show Chart View',
              ),
              // Export Button
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.file_download,
                        color: Colors.white, size: 20),
                  ),
                  onPressed: _exportData,
                  tooltip: 'Export Data',
                ),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: StreamBuilder<List<UploadModel>>(
                // FIX: Use selected device MAC address instead of defaultDeviceMac
                stream: FirebaseDatabaseMethods.getHistoricalDataAsStream(
                  _selectedDevice?.macAddress ?? '', // ← KEY CHANGE HERE
                  limit: 24,
                ),
                builder: (context, snapshot) {
                  // Add debug info
                  print('Selected device: ${_selectedDevice?.macAddress}');
                  print('Snapshot has data: ${snapshot.hasData}');
                  print('Data length: ${snapshot.data?.length ?? 0}');

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingWidget();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorWidget(snapshot.error.toString());
                  }

                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return _buildEmptyWidget();
                  }

                  return Column(
                    children: [
                      // Metric Selector Card
                      _buildMetricSelector(isDark),

                      // Chart or List View
                      if (_showChart)
                        _buildChartView(data, isDark)
                      else
                        _buildListView(data, isDark),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSelector(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Metric',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DisplayMetric.values.map((metric) {
              final isSelected = _selectedMetric == metric;
              final metricInfo = _getMetricInfo(metric);

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedMetric = metric);
                  _animationController.reset();
                  _animationController.forward();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? metricInfo.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? metricInfo.color : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        metricInfo.icon,
                        color: isSelected ? Colors.white : metricInfo.color,
                        size: 20,
                      ),
                      isSelected
                          ? const SizedBox(width: 8)
                          : const SizedBox(width: 0),
                      isSelected
                          ? Text(
                              metricInfo.label,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white
                                        : Colors.grey[700]),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            )
                          : Text('')
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChartView(List<UploadModel> data, bool isDark) {
    final metricInfo = _getMetricInfo(_selectedMetric);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metricInfo.icon, color: metricInfo.color, size: 24),
              const SizedBox(width: 8),
              Text(
                '${metricInfo.label} Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: null,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value % 4 == 0 && value < data.length) {
                          final dateTime = data[value.toInt()].dateTime;
                          if (dateTime != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('HH:mm').format(dateTime),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                        }
                        return const Text('');
                      },
                      reservedSize: 35,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getDataPoints(data),
                    isCurved: true,
                    color: metricInfo.color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: metricInfo.color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          metricInfo.color.withOpacity(0.3),
                          metricInfo.color.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<UploadModel> data, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Recent Readings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                color: isDark ? Colors.grey[700] : Colors.grey[200],
                height: 1,
              ),
            ),
            itemBuilder: (context, index) {
              final item = data[index];
              final metricInfo = _getMetricInfo(_selectedMetric);
              final (value, unit) = _getValueAndUnit(item, _selectedMetric);

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: metricInfo.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        metricInfo.icon,
                        color: metricInfo.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${value ?? '0'} $unit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.formattedDateTime ?? 'No timestamp',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading data...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.data_usage_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Historical data will appear here once available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    // Check if device is selected
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No device selected for export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.blue,
                ),
          ),
          child: child!,
        );
      },
    );

    if (dateRange != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text('Exporting data...'),
            ],
          ),
        ),
      );

      try {
        // FIX: Use selected device MAC address
        final data = await FirebaseDatabaseMethods.getHistoricalDataByDateRange(
          _selectedDevice!.macAddress, // ← KEY CHANGE HERE
          dateRange.start,
          dateRange.end,
        );

        final fileName =
            'sensor_data_${DateFormat('yyyyMMdd').format(dateRange.start)}_${DateFormat('yyyyMMdd').format(dateRange.end)}';

        await ExcelExportService.exportAndShareToExcel(
          data,
          fileName,
          shareSubject:
              'Sensor Data Export ${DateFormat('yyyy-MM-dd').format(dateRange.start)} to ${DateFormat('yyyy-MM-dd').format(dateRange.end)}',
        );

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('File exported successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error exporting data: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void updateSelectedDevice(DeviceModel? device) {
    setState(() {
      _selectedDevice = device;
    });
  }

  List<FlSpot> _getDataPoints(List<UploadModel> data) {
    return data.asMap().entries.map((entry) {
      final value = switch (_selectedMetric) {
        DisplayMetric.temperature => entry.value.temperature,
        DisplayMetric.humidity => entry.value.humidity,
        DisplayMetric.pms => entry.value.pms,
        DisplayMetric.aqi => entry.value.aqi,
      };
      return FlSpot(entry.key.toDouble(), value ?? 0);
    }).toList();
  }

  ({String label, IconData icon, Color color}) _getMetricInfo(
      DisplayMetric metric) {
    return switch (metric) {
      DisplayMetric.temperature => (
          label: 'Temperature',
          icon: Icons.thermostat,
          color: Colors.orange,
        ),
      DisplayMetric.humidity => (
          label: 'Humidity',
          icon: Icons.water_drop,
          color: Colors.blue,
        ),
      DisplayMetric.pms => (
          label: 'PM',
          icon: Icons.air,
          color: Colors.green,
        ),
      DisplayMetric.aqi => (
          label: 'AQI',
          icon: Icons.air_outlined,
          color: Colors.purple,
        ),
    };
  }

  (String?, String) _getValueAndUnit(UploadModel item, DisplayMetric metric) {
    return switch (metric) {
      DisplayMetric.temperature => (item.temperature?.toStringAsFixed(1), '°C'),
      DisplayMetric.humidity => (item.humidity?.toStringAsFixed(1), '%'),
      DisplayMetric.pms => (item.pms?.toStringAsFixed(1), 'µg/m³'),
      DisplayMetric.aqi => (item.aqi?.toStringAsFixed(1), ''),
    };
  }
}
