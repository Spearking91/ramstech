class WifiCredentials {
  String ssid;
  String password;

  WifiCredentials({required this.ssid, required this.password});

  bool validate() {
    return ssid.isNotEmpty && password.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'password': password,
    };
  }

  static WifiCredentials fromJson(Map<String, dynamic> json) {
    return WifiCredentials(
      ssid: json['ssid'],
      password: json['password'],
    );
  }
}