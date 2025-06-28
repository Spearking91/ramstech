import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ramstech/services/version_check_service.dart';
import 'package:dio/dio.dart';
import 'package:app_installer/app_installer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;

class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> with TickerProviderStateMixin {
  double _progress = 0.0;
  bool _downloading = false;
  bool _isLoading = false;
  bool _downloadExists = false;
  String? _downloadedVersion;
  String? _downloadedFilePath;

  // Dio cancel token for download cancellation
  CancelToken? _cancelToken;

  // App info variables
  String _appName = '';
  String _packageName = '';
  String _version = '';
  String _buildNumber = '';

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _initAnimations();
    _checkExistingDownload();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appName = info.appName;
      _packageName = info.packageName;
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  /// Get the internal storage directory for the ramstech folder
  Future<Directory> _getRamstechDirectory() async {
    Directory appDir;

    if (Platform.isAndroid) {
      // Use getApplicationSupportDirectory() for internal storage on Android
      appDir = await getApplicationSupportDirectory();
    } else {
      // Fallback for other platforms
      appDir = await getApplicationDocumentsDirectory();
    }

    final ramstechDir = Directory(path.join(appDir.path, 'ramstech'));

    // Create the directory if it doesn't exist
    if (!await ramstechDir.exists()) {
      await ramstechDir.create(recursive: true);
    }

    return ramstechDir;
  }

  Future<void> _checkExistingDownload() async {
    try {
      final ramstechDir = await _getRamstechDirectory();
      final downloadPath = path.join(ramstechDir.path, 'ramstech_update.apk');
      final versionPath = path.join(ramstechDir.path, 'download_version.txt');

      final downloadFile = File(downloadPath);
      final versionFile = File(versionPath);

      if (await downloadFile.exists() && await versionFile.exists()) {
        final version = await versionFile.readAsString();
        setState(() {
          _downloadExists = true;
          _downloadedVersion = version.trim();
          _downloadedFilePath = downloadPath;
        });
      }
    } catch (e) {
      // Ignore errors when checking for existing downloads
      print('Error checking existing download: $e');
    }
  }

  Future<void> _saveDownloadVersion(String version) async {
    try {
      final ramstechDir = await _getRamstechDirectory();
      final versionPath = path.join(ramstechDir.path, 'download_version.txt');
      final versionFile = File(versionPath);
      await versionFile.writeAsString(version);
    } catch (e) {
      print('Error saving download version: $e');
    }
  }

  Future<void> _clearDownloadData() async {
    try {
      final ramstechDir = await _getRamstechDirectory();
      final downloadPath = path.join(ramstechDir.path, 'ramstech_update.apk');
      final versionPath = path.join(ramstechDir.path, 'download_version.txt');

      final downloadFile = File(downloadPath);
      final versionFile = File(versionPath);

      if (await downloadFile.exists()) {
        await downloadFile.delete();
      }
      if (await versionFile.exists()) {
        await versionFile.delete();
      }

      setState(() {
        _downloadExists = false;
        _downloadedVersion = null;
        _downloadedFilePath = null;
      });
    } catch (e) {
      print('Error clearing download data: $e');
    }
  }

  Future<void> _installExistingApk() async {
    if (_downloadedFilePath != null && Platform.isAndroid) {
      try {
        await AppInstaller.installApk(_downloadedFilePath!);
      } catch (e) {
        _showSnackBar(context, 'Installation failed: $e', Colors.red);
      }
    }
  }

