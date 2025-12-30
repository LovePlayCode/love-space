import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// 恋爱主题标签图标配置
class TagIcons {
  TagIcons._();

  /// 预设的恋爱主题图标列表
  /// key: 图标代码（存储在数据库）
  /// value: 图标数据
  static const Map<String, TagIconData> presetIcons = {
    // 爱情相关
    'heart': TagIconData(icon: FontAwesomeIcons.heart, label: '爱心'),
    'heart_solid': TagIconData(icon: FontAwesomeIcons.solidHeart, label: '实心爱心'),
    'heart_pulse': TagIconData(icon: FontAwesomeIcons.heartPulse, label: '心跳'),
    'heart_circle': TagIconData(icon: FontAwesomeIcons.heartCircleCheck, label: '爱心勾选'),
    'kiss': TagIconData(icon: FontAwesomeIcons.faceKiss, label: '亲吻'),
    'kiss_heart': TagIconData(icon: FontAwesomeIcons.faceKissWinkHeart, label: '飞吻'),
    'hug': TagIconData(icon: FontAwesomeIcons.handHoldingHeart, label: '捧心'),
    'hands_holding': TagIconData(icon: FontAwesomeIcons.handsHolding, label: '双手'),
    
    // 约会相关
    'calendar': TagIconData(icon: FontAwesomeIcons.calendarDays, label: '日历'),
    'clock': TagIconData(icon: FontAwesomeIcons.clock, label: '时钟'),
    'location': TagIconData(icon: FontAwesomeIcons.locationDot, label: '位置'),
    'map': TagIconData(icon: FontAwesomeIcons.mapLocationDot, label: '地图'),
    'plane': TagIconData(icon: FontAwesomeIcons.plane, label: '飞机'),
    'car': TagIconData(icon: FontAwesomeIcons.car, label: '汽车'),
    'train': TagIconData(icon: FontAwesomeIcons.train, label: '火车'),
    
    // 美食相关
    'utensils': TagIconData(icon: FontAwesomeIcons.utensils, label: '餐具'),
    'cake': TagIconData(icon: FontAwesomeIcons.cakeCandles, label: '蛋糕'),
    'wine': TagIconData(icon: FontAwesomeIcons.wineGlass, label: '红酒'),
    'champagne': TagIconData(icon: FontAwesomeIcons.champagneGlasses, label: '香槟'),
    'coffee': TagIconData(icon: FontAwesomeIcons.mugHot, label: '咖啡'),
    'ice_cream': TagIconData(icon: FontAwesomeIcons.iceCream, label: '冰淇淋'),
    'pizza': TagIconData(icon: FontAwesomeIcons.pizzaSlice, label: '披萨'),
    
    // 娱乐相关
    'film': TagIconData(icon: FontAwesomeIcons.film, label: '电影'),
    'music': TagIconData(icon: FontAwesomeIcons.music, label: '音乐'),
    'headphones': TagIconData(icon: FontAwesomeIcons.headphones, label: '耳机'),
    'gamepad': TagIconData(icon: FontAwesomeIcons.gamepad, label: '游戏'),
    'book': TagIconData(icon: FontAwesomeIcons.book, label: '书籍'),
    'camera': TagIconData(icon: FontAwesomeIcons.camera, label: '相机'),
    'video': TagIconData(icon: FontAwesomeIcons.video, label: '视频'),
    
    // 礼物相关
    'gift': TagIconData(icon: FontAwesomeIcons.gift, label: '礼物'),
    'ring': TagIconData(icon: FontAwesomeIcons.ring, label: '戒指'),
    'gem': TagIconData(icon: FontAwesomeIcons.gem, label: '宝石'),
    'crown': TagIconData(icon: FontAwesomeIcons.crown, label: '皇冠'),
    'star': TagIconData(icon: FontAwesomeIcons.star, label: '星星'),
    'star_solid': TagIconData(icon: FontAwesomeIcons.solidStar, label: '实心星星'),
    'sparkles': TagIconData(icon: FontAwesomeIcons.wandMagicSparkles, label: '闪光'),
    
    // 自然相关
    'sun': TagIconData(icon: FontAwesomeIcons.sun, label: '太阳'),
    'moon': TagIconData(icon: FontAwesomeIcons.moon, label: '月亮'),
    'cloud': TagIconData(icon: FontAwesomeIcons.cloud, label: '云朵'),
    'rainbow': TagIconData(icon: FontAwesomeIcons.rainbow, label: '彩虹'),
    'snowflake': TagIconData(icon: FontAwesomeIcons.snowflake, label: '雪花'),
    'leaf': TagIconData(icon: FontAwesomeIcons.leaf, label: '树叶'),
    'seedling': TagIconData(icon: FontAwesomeIcons.seedling, label: '幼苗'),
    'tree': TagIconData(icon: FontAwesomeIcons.tree, label: '树木'),
    
    // 宠物相关
    'paw': TagIconData(icon: FontAwesomeIcons.paw, label: '爪印'),
    'dog': TagIconData(icon: FontAwesomeIcons.dog, label: '狗狗'),
    'cat': TagIconData(icon: FontAwesomeIcons.cat, label: '猫咪'),
    'fish': TagIconData(icon: FontAwesomeIcons.fish, label: '鱼'),
    'dove': TagIconData(icon: FontAwesomeIcons.dove, label: '鸽子'),
    'feather': TagIconData(icon: FontAwesomeIcons.feather, label: '羽毛'),
    
    // 运动相关
    'dumbbell': TagIconData(icon: FontAwesomeIcons.dumbbell, label: '健身'),
    'bicycle': TagIconData(icon: FontAwesomeIcons.bicycle, label: '自行车'),
    'person_running': TagIconData(icon: FontAwesomeIcons.personRunning, label: '跑步'),
    'person_swimming': TagIconData(icon: FontAwesomeIcons.personSwimming, label: '游泳'),
    'person_hiking': TagIconData(icon: FontAwesomeIcons.personHiking, label: '徒步'),
    'mountain': TagIconData(icon: FontAwesomeIcons.mountain, label: '山峰'),
    'umbrella_beach': TagIconData(icon: FontAwesomeIcons.umbrellaBeach, label: '海滩'),
    
    // 家居相关
    'house': TagIconData(icon: FontAwesomeIcons.house, label: '房子'),
    'couch': TagIconData(icon: FontAwesomeIcons.couch, label: '沙发'),
    'bed': TagIconData(icon: FontAwesomeIcons.bed, label: '床'),
    'bath': TagIconData(icon: FontAwesomeIcons.bath, label: '浴缸'),
    'kitchen': TagIconData(icon: FontAwesomeIcons.kitchenSet, label: '厨房'),
    
    // 表情相关
    'smile': TagIconData(icon: FontAwesomeIcons.faceSmile, label: '微笑'),
    'laugh': TagIconData(icon: FontAwesomeIcons.faceLaughBeam, label: '大笑'),
    'grin_hearts': TagIconData(icon: FontAwesomeIcons.faceGrinHearts, label: '花痴'),
    'blush': TagIconData(icon: FontAwesomeIcons.faceFlushed, label: '害羞'),
    'sad': TagIconData(icon: FontAwesomeIcons.faceSadTear, label: '难过'),
    'surprise': TagIconData(icon: FontAwesomeIcons.faceSurprise, label: '惊讶'),
    
    // 其他
    'bell': TagIconData(icon: FontAwesomeIcons.bell, label: '铃铛'),
    'bookmark': TagIconData(icon: FontAwesomeIcons.bookmark, label: '书签'),
    'flag': TagIconData(icon: FontAwesomeIcons.flag, label: '旗帜'),
    'tag': TagIconData(icon: FontAwesomeIcons.tag, label: '标签'),
    'fire': TagIconData(icon: FontAwesomeIcons.fire, label: '火焰'),
    'bolt': TagIconData(icon: FontAwesomeIcons.bolt, label: '闪电'),
    'infinity': TagIconData(icon: FontAwesomeIcons.infinity, label: '无限'),
  };

