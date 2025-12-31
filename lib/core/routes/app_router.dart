import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/album/album_screen.dart';
import '../../screens/album/photo_detail_screen.dart';
import '../../screens/album/media_picker_screen.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../screens/calendar/daily_detail_screen.dart';
import '../../screens/anniversary/anniversary_screen.dart';
import '../../screens/anniversary/anniversary_edit_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/profile_edit_screen.dart';
import '../../widgets/common/main_scaffold.dart';

/// 路由路径常量
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String album = '/album';
  static const String photoDetail = '/album/photo/:id';
  static const String mediaPicker = '/album/picker';
  static const String calendar = '/calendar';
  static const String dailyDetail = '/calendar/day/:date';
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
      // 底部导航栏 Shell
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
            path: AppRoutes.album,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AlbumScreen(),
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
        ],
      ),

      // 独立页面（不带底部导航栏）
      GoRoute(
        path: AppRoutes.photoDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PhotoDetailScreen(photoId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.mediaPicker,
        builder: (context, state) => const MediaPickerScreen(),
      ),
      GoRoute(
        path: AppRoutes.dailyDetail,
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
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (context, state) => const ProfileEditScreen(),
      ),
    ],
  );
}
