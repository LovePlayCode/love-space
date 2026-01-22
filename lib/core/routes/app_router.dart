import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/moment_detail_screen.dart';
import '../../screens/album/system_album_screen.dart';
import '../../screens/album/system_photo_detail_screen.dart';
import '../../screens/album/media_picker_screen.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../screens/calendar/daily_detail_screen.dart';
import '../../screens/calendar/daily_view_screen.dart';
import '../../screens/anniversary/anniversary_screen.dart';
import '../../screens/anniversary/anniversary_edit_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/profile_edit_screen.dart';
import '../../widgets/common/main_scaffold.dart';

/// 路由路径常量
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String momentDetail = '/moment/:id';
  static const String album = '/album';
  static const String photoDetail = '/album/photo/:id';
  static const String mediaPicker = '/media-picker';
  static const String calendar = '/calendar';
  static const String dailyView = '/calendar/day/:date';
  static const String dailyEdit = '/calendar/day/:date/edit';
  static const String anniversary = '/anniversary';
  static const String anniversaryEdit = '/anniversary/edit';
  static const String anniversaryAdd = '/anniversary/add';
  static const String settings = '/settings';
  static const String profileEdit = '/settings/profile';
}

/// 应用路由配置
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      // 底部导航栏 Shell - 4个tab: 首页、日历、纪念日、设置
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CalendarScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.anniversary,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnniversaryScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // 独立页面（不带底部导航栏）
      GoRoute(
        path: AppRoutes.momentDetail,
        builder: (context, state) {
          final idStr = state.pathParameters['id'] ?? '0';
          final id = int.tryParse(idStr) ?? 0;
          return MomentDetailScreen(mediaId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.album,
        builder: (context, state) => const SystemAlbumScreen(),
      ),
      GoRoute(
        path: AppRoutes.photoDetail,
        builder: (context, state) {
          // ID 可能被 URL 编码，需要解码
          final encodedId = state.pathParameters['id'] ?? '';
          final id = Uri.decodeComponent(encodedId);
          return SystemPhotoDetailScreen(assetId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.mediaPicker,
        builder: (context, state) => const MediaPickerScreen(),
      ),
      GoRoute(
        path: AppRoutes.dailyView,
        builder: (context, state) {
          final dateStr = state.pathParameters['date'] ?? '';
          return DailyViewScreen(dateStr: dateStr);
        },
      ),
      GoRoute(
        path: AppRoutes.dailyEdit,
        builder: (context, state) {
          final dateStr = state.pathParameters['date'] ?? '';
          return DailyDetailScreen(dateStr: dateStr);
        },
      ),
      GoRoute(
        path: AppRoutes.anniversaryAdd,
        builder: (context, state) => const AnniversaryEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.anniversaryEdit,
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return AnniversaryEditScreen(anniversaryId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (context, state) => const ProfileEditScreen(),
      ),
    ],
  );
}
