import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/data/repositories/fcm_token_repository.dart';
import 'package:spare_kart/features/messages/chat_detail_screen.dart';
import 'package:spare_kart/firebase_options.dart';

typedef PushNavigateHandler = void Function(String route, {String? threadId});

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _channelId = 'sparekart_messages';
  static const _channelName = 'SpareKart Messages';

  late final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FcmTokenRepository _tokenRepository = FcmTokenRepository();

  StreamSubscription<String>? _tokenRefreshSub;
  String? _currentToken;
  String? _activeUserId;
  PushNavigateHandler? _onNavigate;
  bool _initialized = false;
  String? _pendingRoute;
  String? _pendingThreadId;

  Future<bool> bootstrap() async {
    if (_initialized) return true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _messaging = FirebaseMessaging.instance;
    } catch (error) {
      debugPrint('Firebase init failed: $error');
      return false;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'New chat messages from buyers and sellers',
      importance: Importance.high,
    );

    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);
    await android?.requestNotificationsPermission();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onRemoteMessageOpened);
    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_persistToken);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _scheduleNavigationFromMessage(initialMessage);
    }

    _initialized = true;
    return true;
  }

  void setNavigateHandler(PushNavigateHandler? handler) {
    _onNavigate = handler;
    _flushPendingNavigation();
  }

  Future<void> startForUser(String userId) async {
    if (!_initialized) {
      final ready = await bootstrap();
      if (!ready) return;
    }

    _activeUserId = userId;
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await _persistToken(token);
    }
  }

  Future<void> stopForUser() async {
    final token = _currentToken;
    _activeUserId = null;
    if (token != null) {
      try {
        await _tokenRepository.removeToken(token);
      } catch (_) {}
    }
    _currentToken = null;
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _onNavigate = null;
  }

  Future<void> _persistToken(String token) async {
    if (_activeUserId == null) return;
    _currentToken = token;
    try {
      await _tokenRepository.saveToken(token);
    } catch (error) {
      debugPrint('Failed to save FCM token: $error');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    final title = notification?.title ?? data['title'] ?? 'SpareKart';
    final body = notification?.body ?? data['body'] ?? '';
    if (body.isEmpty) return;

    unawaited(
      _localNotifications.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'New chat messages from buyers and sellers',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode({
          'route': data['route'] ?? AppRoutes.messages,
          'thread_id': data['thread_id'] ?? '',
          'type': data['type'] ?? 'message',
        }),
      ),
    );
  }

  void _onRemoteMessageOpened(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  void _scheduleNavigationFromMessage(RemoteMessage message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateFromData(message.data);
    });
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromData(
        data.map((key, value) => MapEntry(key, value?.toString() ?? '')),
      );
    } catch (_) {}
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final route = data['route'] as String? ?? AppRoutes.messages;
    final threadId = data['thread_id'] as String?;
    if (_onNavigate == null) {
      _pendingRoute = route;
      _pendingThreadId = threadId?.isNotEmpty == true ? threadId : null;
      return;
    }
    _onNavigate!.call(
      route,
      threadId: threadId?.isNotEmpty == true ? threadId : null,
    );
  }

  void _flushPendingNavigation() {
    final route = _pendingRoute;
    if (route == null || _onNavigate == null) return;
    final threadId = _pendingThreadId;
    _pendingRoute = null;
    _pendingThreadId = null;
    _onNavigate!.call(route, threadId: threadId);
  }

  void navigateFromHandler(
    BuildContext context, {
    required String route,
    String? threadId,
  }) {
    if (threadId != null) {
      Navigator.of(context).pushNamed(
        AppRoutes.chatDetail,
        arguments: ChatArgs(
          thread: MessageThread(
            id: threadId,
            participantName: '',
            lastMessage: '',
            timestamp: DateTime.now(),
            unreadCount: 0,
            partTitle: '',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(AppRoutes.messages);
  }
}
