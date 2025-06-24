
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

List devColor = [
  OnlineStatus(),
  OfflineStatus(),
];

class OnlineStatus {
  static const onlineIcon = Colors.lightGreen;
  static const onlineText = 'Online';
}

class OfflineStatus {
  static const offlineIcon = Colors.redAccent;
  static const offlineText = 'Offline';
}

class DevicesPage extends StatelessWidget {
  const DevicesPage(
      {super.key,});
      // required Null Function(dynamic deviceId, dynamic deviceName)
      //     onDeviceSelected});

  @override
  Widget build(BuildContext context) {
    final items = const {'Devices': 2, 'Active': 7, 'Offline': 4};
    String qrData = 'CC:7B:5C:F1:9C:4A';

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height * 0.1,
              margin: EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 39, 147, 115),
                      const Color.fromARGB(255, 32, 69, 33),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  items.length,
                  (index) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        items.keys.elementAt(index),
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        items.values.elementAt(index).toString(),
                        style: TextStyle(
                            fontSize: 30.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            title: Text('Devices'),
            trailing: TextButton.icon(
              icon: Icon(Icons.sort),
              onPressed: () {},
              label: Text('Filter'),
            ),
          ),
          Column(
            children: [
              ...List.generate(
                devColor.length,
                (index) {
                  return ListTile(
                    contentPadding: EdgeInsets.only(left: 16, right: 0),
                    leading: Icon(Icons.devices),
                    title: Text('Device ${index + 1}'),
                    subtitle: Text('MAC Address'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.circle),
                          iconAlignment: IconAlignment.end,
                          label: Text(index == 0
                              ? OnlineStatus.onlineText
                              : OfflineStatus.offlineText),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            iconColor: index == 0
                                ? OnlineStatus.onlineIcon
                                : OfflineStatus.offlineIcon,
                            foregroundColor: index == 0
                                ? OnlineStatus.onlineIcon
                                : OfflineStatus.offlineIcon,
                          ),
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) {
                            return [
                              PopupMenuItem(
                                onTap: () {
                                  // Show dialog before navigation
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Share Device'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(qrData),
                                            // ignore: non_const_call_to_literal_constructor
                                            PrettyQrView.data(
                                                data: qrData,
                                                decoration: PrettyQrDecoration(
                                                  background: Colors.white,
                                                )),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Text("Share"),
                              ),
                              PopupMenuItem(
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
            ],
          )
        ],
      ),
    );
  }
}
