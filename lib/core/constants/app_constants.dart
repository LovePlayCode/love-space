/// LoveSpace 应用常量配置
class AppConstants {
  AppConstants._();

  // 应用信息
  static const String appName = 'LoveSpace';
  static const String appVersion = '1.0.0';

  // 数据库
  static const String databaseName = 'love_space.db';
  static const int databaseVersion = 7;

  // SharedPreferences Keys
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyMyNickname = 'my_nickname';
  static const String keyPartnerNickname = 'partner_nickname';
  static const String keyMyAvatar = 'my_avatar';
  static const String keyPartnerAvatar = 'partner_avatar';
  static const String keyStartDate = 'start_date';
  static const String keyThemeColor = 'theme_color';

  // 文件目录
  static const String imageDirectory = 'images';
  static const String videoDirectory = 'videos';
  static const String thumbnailDirectory = 'thumbnails';
  static const String livePhotoDirectory = 'live_photos';
  static const String backupDirectory = 'backups';

  // 媒体类型
  static const int mediaTypeImage = 0;
  static const int mediaTypeVideo = 1;
  static const int mediaTypeLivePhoto = 2;

  // 默认值
  static const String defaultMyNickname = '我';
  static const String defaultPartnerNickname = 'TA';

  // 心情图标
  static const Map<String, String> moodEmojis = {
    'happy': '😊',
    'love': '🥰',
    'excited': '🤩',
    'sad': '😢',
    'angry': '😠',
    'neutral': '😐',
    'tired': '😴',
    'surprised': '😲',
  };

  // 纪念日类型
  static const Map<String, String> anniversaryTypes = {
    'together': '在一起',
    'birthday': '生日',
    'first_meet': '初次相遇',
    'first_date': '第一次约会',
    'first_kiss': '初吻',
    'proposal': '求婚',
    'wedding': '结婚',
    'travel': '旅行',
    'custom': '自定义',
  };

  // 纪念日图标
  static const Map<String, String> anniversaryIcons = {
    'together': '💑',
    'birthday': '🎂',
    'first_meet': '👋',
    'first_date': '🌹',
    'first_kiss': '💋',
    'proposal': '💍',
    'wedding': '👰',
    'travel': '✈️',
    'custom': '💝',
  };
}
