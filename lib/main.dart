import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

const notificationChannelId = 'my_foreground';
const notificationId = 888;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeService();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update only if the location changes by 10 meters
      ),
    ).listen((val) {
      setState(() {
        latLong = '${val.latitude}, ${val.longitude}';
      });
    });
    super.initState();
  }

  String latLong = '';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Tracking',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Location Tracking'),
          actions: [
            IconButton(
                onPressed: () async {
                  final pos = await Geolocator.getCurrentPosition(
                    locationSettings: const LocationSettings(
                      accuracy: LocationAccuracy.high,
                      distanceFilter:
                          10, // Update only if the location changes by 10 meters
                    ),
                  );
                  setState(() {
                    latLong = '${pos.latitude}, ${pos.longitude}';
                  });
                },
                icon: Icon(Icons.refresh))
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Current location : $latLong'),
              Text('Date & Time : ${DateTime.now().toIso8601String()}')
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId, // id
    'MY FOREGROUND SERVICE', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.high, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      // foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
        autoStart: true,
        onBackground: (val) {
          return true;
        },
        onForeground: (val) {}),
  );
}

void onStart(ServiceInstance service) async {
  await requestLocationPermission();
}

Future<String> getDeviceId() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String deviceId = "Unknown";

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceId = androidInfo.id ?? "Unknown"; // Unique Android ID
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    deviceId = iosInfo.identifierForVendor ?? "Unknown"; // Unique iOS ID
  }

  return deviceId.replaceAll('.', '');
}

Future<void> requestLocationPermission() async {
  if (await Permission.location.isGranted) {
    startService();
  } else {
    PermissionStatus status = await Permission.location.request();
    if (status.isGranted) {
      startService();
    } else {
      openAppSettings();
    }
  }
}

void startService() async {
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDGYSmXVTx-uv3KyffJ5vlze5uCnnD21aM",
      appId: "1:1013607028438:android:5065ed5ba05b782abc9b77",
      messagingSenderId: "1013607028438",
      projectId: "tracking-4d69b",
      storageBucket: 'tracking-4d69b.firebasestorage.app',
      databaseURL: "https://tracking-4d69b-default-rtdb.firebaseio.com",
    ),
  );

  final positionStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update only if the location changes by 10 meters
    ),
  );
  final databaseRef = FirebaseDatabase.instance.ref('user');
  final deviceId = await getDeviceId();

  Position? lastRecordedPosition;
  DateTime? lastUpdateTime;

  positionStream.listen((Position position) async {
    double latitude = position.latitude;
    double longitude = position.longitude;
    DateTime currentTime = DateTime.now();

    // Calculate distance from the last recorded location
    double distance = lastRecordedPosition != null
        ? Geolocator.distanceBetween(
            lastRecordedPosition!.latitude,
            lastRecordedPosition!.longitude,
            latitude,
            longitude,
          )
        : double.infinity;

    // Calculate time difference in minutes
    int timeDifference = lastUpdateTime != null
        ? currentTime.difference(lastUpdateTime!).inMinutes
        : 5; // Default to 5 minutes for the first update

    // Check if either condition (50 meters or 5 minutes) is met
    if (distance >= 50 || timeDifference >= 5) {
      String timestamp = currentTime.toIso8601String();

      // Update current location
      await databaseRef.child(deviceId).child("current_location").set({
        'device_id': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
      });

      // Push to past locations
      await databaseRef.child(deviceId).child("past_locations").push().set({
        'device_id': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
      });

      // Update last recorded position and time
      lastRecordedPosition = position;
      lastUpdateTime = currentTime;
    }
  });
}
