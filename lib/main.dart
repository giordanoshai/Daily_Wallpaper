import 'dart:convert';
// import 'dart:io';
import 'dart:async';
import 'dart:math';

// import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_fade/image_fade.dart';
import 'package:flutter_gromore_ads/flutter_gromore_ads.dart';
import 'package:http/http.dart' as http;


import 'package:permission_handler/permission_handler.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:daily_wallpaper/adConfigs.dart';

//version: 1.0.60

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
  ///变量
  String _platformVersion = 'Unknown';
  String __heightWidth = "Unknown";
  String copyRight = '';
  String _imageUrl = '';
  final String _bingApi = 'http://box.ggwp.cn:52490/get_random_image_url';
  double _initialPosition = 0.0 ; // 初始触摸点位置
  double _lastPosition =  0.0 ; // 上一次触摸点位置
  double _distance = 0.0; // 位置变化的字符串表示
  String _adInitResult = '';
  String _adEvent = '';
  String eventAction = '';
  final Set<String> eventActions = {
    'onAdComplete',
    'onAdClosed',
    'onAdReward',
    'onAdSkip'
  };
  bool _isButtonTrigger = false;


  @override
  void initState() {
    _fetchBingImageUrl();
    setAdEvent();
    initAd();
    requestIDFA();
    super.initState();
    ///开启app后获取_imageUrl
    initAppState();///初始化wallpaper manager
  }
  ///开机执行

