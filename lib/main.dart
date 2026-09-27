import 'package:flutter/material.dart';
import 'package:image_fade/image_fade.dart';
import 'package:gal/gal.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'bing_wallpaper_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '简纸',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '简纸'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 壁纸数据列表与当前索引
  List<BingWallpaperItem> _wallpapers = [];
  int _currentIndex = 0;

  // 加载与状态管理
  bool _isLoading = true;
  String? _errorMessage;

  // 手势滑动检测
  double _initialPosition = 0.0;
  double _lastPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchBingWallpapers();
  }

  /// 直接从微软 Bing 官方拉取每日壁纸（免自建服务器）
  Future<void> _fetchBingWallpapers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await BingWallpaperService.fetchAllRecentWallpapers();
      if (!mounted) return;
      setState(() {
        _wallpapers = list;
        _currentIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      _showToast('壁纸加载失败: $_errorMessage');
    }
  }

  /// 获取当前显示的壁纸对象
  BingWallpaperItem? get _currentWallpaper {
    if (_wallpapers.isEmpty || _currentIndex >= _wallpapers.length) {
      return null;
    }
    return _wallpapers[_currentIndex];
  }

  /// 切换到上一张壁纸
  void _prevWallpaper() {
    if (_wallpapers.isEmpty) return;
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
      } else {
        _currentIndex = _wallpapers.length - 1; // 循环切换
      }
    });
  }

  /// 切换到下一张壁纸
  void _nextWallpaper() {
    if (_wallpapers.isEmpty) return;
    setState(() {
      if (_currentIndex < _wallpapers.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0; // 循环切换
      }
    });
  }

  /// 随机切换一张壁纸
  void _randomWallpaper() {
    if (_wallpapers.length <= 1) {
      _fetchBingWallpapers();
      return;
    }
    final nextIndex = (_currentIndex + 1) % _wallpapers.length;
    setState(() {
      _currentIndex = nextIndex;
    });
  }

  /// 统一轻提示 SnackBar
  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15.0, color: Colors.white),
        ),
        backgroundColor: const Color(0xD9000000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 保存图片到本地相册
  Future<void> _downloadImage() async {
    final wallpaper = _currentWallpaper;
    if (wallpaper == null) {
      _showToast('暂无壁纸可保存');
      return;
    }

    try {
      _showToast('正在下载高清壁纸...');
      // 优先保存 4K 超清原图（uhdUrl），若无则保存默认高清竖屏图
      final saveUrl = wallpaper.uhdUrl.isNotEmpty ? wallpaper.uhdUrl : wallpaper.imageUrl;
      final file = await DefaultCacheManager().getSingleFile(saveUrl);

      // 请求相册访问权限并保存到相册
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final request = await Gal.requestAccess();
        if (!request) {
          _showToast('未获得相册权限，无法保存');
          return;
        }
      }

      await Gal.putImage(file.path, album: 'DailyWallpaper');
      _showToast('保存成功，已存入相册');
    } catch (e) {
      _showToast('保存出错: $e');
    }
  }

  /// 设置壁纸通用方法
  Future<void> _setWallpaper(int location, String targetName) async {
    final wallpaper = _currentWallpaper;
    if (wallpaper == null) {
      _showToast('暂无壁纸可设置');
      return;
    }

    _showToast('正在下载并设置$targetName...');
    try {
      // 使用竖屏版或高清原图缓存
      final file = await DefaultCacheManager().getSingleFile(wallpaper.imageUrl);
      final bool result = await WallpaperManager.setWallpaperFromFile(file.path, location);
      if (result) {
        _showToast('$targetName设置成功！');
      } else {
        _showToast('$targetName设置失败');
      }
    } catch (e) {
      _showToast('设置壁纸异常: $e');
    }
  }

  /// 弹出设置壁纸菜单
  void _showSetWallpaperMenu(Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx - 180,
        position.dy - 160,
        position.dx,
        position.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: const Color(0xFF1E1E1E),
      items: [
        PopupMenuItem<String>(
          onTap: () => _setWallpaper(WallpaperManager.HOME_SCREEN, '桌面壁纸'),
          child: const Row(
            children: [
              Icon(Icons.home, color: Colors.lightBlueAccent, size: 20),
              SizedBox(width: 12),
              Text('设为桌面', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          onTap: () => _setWallpaper(WallpaperManager.LOCK_SCREEN, '锁屏壁纸'),
          child: const Row(
            children: [
              Icon(Icons.lock, color: Colors.orangeAccent, size: 20),
              SizedBox(width: 12),
              Text('设为锁屏', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          onTap: () => _setWallpaper(WallpaperManager.BOTH_SCREEN, '桌面与锁屏壁纸'),
          child: const Row(
            children: [
              Icon(Icons.smartphone, color: Colors.greenAccent, size: 20),
              SizedBox(width: 12),
              Text('同时设为桌面和锁屏', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallpaper = _currentWallpaper;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 8, color: Colors.black87),
            ],
          ),
        ),
        actions: [
          if (_wallpapers.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: const Color(0x66000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${_wallpapers.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          // 核心壁纸展示与滑动手势
          Positioned.fill(
            child: GestureDetector(
              onPanDown: (details) {
                _initialPosition = details.localPosition.dy;
              },
              onPanUpdate: (details) {
                _lastPosition = details.localPosition.dy;
              },
              onPanEnd: (details) {
                final double distance = _initialPosition - _lastPosition;
                // 滑动距离超过 40 触发切图
                if (distance > 40) {
                  // 上滑：切换到上一张（前一天）
                  _prevWallpaper();
                } else if (distance < -40) {
                  // 下滑：切换到下一张
                  _nextWallpaper();
                }
              },
              child: Container(
                color: Colors.black,
                child: _buildWallpaperContent(wallpaper),
              ),
            ),
          ),

          // 底部阴影遮罩（增强文字与图标可读性）
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 240,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black87,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 底部壁纸版权与标题信息
          Positioned(
            bottom: 24.0,
            left: 20.0,
            right: 76.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (wallpaper != null && wallpaper.title.isNotEmpty) ...[
                  Text(
                    wallpaper.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4.0, color: Colors.black)],
                    ),
                  ),
                  const SizedBox(height: 6.0),
                ],
                Text(
                  wallpaper?.copyright.isNotEmpty == true
                      ? wallpaper!.copyright
                      : (_isLoading ? '壁纸正在加载中...' : '暂无版权说明'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w300,
                    height: 1.3,
                    shadows: [Shadow(blurRadius: 4.0, color: Colors.black)],
                  ),
                ),
                const SizedBox(height: 6.0),
                const Row(
                  children: [
                    Icon(Icons.swipe_vertical, color: Colors.white38, size: 16),
                    SizedBox(width: 6),
                    Text(
                      '上下滑动切换壁纸',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 右侧快捷操作按钮（刷新/随机、保存、设为壁纸）
          Positioned(
            bottom: 24.0,
            right: 14.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 刷新/随机按钮
                FloatingActionButton.small(
                  heroTag: 'fab_refresh',
                  onPressed: _isLoading ? null : _randomWallpaper,
                  backgroundColor: const Color(0x40FFFFFF),
                  elevation: 0,
                  tooltip: '切换壁纸',
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
                const SizedBox(height: 12),

                // 保存到相册
                FloatingActionButton.small(
                  heroTag: 'fab_save',
                  onPressed: _isLoading ? null : _downloadImage,
                  backgroundColor: const Color(0x40FFFFFF),
                  elevation: 0,
                  tooltip: '保存到相册',
                  child: const Icon(Icons.save_alt, color: Colors.white),
                ),
                const SizedBox(height: 12),

                // 设为壁纸菜单
                GestureDetector(
                  onTapDown: (TapDownDetails details) {
                    _showSetWallpaperMenu(details.globalPosition);
                  },
                  child: const FloatingActionButton.small(
                    heroTag: 'fab_settings',
                    onPressed: null,
                    backgroundColor: Color(0xD9448AFF),
                    elevation: 2,
                    tooltip: '设为壁纸',
                    child: Icon(Icons.wallpaper, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建壁纸展示内容（支持加载、错误重试与淡入动画）
  Widget _buildWallpaperContent(BingWallpaperItem? wallpaper) {
    if (_isLoading && _wallpapers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    if (_errorMessage != null && _wallpapers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                '加载失败: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchBingWallpapers,
                icon: const Icon(Icons.refresh),
                label: const Text('点击重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (wallpaper == null) {
      return Image.asset(
        'assets/images/bg.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return ImageFade(
      key: ValueKey(wallpaper.imageUrl),
      image: NetworkImage(wallpaper.imageUrl),
      duration: const Duration(milliseconds: 350),
      syncDuration: const Duration(milliseconds: 100),
      alignment: Alignment.center,
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
      placeholder: Container(
        color: const Color(0xFF1E1E1E),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white30,
          ),
        ),
      ),
      errorBuilder: (context, error) => Image.asset(
        'assets/images/bg.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
