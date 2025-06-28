import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionService {
  static Future<String?> getLatestGitHubVersion({
    required String owner,
    required String repo,
  }) async {
    final url =
        Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['tag_name'] as String?;
    }
    return null;
  }

  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}
