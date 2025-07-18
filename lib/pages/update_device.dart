import 'package:flutter/material.dart';
import 'package:ramstech/pages/bluetooth.dart';
import 'package:ramstech/pages/home_page.dart';
import 'package:ramstech/services/firestoreServices.dart';
import 'package:ramstech/widgets/scan_page.dart';

class UpdateDevice extends StatefulWidget {
  const UpdateDevice({super.key});

  @override
  State<UpdateDevice> createState() => _UpdateDeviceState();
}

class _UpdateDeviceState extends State<UpdateDevice>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _deviceNameController = TextEditingController();
  final _deviceIdController = TextEditingController();

  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _deviceIdController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true, // Ensures body resizes for keyboard
      body: SafeArea(
        child: ColoredBox(
          color: Colors.white70,
          child: SingleChildScrollView(
            // This allows the content to scroll when keyboard appears
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    size.height - MediaQuery.of(context).padding.vertical,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Container(
                      height: size.height * 0.25,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.devices,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Add Devices',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your Ramstech Device Here',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Form Section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                // Device Name Field
                                _buildModernTextField(
                                  controller: _deviceNameController,
                                  label: 'Device Name',
                                  hint: 'Enter your preferred device name',
                                  icon: Icons.devices,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a device name';
                                    }
                                    if (value.length < 3) {
                                      return 'Device name must be at least 3 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Device ID Field
                                _buildModernTextField(
                                  controller: _deviceIdController,
                                  label: 'Device ID',
                                  hint: _deviceIdController.text.isEmpty
                                      ? 'Get Device ID via Bluetooth or QR code'
                                      : 'Device ID obtained',
                                  icon: Icons.device_hub,
                                  readonly: true,
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_deviceIdController.text.isNotEmpty)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                        ),
                                      IconButton(
                                        onPressed: () async {
                                          try {
                                            final result =
                                                await Navigator.push<String>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    Esp32Bluetooth(),
                                              ),
                                            );
                                            if (result != null &&
                                                result.isNotEmpty) {
                                              if (!mounted) return;
                                              setState(() {
                                                _deviceIdController.text =
                                                    result;
                                              });
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Device ID obtained: ${result.substring(0, 8)}...'),
                                                  backgroundColor: Colors.green,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Failed to get device ID: $e'),
                                                backgroundColor: Colors.red,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          Icons.bluetooth_connected,
                                          color: _deviceIdController
                                                  .text.isNotEmpty
                                              ? Colors.green
                                              : Colors.grey[600],
                                        ),
                                        tooltip: 'Get Device ID via Bluetooth',
                                      ),
                                      const SizedBox(width: 2),
                                      IconButton(
                                        onPressed: () async {
                                          try {
                                            final result =
                                                await Navigator.push<String>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ScanPage(),
                                              ),
                                            );
                                            if (result != null &&
                                                result.isNotEmpty) {
                                              if (!mounted) return;
                                              setState(() {
                                                _deviceIdController.text =
                                                    result;
                                              });
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Device ID scanned: ${result.substring(0, 8)}...'),
                                                  backgroundColor: Colors.green,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Failed to scan device ID: $e'),
                                                backgroundColor: Colors.red,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                            Icons.qr_code_scanner_sharp),
                                        tooltip: 'Scan Device ID QR Code',
                                      ),
                                      if (_deviceIdController.text.isNotEmpty)
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _deviceIdController.clear();
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.clear,
                                            color: Colors.red,
                                          ),
                                          tooltip: 'Clear Device ID',
                                        ),
                                    ],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please get a device ID via Bluetooth or QR code';
                                    }
                                    final devIdRegex =
                                        RegExp(r'^DEV_[a-fA-F0-9]{16}$');
                                    if (!devIdRegex.hasMatch(value)) {
                                      return 'Please enter a valid device ID';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Add Device Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _addDevice,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shadowColor:
                                          theme.primaryColor.withOpacity(0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      disabledBackgroundColor: Colors.grey[300],
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Add Device',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Skip Button
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const HomePage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Skip for now',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool readonly = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      readOnly: readonly,
      validator: validator,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: Colors.grey[600],
          size: 22,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: Colors.grey[600]),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
    );
  }

  Future<void> _addDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirestoreService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final deviceId = _deviceIdController.text.trim();
      final deviceName = _deviceNameController.text.trim();

      // Check if device already exists and is assigned to another user
      final isAssigned = await FirestoreService.isDeviceAssigned(deviceId);
      if (isAssigned) {
        throw Exception('This device is already assigned to another user');
      }

      // Add device to user (this updates both devices and user's devices array)
      await FirestoreService.addDeviceToUser(
        userId: userId,
        deviceId: deviceId,
        deviceName: deviceName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device "$deviceName" added successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