  void _cancelDownload() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('Download cancelled by user');
      setState(() {
        _downloading = false;
        _progress = 0.0;
      });
      _showSnackBar(context, 'Download cancelled', Colors.orange);
    }
  }

  Future<void> _checkVersion(BuildContext context) async {
    setState(() => _isLoading = true);

    const owner = 'Spearking91';
    const repo = 'ramstech';

    try {
      final latest =
          await VersionService.getLatestGitHubVersion(owner: owner, repo: repo);
      final current = await VersionService.getCurrentVersion();

      setState(() => _isLoading = false);

      if (latest != null && latest != current) {
        _showUpdateDialog(context, latest, owner, repo);
      } else {
        _showSnackBar(context, 'You have the latest version! 🎉', Colors.green);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(context, 'Failed to check for updates', Colors.red);
    }
  }

  void _showUpdateDialog(
      BuildContext context, String latest, String owner, String repo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.system_update, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version is ready to install!',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.new_releases, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Version $latest',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Later',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _downloadAndInstallApk(context, owner, repo, latest);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: 18),
                SizedBox(width: 6),
                Text('Update Now'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _downloadAndInstallApk(
      BuildContext context, String owner, String repo, String tag) async {
    // Create a new cancel token for this download
    _cancelToken = CancelToken();

    setState(() {
      _downloading = true;
      _progress = 0.0;
    });

    try {
      // Fetch release assets from GitHub API
      final url = Uri.parse(
          'https://api.github.com/repos/$owner/$repo/releases/tags/$tag');
      final response = await Dio().getUri(url);
      final assets = response.data['assets'] as List<dynamic>;
      final apkAsset = assets.firstWhere(
        (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => null,
      );

      if (apkAsset == null) {
        _showSnackBar(
            context, 'No APK found in the latest release', Colors.red);
        setState(() => _downloading = false);
        return;
      }

      final apkUrl = apkAsset['browser_download_url'] as String;

      // Get the ramstech directory in internal storage
      final ramstechDir = await _getRamstechDirectory();
      final savePath = path.join(ramstechDir.path, 'ramstech_update.apk');

      // Download the APK file
      await Dio().download(
        apkUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );

      // Save the downloaded version info
      await _saveDownloadVersion(tag);

      setState(() {
        _downloading = false;
        _downloadExists = true;
        _downloadedVersion = tag;
        _downloadedFilePath = savePath;
      });

      // Show success message and ask to install
      _showInstallDialog(context);
    } on DioException catch (e) {
      setState(() => _downloading = false);
      if (e.type == DioExceptionType.cancel) {
        // Download was cancelled, don't show error
        return;
      }
      _showSnackBar(context, 'Download failed: ${e.message}', Colors.red);
    } catch (e) {
      setState(() => _downloading = false);
      _showSnackBar(context, 'Download failed: $e', Colors.red);
    }
  }

  void _showInstallDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Download Complete'),
          ],
        ),
        content: const Text(
            'The update has been downloaded successfully. Would you like to install it now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Install Later',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _installExistingApk();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.install_mobile, size: 18),
                SizedBox(width: 6),
                Text('Install Now'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // App Icon and Title
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.blue, Colors.purple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  spreadRadius: 0,
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mobile_friendly,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _appName.isNotEmpty ? _appName : 'RamsTech',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep your app up to date',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // App Information Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 15,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'App Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Package Name', _packageName),
                      _buildInfoRow('Version', _version),
                      _buildInfoRow('Build Number', _buildNumber),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Existing Download Card (if exists)
                if (_downloadExists) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 15,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.file_download_done,
                                  color: Colors.green, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Update Ready',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Version ${_downloadedVersion ?? 'Unknown'} is ready to install',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _installExistingApk,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.install_mobile, size: 18),
                                    SizedBox(width: 6),
                                    Text('Install Update'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    title: const Text('Delete Download'),
                                    content: const Text(
                                        'Are you sure you want to delete the downloaded update?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await _clearDownloadData();
                                          _showSnackBar(
                                              context,
                                              'Download deleted',
                                              Colors.orange);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.red.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Update Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        spreadRadius: 0,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: (_downloading || _isLoading)
                        ? null
                        : () => _checkVersion(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Checking...',
                                  style: TextStyle(fontSize: 16)),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, size: 22),
                              SizedBox(width: 8),
                              Text('Check for Updates',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),

                // Download Progress
                if (_downloading) ...[
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 15,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.download,
                                  color: Colors.blue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Downloading Update',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _cancelDownload,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey[200],
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${(_progress * 100).toStringAsFixed(0)}% completed',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Loading...',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
