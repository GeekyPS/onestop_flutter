import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import 'package:shared_preferences/shared_preferences.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('A bg message just showed up :  ${message.messageId}');
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high,
      playSound: true);
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(channel.id, channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          playSound: true,
          icon: '@mipmap/ic_launcher');
  DarwinNotificationDetails iosNotificationDetails =
      const DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: iosNotificationDetails,
  );
  RemoteNotification? notification = message.notification;
  // String type = message.data['type'];
  print("NOTIFICation : $notification");
  if (checkNotificationCategory(message.data['category'])) {
    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.data['header'],
      message.data['body'],
      notificationDetails,
    );
  }
  saveNotification(message.data, message.sentTime);
}

@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  if (notificationResponse.payload != null) {
    print('notification payload: $payload');
  }
  // await Navigator.pushNamed(context, HomePage.id);
}

bool checkNotificationCategory(String type) {
  switch (type) {
    case "Lost":
    case "Found":
    case "Buy":
    case "Sell":
      return true;
  }
  return false;
}

Future<bool> checkForNotifications() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  String? token = sharedPreferences.getString("fcm-token");
  if (token == null) {
    token = await messaging.getToken();
    sharedPreferences.setString("fcm-token", token!);
  }
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()!
      .requestPermission();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high,
      playSound: true);
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    // onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    // onDidReceiveBackgroundNotificationResponse:
    //     onDidReceiveNotificationResponse,
  );
  AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(channel.id, channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          playSound: true,
          icon: '@mipmap/ic_launcher');
  DarwinNotificationDetails iosNotificationDetails =
      const DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: iosNotificationDetails,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    // try{
    //   String type = message.data['type'];
    // } catch(e){
    //   print(e);
    // }
    print("NOTIFICation : $notification");
    print("Message is ${message.category}");
    if (notification != null &&
        checkNotificationCategory(message.data['category'])) {
      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.data['header'],
        message.data['body'],
        notificationDetails,
      );
    }
    saveNotification(message.data, message.sentTime);
  });
  return true;
}

void saveNotification(
    Map<String, dynamic> notificationData, DateTime? sentTime) async {
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  notificationData['time'] = sentTime?.toString() ?? DateTime.now().toString();
  notificationData['read'] = false;
  String notifJson = jsonEncode(notificationData);
  print("data = $notificationData");
  List<String> notifications = preferences.getStringList('notifications') ?? [];
  if (notifications.length > 15) {
    notifications.removeAt(0);
  }
  notifications.add(notifJson);
  preferences.setStringList('notifications', notifications);
}
