import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../config/globals.dart';
import 'secure_storage_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    // 1. Minta izin notifikasi eksplisit untuk Android 13+ & iOS
    try {
      await Permission.notification.request();
    } catch (_) {}

    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 2. Buat saluran notifikasi Android berprioritas tinggi
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'desa_channel',
      'Notifikasi Desa Rambipuji',
      description: 'Saluran notifikasi pengajuan surat dan informasi Desa Rambipuji',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Inisialisasi plugin notifikasi lokal
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!);
            handleNotificationNavigation(data);
          } catch (_) {}
        }
      },
    );

    // 4. Tangani notifikasi saat aplikasi sedang AKTIF / TERBUKA (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotif.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 5. Tangani ketika notifikasi diklik saat aplikasi di BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationNavigation(message.data);
    });

    // 6. Tangani ketika notifikasi diklik saat aplikasi dalam kondisi MATI (Terminated)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      handleNotificationNavigation(initialMessage.data);
    }

    // 7. Listener saat FCM token berganti secara berkala
    _fcm.onTokenRefresh.listen((newToken) {
      syncTokenToBackend(overrideToken: newToken);
    });

    // 8. Langsung coba sync token saat inisialisasi jika sudah ada data akun
    syncTokenToBackend();
  }

  /// Sinkronkan FCM Token perangkat ini ke Backend Laravel
  Future<void> syncTokenToBackend({String? overrideToken}) async {
    try {
      String? token = overrideToken ?? await _fcm.getToken();
      String? authToken = await SecureStorageService.instance.getToken();
      String? nik = await SecureStorageService.instance.getNik();

      if (token == null || token.isEmpty) {
        return;
      }

      // Pastikan ada token auth atau NIK untuk mengenali pengguna
      if ((authToken == null || authToken.isEmpty) && (nik == null || nik.isEmpty)) {
        return;
      }

      final url = Uri.parse('$baseURL/update-fcm-token');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final body = <String, dynamic>{
        'fcm_token': token,
        if (nik != null && nik.isNotEmpty) 'nik': nik,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      debugPrint('🔔 [FCM] Sync Token Status: ${response.statusCode}');
    } catch (e) {
      debugPrint('🔔 [FCM] Sync Token Error: $e');
    }
  }

  /// Navigasi cerdas ke halaman tujuan sesuai payload data notifikasi
  void handleNotificationNavigation(Map<String, dynamic> data) async {
    String? screen = data['screen'];
    String role = await SecureStorageService.instance.getRole();

    // Pastikan navigator siap
    if (navigatorKey.currentState == null) return;

    if (screen == 'kadus_surat_masuk' && role == 'kepala_dusun') {
      // Halaman Kadus
    } else if (screen == 'sekdes_surat_masuk' && role == 'sekretaris_desa') {
      // Halaman Sekdes
    } else if (screen == 'kades_surat_masuk' && role == 'kepala_desa') {
      // Halaman Kades
    }
  }
}

