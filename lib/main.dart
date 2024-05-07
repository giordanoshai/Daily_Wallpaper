import 'dart:convert';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_fade/image_fade.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'package:gallery_saver/gallery_saver.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';



void main() {
  runApp(const MyApp());
}




class MyApp extends StatelessWidget {
  const MyApp({super.key});



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:'简纸',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
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



//////////////////////
class _MyHomePageState extends State<MyHomePage> {

  String copyRight = '';
  String _imageUrl = '';
  final String _bingApi = 'http://box.ggwp.cn:52490/get_random_image_url';
  String _platformVersion = 'Unknown';
  String __heightWidth = "Unknown";
  double _initialPosition = 0.0 ; // 初始触摸点位置
  double _lastPosition =  0.0 ; // 上一次触摸点位置
  double _distance = 0.0; // 位置变化的字符串表示
  final fadeColor = const LinearGradient(
    colors: [Colors.blue, Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );


  @override
  void initState() {
    super.initState();

    _fetchBingImageUrl();
    initAppState();
  } ///运行执行_fetchBingImageUrl
  ///


  Future<void> initAppState() async {
    String platformVersion;
    String heightWidth;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await WallpaperManager.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    try {
      int height = await WallpaperManager.getDesiredMinimumHeight();
      int width = await WallpaperManager.getDesiredMinimumWidth();
      heightWidth =
          "Width = $width Height = $height";
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
      heightWidth = "Failed to get Height and Width";
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      __heightWidth = heightWidth;
      _platformVersion = platformVersion;
    });
  }///壁纸设置初始化


  Future<void> _fetchBingImageUrl() async {
    try {
      final response = await http.get(Uri.parse(_bingApi));
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _imageUrl = jsonData['url'];
          copyRight = jsonData['copyright'];

        });
      } else {

        throw Exception('Failed to load data');
      }
    } catch (e) {
      // 错误处理，例如显示错误消息
    }
  } ///传递图片地址给_imageUrl



  // Future<void> _fetchBingImageUrl() async {
  //   try {
  //     final String imageUrl = await fetchBingImageUrl();
  //     setState(() {
  //
  //       _imageUrl = imageUrl;
  //     });
  //   } catch (e) {
  //     // 错误处理，例如显示错误消息
  //     // print(e);
  //   }
  // } ///传递图片地址给_imageUrl

  // Future<String> fetchBingImageUrl() async {
  //   String imageUrl = ''; // 声明imageUrl变量
  //   _bingApi += '?random=${DateTime.now().microsecondsSinceEpoch}';
  //   print(_bingApi);
  //   final client = HttpClient();
  //   var uri = Uri.parse(_bingApi);
  //   var request = await client.getUrl(uri);
  //   request.followRedirects = false;
  //
  //   var response = await request.close();
  //   while (response.isRedirect) {
  //     response.drain();
  //     final location = response.headers.value(HttpHeaders.locationHeader);
  //     if (location != null) {
  //       uri = uri.resolve(location);
  //       request = await client.getUrl(uri);
  //       // Set the body or headers as desired.
  //       request.followRedirects = false;
  //       response = await request.close();
  //       imageUrl = uri.toString();
  //     }
  //   }
  //   return imageUrl;
  // } ///获取302跳转RUL



  void _downloadImage() async {
    var status = await Permission.mediaLibrary.request();
    if (status.isGranted) {
      GallerySaver.saveImage(_imageUrl, albumName: 'Media').then((success) {
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.transparent,
            margin: EdgeInsets.only(bottom: 380.0),
            behavior: SnackBarBehavior.floating,
            content: Text(
              '保存成功',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.0),
            ),
          ));
        });

      });
    }
    else {}
  } ///保存图片


  Future<void> setWallpaperHome() async {
    try {
      String url = _imageUrl;
      int location = WallpaperManager
          .HOME_SCREEN; // or location = WallpaperManager.LOCK_SCREEN;
      var file = await DefaultCacheManager().getSingleFile(url);
      // final bool result =
      await WallpaperManager.setWallpaperFromFile(file.path, location);
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.transparent,
            margin: EdgeInsets.only(bottom: 380.0),
            behavior: SnackBarBehavior.floating,
            content: Text(
              '设置成功',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.0),
            ),
          ));
        });

    }
    catch(e){
      // ignored, really.
    }
  }///设置HOME

  Future<void> setWallpaperLock() async {
    try {
      String url = _imageUrl;
      int location = WallpaperManager
          .LOCK_SCREEN; // or location = WallpaperManager.LOCK_SCREEN;
      var file = await DefaultCacheManager().getSingleFile(url);
      // final bool result =
      await WallpaperManager.setWallpaperFromFile(file.path, location);

        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.transparent,
            margin: EdgeInsets.only(bottom: 380.0),
            behavior: SnackBarBehavior.floating,
            content: Text(
              '设置成功',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.0),
            ),
          ));
        });

    }
    catch(e){
      // ignored, really.
    }
  }///设置LOCK


  Future<void> setWallpaperBoth() async {
    try {
      String url = _imageUrl;
      int location = WallpaperManager
          .BOTH_SCREEN; // or location = WallpaperManager.LOCK_SCREEN;
      var file = await DefaultCacheManager().getSingleFile(url);
      // final bool result =
      await WallpaperManager.setWallpaperFromFile(file.path, location);

      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.transparent,
          margin: EdgeInsets.only(bottom: 380.0),
          behavior: SnackBarBehavior.floating,
          content: Text(
            '设置成功',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20.0),
          ),
        ));
      });

    }
    catch(e){
      // ignored, really.
    }
  }///设置BOTH





  void showPopupMenuButton(Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx-200,
          position.dy-140,
          position.dx,
          position.dy), // 根据需要调整位置
      items: <PopupMenuItem<String>>[

        PopupMenuItem<String>(
            onTap: setWallpaperHome,
            child:const Row(
              children: [
                Icon(Icons.home),
                Text('桌面')
              ],
            )
        ),
        PopupMenuItem<String>(
            onTap: setWallpaperLock,
            child:const Row(
              children: [
                Icon(Icons.lock),
                Text('锁屏',)
              ],
            )
        ),
        PopupMenuItem<String>(
          onTap: setWallpaperBoth,
          child:const Row(
            children: [
              Icon(Icons.ad_units_outlined),
              Text('桌面和锁屏'),
            ],
          )
        ),
        // 添加更多选项
      ],
    );
  }