  /// 获取图标
  static IconData? getIcon(String? iconCode) {
    if (iconCode == null) return null;
    return presetIcons[iconCode]?.icon;
  }

  /// 获取图标标签
  static String? getLabel(String? iconCode) {
    if (iconCode == null) return null;
    return presetIcons[iconCode]?.label;
  }

  /// 获取所有图标代码列表
  static List<String> get allIconCodes => presetIcons.keys.toList();

  /// 按分类获取图标
  static Map<String, List<String>> get iconsByCategory => {
    '爱情': ['heart', 'heart_solid', 'heart_pulse', 'heart_circle', 'kiss', 'kiss_heart', 'hug', 'hands_holding'],
    '约会': ['calendar', 'clock', 'location', 'map', 'plane', 'car', 'train'],
    '美食': ['utensils', 'cake', 'wine', 'champagne', 'coffee', 'ice_cream', 'pizza'],
    '娱乐': ['film', 'music', 'headphones', 'gamepad', 'book', 'camera', 'video'],
    '礼物': ['gift', 'ring', 'gem', 'crown', 'star', 'star_solid', 'sparkles'],
    '自然': ['sun', 'moon', 'cloud', 'rainbow', 'snowflake', 'leaf', 'seedling', 'tree'],
    '宠物': ['paw', 'dog', 'cat', 'fish', 'dove', 'feather'],
    '运动': ['dumbbell', 'bicycle', 'person_running', 'person_swimming', 'person_hiking', 'mountain', 'umbrella_beach'],
    '家居': ['house', 'couch', 'bed', 'bath', 'kitchen'],
    '表情': ['smile', 'laugh', 'grin_hearts', 'blush', 'sad', 'surprise'],
    '其他': ['bell', 'bookmark', 'flag', 'tag', 'fire', 'bolt', 'infinity'],
  };
}

/// 图标数据
class TagIconData {
  final IconData icon;
  final String label;

  const TagIconData({
    required this.icon,
    required this.label,
  });
}
