import 'package:flutter/material.dart';
import 'package:ramstech/auth/login_page.dart';
import 'package:ramstech/data/notifiers.dart';
import 'package:ramstech/pages/update_page.dart';
import 'package:ramstech/services/firebase_auth_service.dart';
import 'package:ramstech/services/firestore_services.dart';
import 'package:ramstech/widgets/avatar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userName = FirebaseAuthMethod.user?.displayName?.isNotEmpty == true
        ? FirebaseAuthMethod.user!.displayName!
        : 'Unknown User';

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomScrollView(
            slivers: [
              // Profile Header
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: _buildProfileHeader(isDark),
                  ),
                ),
              ),

              // Profile Stats Card
              // SliverToBoxAdapter(
              //   child: Transform.translate(
              //     offset: Offset(0, _slideAnimation.value * 1.5),
              //     child: Opacity(
              //       opacity: _fadeAnimation.value,
              //       child: _buildStatsCard(isDark),
              //     ),
              //   ),
              // ),

              // Account Settings
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value * 2),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: _buildAccountSettings(isDark),
                  ),
                ),
              ),

              // Additional spacing at bottom
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    final userName = FirebaseAuthMethod.user?.displayName?.isNotEmpty == true
        ? FirebaseAuthMethod.user!.displayName!
        : 'Unknown User';

    return Container(
      // height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A237E),
                  const Color(0xFF3949AB),
                  const Color(0xFF5C6BC0),
                ]
              : [
                  const Color(0xFF1976D2),
                  const Color(0xFF42A5F5),
                  const Color(0xFF64B5F6),
                ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar with glow effect
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Hero(
                tag: 'profile_avatar',
                child: Avatar(
                  onPressed: () => _showAvatarOptions(context),
                ),
              ),
            ),

            const SizedBox(height: 5),

            // User Name
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 4),

            // Email
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                FirebaseAuthMethod.user?.email ?? 'No email',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // const SizedBox(height: 5),

            // // Edit Profile Button
            // ElevatedButton.icon(
            //   onPressed: () => _editProfile(context),
            //   icon: const Icon(Icons.edit, size: 18),
            //   label: const Text('Edit Profile'),
            //   style: ElevatedButton.styleFrom(
            //     foregroundColor: Colors.blue[700],
            //     backgroundColor: Colors.white,
            //     elevation: 0,
            //     padding:
            //         const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(25),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    final stats = [
      {'label': 'Devices', 'value': '2', 'icon': Icons.devices},
      {'label': 'Active', 'value': '7', 'icon': Icons.power},
      {'label': 'Offline', 'value': '4', 'icon': Icons.power_off},
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
          Text(
            'Device Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
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

  Widget _buildAccountSettings(bool isDark) {
    final settings = [
      {
        'title': 'Account Information',
        'icon': Icons.person,
        'items': [
          {
            'title': 'Email',
            'subtitle': FirebaseAuthMethod.user?.email ?? 'Not provided',
            'icon': Icons.email,
            'action': () => _showEmailDialog(context),
          },
          {
            'title': 'Phone',
            'subtitle': FirebaseAuthMethod.user?.phoneNumber != null
                ? '+233${FirebaseAuthMethod.user?.phoneNumber}'
                : 'Not provided',
            'icon': Icons.phone,
            'action': () => _showPhoneDialog(context),
          },
        ],
      },
      {
        'title': 'Preferences',
        'icon': Icons.settings,
        'items': [
          {
            'title': 'Theme',
            'subtitle': _getThemeText(),
            'icon': _getThemeIcon(),
            'action': () => _showThemeDialog(context),
            'isTheme': true,
          },
          {
            'title': 'Notifications',
            'subtitle': 'Manage your notifications',
            'icon': Icons.notifications,
            'action': () => _showNotificationsDialog(context),
          },
          {
            'title': 'Updates',
            'subtitle': 'Check for updates',
            'icon': Icons.system_update,
            'action': () => _directToUpdates(context),
          },
        ],
      },
      {
        'title': 'Account Actions',
        'icon': Icons.security,
        'items': [
          {
            'title': 'Change Password',
            'subtitle': 'Update your password',
            'icon': Icons.lock,
            'action': () => _changePassword(context),
          },
          {
            'title': 'Sign Out',
            'subtitle': 'Sign out of your account',
            'icon': Icons.logout,
            'action': () => _showLogoutDialog(context),
            'isDestructive': true,
          },
        ],
      },
    ];

    return Column(
      children: settings.map((section) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      section['icon'] as IconData,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      section['title'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: (section['items'] as List<Map<String, dynamic>>)
                    .map((item) => _buildSettingsTile(item, isDark))
                    .toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingsTile(Map<String, dynamic> item, bool isDark) {
    final isDestructive = item['isDestructive'] == true;
    final isTheme = item['isTheme'] == true;

    return ListTile(
      onTap: item['action'] as VoidCallback?,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          item['icon'] as IconData,
          color: isDestructive ? Colors.red : Colors.blue,
          size: 20,
        ),
      ),
      title: Text(
        item['title'] as String,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive
              ? Colors.red
              : (isDark ? Colors.white : Colors.grey[800]),
        ),
      ),
      subtitle: item['subtitle'] != null
          ? Text(
              item['subtitle'] as String,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 13,
              ),
            )
          : null,
      trailing: isTheme
          ? ValueListenableBuilder(
              valueListenable: isDarkNotififier,
              builder: (context, isDarkMode, child) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getThemeText(),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            )
          : Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[400],
              size: 20,
            ),
    );
  }

  String _getThemeText() {
    return isDarkNotififier.value == null
        ? 'System'
        : isDarkNotififier.value!
            ? 'Dark'
            : 'Light';
  }

  IconData _getThemeIcon() {
    return isDarkNotififier.value == null
        ? Icons.brightness_auto
        : isDarkNotififier.value!
            ? Icons.dark_mode
            : Icons.light_mode;
  }

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Profile Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAvatarOption(Icons.camera_alt, 'Camera', () {}),
                _buildAvatarOption(Icons.photo_library, 'Gallery', () {}),
                _buildAvatarOption(Icons.delete, 'Remove', () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _editProfile(BuildContext context) {
    // Implement edit profile functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile feature coming soon!')),
    );
  }

  void _showEmailDialog(BuildContext context) {
    // Implement email change dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email change feature coming soon!')),
    );
  }

  void _showPhoneDialog(BuildContext context) {
    // Implement phone change dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone change feature coming soon!')),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool?>(
              title: const Text('System'),
              value: null,
              groupValue: isDarkNotififier.value,
              onChanged: (value) {
                isDarkNotififier.value = value;
                Navigator.pop(context);
              },
            ),
            RadioListTile<bool?>(
              title: const Text('Light'),
              value: false,
              groupValue: isDarkNotififier.value,
              onChanged: (value) {
                isDarkNotififier.value = value;
                Navigator.pop(context);
              },
            ),
            RadioListTile<bool?>(
              title: const Text('Dark'),
              value: true,
              groupValue: isDarkNotififier.value,
              onChanged: (value) {
                isDarkNotififier.value = value;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications settings coming soon!')),
    );
  }

  void _directToUpdates(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return const UpdatePage();
      },
    ));
  }

  void _changePassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password change feature coming soon!')),
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
}