///////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
              backgroundColor: Colors.blue[700],
              title: Text(widget.title,style: const TextStyle(color: Colors.black),),
      ),///蓝色顶部AppBar，单独的空间
      // appBar: null,///去掉appBar
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(

            child:
              GestureDetector(

                onPanDown: (details) {
                  setState(() {
                    _initialPosition = details.localPosition.dy;
                  });
                },
                // onPanUpdate 回调，更新当前触摸点的 y 坐标
                onPanUpdate: (details) {
                  setState(() {
                    _lastPosition = details.localPosition.dy;
                  });
                },
                // onPanEnd 回调，计算并打印滑动距离
                onPanEnd: (details) {
                  _distance = _initialPosition - _lastPosition;
                 switch(_distance.sign){
                   case 1:
                   case -1:
                     if (_distance.abs() >= 40)
                       {
                         _fetchBingImageUrl();
                       }
                 }
                },

                  child: Container(
                      color: Colors.transparent,
                      constraints: const BoxConstraints.expand(),
                      child:
                          ImageFade(
                            // whenever the image changes, it will be loaded, and then faded in:
                            image: _imageUrl == null ? null : NetworkImage(_imageUrl),

                            // slow-ish fade for loaded images:
                            duration: const Duration(milliseconds: 400),

                            // if the image is loaded synchronously (ex. from memory), fade in faster:
                            syncDuration: const Duration(milliseconds: 150),

                            // supports most properties of Image:
                            alignment: Alignment.center,
                            fit: BoxFit.cover,
                            scale: 2,
                            height: double.infinity,
                            width: double.infinity,

                            // shown behind everything:
                            placeholder: Container(
                              color: const Color(0xFFCFCDCA),
                              alignment: Alignment.center,
                              child: const Icon(Icons.photo, color: Colors.white30, size: 128.0),
                            ),

                            // shows progress while loading an image:
                            loadingBuilder: (context, progress, chunkEvent) =>
                                Center(child: CircularProgressIndicator(value: progress)),

                            // displayed when an error occurs:
                            errorBuilder: (context, error) => Container(
                              color: const Color(0xFF6F6D6A),
                              alignment: Alignment.center,
                              child:
                              Image.asset('assets/images/bg.png' ,fit: BoxFit.fill,
                                  height: double.infinity,
                                  width: double.infinity,),
                            ),
                          )
                          
                  ),

              ),///图片显示和滑动侦测

          ),
          
          Positioned(
            bottom: 20.0,
            right: 10.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: _fetchBingImageUrl,
                  backgroundColor: Colors.blue[700],
                  mini:true,
                  child: const Icon(Icons.refresh,color: Colors.white70,)
                ),

                const SizedBox(
                  height: 10,
                ),
                FloatingActionButton(
                  onPressed: _downloadImage,
                  backgroundColor: Colors.blue[700],
                  mini:true,
                  child: const Icon(Icons.save,color: Colors.white70,)
                ),

                const SizedBox(
                  height: 10,
                ),
                GestureDetector ( onTapDown: (TapDownDetails details) {
                  showPopupMenuButton(details.globalPosition);
                },

                   child: FloatingActionButton(
                    onPressed: null,
                    backgroundColor: Colors.blue[700],
                    mini:true,
                    child: const Icon(Icons.settings,color: Colors.white70,)
                  ),
                ),
              ],

            ),
          ),///3个按钮
          Positioned(
              bottom: 10.0,
              left: 20.0,
              right: 60.0,

              child: Column(
                mainAxisAlignment:MainAxisAlignment.end,
                children: [
                      Text(copyRight,style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 22.0,
                      fontWeight: FontWeight.w300,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.grey,
                        )
                      ],
                    ),),
                  const SizedBox(height: 5.0,),
                    const Padding( padding: EdgeInsets.only(left: 20.0),
                      child: Icon(Icons.keyboard_double_arrow_up_outlined,color: Colors.white24,size: 30,),)
                ]
              ),
          ),///底部的CopyRight
          // Positioned(
          //   top:0,left: 0,right: 0,
          //     child: AppBar(
          //         backgroundColor: Colors.grey.withOpacity(0.4),
          //         title: Text(widget.title,style: const TextStyle(color: Colors.white70),),
          //
          // )

          //)///AppBar半透明
        ],
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}


