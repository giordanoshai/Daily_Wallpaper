import 'dart:convert';
import 'package:http/http.dart' as http;

/// Bing 壁纸数据模型
class BingWallpaperItem {
  final String title;
  final String copyright;
  final String copyrightLink;
  final String imageUrl; // 默认使用适配手机竖屏的 1080x1920 分辨率
  final String uhdUrl; // 4K 超清原图
  final String standardUrl; // 原始横屏 1920x1080
  final String startDate;

  BingWallpaperItem({
    required this.title,
    required this.copyright,
    required this.copyrightLink,
    required this.imageUrl,
    required this.uhdUrl,
    required this.standardUrl,
    required this.startDate,
  });

  factory BingWallpaperItem.fromJson(Map<String, dynamic> json) {
    const String host = 'https://cn.bing.com';
    final String urlbase = json['urlbase'] ?? '';
    final String rawUrl = json['url'] ?? '';

    // 优先提供手机竖屏专版壁纸（1080x1920），若无 urlbase 则回退到原始 url
    final String portraitUrl = urlbase.isNotEmpty ? '$host${urlbase}_1080x1920.jpg' : '$host$rawUrl';
    final String uhdUrl = urlbase.isNotEmpty ? '$host${urlbase}_UHD.jpg' : '$host$rawUrl';
    final String standardUrl = '$host$rawUrl';

    return BingWallpaperItem(
      title: json['title'] ?? '',
      copyright: json['copyright'] ?? '',
      copyrightLink: json['copyrightlink'] ?? '',
      imageUrl: portraitUrl,
      uhdUrl: uhdUrl,
      standardUrl: standardUrl,
      startDate: json['startdate'] ?? '',
    );
  }
}

/// 微软 Bing 官方壁纸获取服务（免自建服务器，直接由客户端直连微软官方 CDN）
class BingWallpaperService {
  static const String _apiEndpoint = 'https://cn.bing.com/HPImageArchive.aspx';

  /// 获取指定天数范围内的 Bing 壁纸（微软官方单次最多支持获取 8 张）
  /// [count] 获取张数（1~8）
  /// [dayOffset] 偏移天数（0 表示今天，1 表示昨天，以此类推）
  static Future<List<BingWallpaperItem>> fetchWallpapers({
    int count = 8,
    int dayOffset = 0,
  }) async {
    final uri = Uri.parse('$_apiEndpoint?format=js&idx=$dayOffset&n=$count&mkt=zh-CN');
    final response = await http.get(uri).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('请求超时，请检查网络连接'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic>? images = data['images'];
      if (images != null && images.isNotEmpty) {
        return images.map((item) => BingWallpaperItem.fromJson(item)).toList();
      }
      throw Exception('未获取到壁纸数据');
    } else {
      throw Exception('获取壁纸失败，状态码: ${response.statusCode}');
    }
  }

  /// 获取微软官方支持的最大历史壁纸（通过并发请求合并最近两周约 16 张壁纸并去重）
  static Future<List<BingWallpaperItem>> fetchAllRecentWallpapers() async {
    final results = await Future.wait([
      fetchWallpapers(count: 8, dayOffset: 0),
      fetchWallpapers(count: 8, dayOffset: 7),
    ]);

    final Map<String, BingWallpaperItem> uniqueMap = {};
    for (final list in results) {
      for (final item in list) {
        uniqueMap[item.startDate] = item;
      }
    }

    final combined = uniqueMap.values.toList();
    // 按日期倒序排序（最新在最前）
    combined.sort((a, b) => b.startDate.compareTo(a.startDate));
    return combined;
  }
}
