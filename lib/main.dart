import 'dart:async';

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/inspection_store.dart';
import 'services/ads/app_open_ad_service.dart';
import 'services/ads/rewarded_ad_service.dart';
import 'services/device/device_info_controller.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PhoneCheckApp());
}

class PhoneCheckApp extends StatefulWidget {
  const PhoneCheckApp({super.key});
  @override
  State<PhoneCheckApp> createState() => _PhoneCheckAppState();
}

class _PhoneCheckAppState extends State<PhoneCheckApp> {
  final InspectionStore store = InspectionStore();
  final DeviceInfoController deviceInfo = DeviceInfoController();
  final AppOpenAdService appOpenAds = AppOpenAdService();
  @override
  void initState() {
    super.initState();
    deviceInfo.load();
    store.loadReports().catchError((Object _) {});
    appOpenAds.initialize();
    unawaited(RewardedAdService.instance.preload());
  }

  @override
  void dispose() {
    store.dispose();
    deviceInfo.dispose();
    appOpenAds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InspectionScope(
    notifier: store,
    child: DeviceInfoScope(
      notifier: deviceInfo,
      child: MaterialApp(
        title: 'PhoneCheck',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: SplashScreen(onComplete: appOpenAds.showOnLaunch),
      ),
    ),
  );
}

class DeviceInfoScope extends InheritedNotifier<DeviceInfoController> {
  const DeviceInfoScope({
    super.key,
    required super.notifier,
    required super.child,
  });
  static DeviceInfoController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DeviceInfoScope>()!.notifier!;
}

class InspectionScope extends InheritedNotifier<InspectionStore> {
  const InspectionScope({
    super.key,
    required super.notifier,
    required super.child,
  });
  static InspectionStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InspectionScope>()!.notifier!;
}