///函数
  ///


  ///初始化壁纸插件wallpaperManager
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
  // } //////add获取302跳转RUL
  ///获取302跳转URL，获取imageUrl过时代码.
    ///保存图片 旧代码，也管用，但是没权限的时候照样显示，体验不好。
  // void _downloadImage() async {
  //   var status = await Permission.mediaLibrary.request();
  //   bool isButtonTrigger = await showInterstitialAd();
  //   setState(() {
  //     isButtonTrigger = _isButtonTrigger;
  //   });
  //   if (status.isGranted && isButtonTrigger) {
  //     GallerySaver.saveImage(_imageUrl, albumName: 'Media').then((success) {
  //       setState(() {
  //         _isButtonTrigger = false;
  //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //           backgroundColor: Colors.transparent,
  //           margin: EdgeInsets.only(bottom: 380.0),
  //           behavior: SnackBarBehavior.floating,
  //           content: Text(
  //             '保存成功',
  //             textAlign: TextAlign.center,
  //             style: TextStyle(fontSize: 20.0),
  //           ),
  //         ));
  //       });
  //
  //     });
  //   }
  //   else {}
  // }

  ///保存图片并显示广告，检测广告是否
  Future<void> _downloadImage() async {
    // 请求权限
    var status = await Permission.mediaLibrary.request();
    bool isAdShown = eventActions.contains(await showInterstitialAd());
    if (isAdShown && status.isGranted) {// 如果广告未展示，则不继续
      GallerySaver.saveImage(_imageUrl, albumName: 'Media').then((success) {
          setState(() {
            _isButtonTrigger = false;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Colors.transparent,
              margin: EdgeInsets.only(bottom: 380.0),
              behavior: SnackBarBehavior.floating,
              content: Text(
                '保存成功',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70,fontSize: 20.0),
              ),
            ));
          });
        });
    }
  }




 // Future <void> setWallpaperHome() async {
 //    try {
 //      String url = _imageUrl;
 //      int location = WallpaperManager
 //          .HOME_SCREEN; // or location = WallpaperManager.LOCK_SCREEN;
 //      var file = await DefaultCacheManager().getSingleFile(url);
 //      // final bool result =
 //      await WallpaperManager.setWallpaperFromFile(file.path, location);
 //        setState(() {
 //          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
 //            backgroundColor: Colors.transparent,
 //            margin: EdgeInsets.only(bottom: 380.0),
 //            behavior: SnackBarBehavior.floating,
 //            content: Text(
 //              '设置成功1',
 //              textAlign: TextAlign.center,
 //              style: TextStyle(fontSize: 20.0),
 //            ),
 //          ));
 //        });
 //
 //    }
 //    catch(e){
 //      // ignored, really.
 //    }
 //  }///设置HOME
  //
  // Future<void> setWallpaperLock() async {
  //   try {
  //     String url = _imageUrl;
  //     int location = WallpaperManager
  //         .LOCK_SCREEN; // or location = WallpaperManager.LOCK_SCREEN;
  //     var file = await DefaultCacheManager().getSingleFile(url);
  //     // final bool result =
  //     await WallpaperManager.setWallpaperFromFile(file.path, location);
  //
  //       setState(() {
  //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //           backgroundColor: Colors.transparent,
  //           margin: EdgeInsets.only(bottom: 380.0),
  //           behavior: SnackBarBehavior.floating,
  //           content: Text(
  //             '设置成功',
  //             textAlign: TextAlign.center,
  //             style: TextStyle(fontSize: 20.0),
  //           ),
  //         ));
  //       });
  //
  //   }
  //   catch(e){
  //     // ignored, really.
  //   }
  // }///设置LOCK
  //
  //
  // Future<void> setWallpaperBoth() async {
  //   try {
  //     String url = _imageUrl;
  //     int location = WallpaperManager
  //         .BOTH_SCREEN; // or location = WallpaperManager.LOCK_SCREEN;
  //     var file = await DefaultCacheManager().getSingleFile(url);
  //     // final bool result =
  //     await WallpaperManager.setWallpaperFromFile(file.path, location);
  //
  //     setState(() {
  //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //         backgroundColor: Colors.transparent,
  //         margin: EdgeInsets.only(bottom: 380.0),
  //         behavior: SnackBarBehavior.floating,
  //         content: Text(
  //           '设置成功',
  //           textAlign: TextAlign.center,
  //           style: TextStyle(fontSize: 20.0),
  //         ),
  //       ));
  //     });
  //
  //   }
  //   catch(e){
  //     // ignored, really.
  //   }
  // }///设置BOTH
  // ///壁纸旧代码

  ///设置壁纸新代码
  Future<void> setWallpaper(int location) async {
    bool isAdShown = eventActions.contains(await showInterstitialAd());
    if (isAdShown) {
      try {
          var file = await DefaultCacheManager().getSingleFile(_imageUrl);
          await WallpaperManager.setWallpaperFromFile(file.path, location);
            setState(() {
              _isButtonTrigger = false;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.transparent,
                margin: EdgeInsets.only(bottom: 380.0),
                behavior: SnackBarBehavior.floating,
                content: Text(
                  '设置成功',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70,fontSize: 20.0),
                ),
              ));
            });

      } catch (e) {
        // 向用户显示一个通用错误消息
      }
    }
  }///设置壁纸

  void setWallpaperHome() {
    setWallpaper(WallpaperManager.HOME_SCREEN);
  }///壁纸Home

  void setWallpaperLock() {
    setWallpaper(WallpaperManager.LOCK_SCREEN);
  }///壁纸Lock

  void setWallpaperBoth() {
    setWallpaper(WallpaperManager.BOTH_SCREEN);
  }///壁纸Both

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
            onTap:() {
              _isButtonTrigger =true;
              setWallpaperHome();},
            child:const Row(
              children: [
                Icon(Icons.home),
                Text('桌面')
              ],
            )
        ),
        PopupMenuItem<String>(
            onTap: () {
              _isButtonTrigger =true;
              setWallpaperLock();
              },
            child:const Row(
              children: [
                Icon(Icons.lock),
                Text('锁屏',)
              ],
            )
        ),
        PopupMenuItem<String>(
          onTap: () {
            _isButtonTrigger =true;
            setWallpaperBoth();
          },
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

///广告相关函数
  ///初始化广告SDK
  Future<bool> initAd() async{
      try {
        bool result = await FlutterGromoreAds.initAd(
            '5520923',
            config:'android_config_5520923.json' ,
            limitPersonalAds: 0,
        );
        _adInitResult = "广告SDK 初始化${result? '成功':'失败'}";
        setState(() {});
        return result;
      }on PlatformException catch(e) {
        _adInitResult =
        "广告SDK 初始化失败 code:${e.code} msg:${e.message} details:${e.details}";
      }
      setState(() {});
      return false;
 }

  ///设置广告监听
 Future<void> setAdEvent() async {
    setState(() {
      _adEvent = '设置成功';
    });
    FlutterGromoreAds.onEventListener((event) {
      _adEvent = 'adId:${event.adId} action:${event.action}';
      if (event is AdErrorEvent) {
        //错误事件
        _adEvent += ' errCode:${event.errCode} errMsg:${event.errMsg}';
      }
      else if(event is AdRewardEvent) {
        //激励事件
        _adEvent += ' rewardVerify:${event.rewardVerify} '
            'rewardAmount:${event.rewardAmount} rewardName:${event.rewardName} '
            'errCode:${event.errCode} errMsg:${event.errMsg} '
            'customData:${event.customData} userId:${event.userId}';
      }
      debugPrint('onEventListener:$_adEvent');
      setState(() {});
    });
 }

  /// 请求应用跟踪透明度授权
  Future<void> requestIDFA() async {
    bool result = await FlutterGromoreAds.requestIDFA;
    _adEvent = '请求广告标识符:$result';
    setState(() {});
  }

  /// 请求应用跟踪透明度授权
  Future<void> requestPermissionIfNecessary() async {
    bool result = await FlutterGromoreAds.requestPermissionIfNecessary;
    _adEvent = '请求相关权限:$result';
    setState(() {});
  }

  ///插屏广告
  Future<String> showInterstitialAd() async {
    String adId = await AdConfig.getInterstitialId();
    try {
      bool requestPermission =  await FlutterGromoreAds.requestPermissionIfNecessary;
        if (requestPermission){
          bool result = await FlutterGromoreAds.showInterstitialAd(adId);
           if (_isButtonTrigger) {
            FlutterGromoreAds.onEventListener((event) {
                eventAction = event.action;
                // print('TT_EventAction is :$eventAction,and _isButtonTrigger:$_isButtonTrigger');
            });
          }else{
            eventAction = 'TT_EventAction : not_trigger_by_button';
            // print(eventAction);
          }
          _adInitResult = "展示插屏广告${result ? '成功' : '失败'}";
        }
    } on PlatformException catch (e) {
      _adInitResult = "展示插屏广告失败 code:${e.code} msg:${e.message} details:${e.details}";
    }
    setState(() {});
    return eventAction;
  }



///广告相关函数

///函数

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
                         final random = Random().nextDouble();
                           if (random <= 0.4) {
                             showInterstitialAd();
                           }///40%的几率出现广告
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
                // FloatingActionButton(
                //     onPressed: shareImage,
                //     backgroundColor: Colors.blue[700],
                //     mini:true,
                //     child: const Icon(Icons.share_outlined,color: Colors.white70,)
                // ),
                // const SizedBox(
                //   height: 10,
                // ),
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
                  onPressed: () {
                    _isButtonTrigger = true;
                    _downloadImage();
                  },
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


