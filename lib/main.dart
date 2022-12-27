import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sixam_mart/controller/auth_controller.dart';
import 'package:sixam_mart/controller/cart_controller.dart';
import 'package:sixam_mart/controller/localization_controller.dart';
import 'package:sixam_mart/controller/location_controller.dart';
import 'package:sixam_mart/controller/splash_controller.dart';
import 'package:sixam_mart/controller/store_controller.dart';
import 'package:sixam_mart/controller/theme_controller.dart';
import 'package:sixam_mart/controller/wishlist_controller.dart';
import 'package:sixam_mart/helper/notification_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/theme/dark_theme.dart';
import 'package:sixam_mart/theme/light_theme.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/messages.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/view/screens/item/item_details_screen.dart';
import 'package:url_strategy/url_strategy.dart';
import 'controller/category_controller.dart';
import 'controller/item_controller.dart';
import 'data/model/response/module_model.dart';
import 'data/model/response/store_model.dart';
import 'helper/get_di.dart' as di;
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  if(ResponsiveHelper.isMobilePhone()) {
    HttpOverrides.global = new MyHttpOverrides();
  }
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  if(GetPlatform.isWeb){
    await Firebase.initializeApp(options: FirebaseOptions(
      apiKey: 'AIzaSyDcSvd77NEgiDZCqVRqiXhV1rf-ykbKvXI',
      appId: '1:943340280765:web:54575132c8b33665e350d4',
      messagingSenderId: '943340280765',
      projectId: 'pula-bazaar',
    ));
    // await Firebase.initializeApp(options: FirebaseOptions(
    //   apiKey: 'AIzaSyDFN-73p8zKVZbA0i5DtO215XzAb-xuGSE',
    //   appId: '1:1000163153346:web:4f702a4b5adbd5c906b25b',
    //   messagingSenderId: 'G-L1GNL2YV61',
    //   projectId: 'ammart-8885e',
    // ));
  }
  await Firebase.initializeApp();
  WidgetsFlutterBinding.ensureInitialized();

  // await Firebase.initializeApp(options: DefaultFirebaseConfig.platformOptions);

  // Get any initial links

  // final PendingDynamicLinkData initialLink =
  // await FirebaseDynamicLinks.instance.getInitialLink();

  Map<String, Map<String, String>> _languages = await di.init();

  int _orderID;
  try {
    if (GetPlatform.isMobile) {
      final RemoteMessage remoteMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (remoteMessage != null) {
        _orderID = remoteMessage.notification.titleLocKey != null ? int.parse(remoteMessage.notification.titleLocKey) : null;
      }
      await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
      FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    }
  }catch(e) {}

  // if (ResponsiveHelper.isWeb()) {
  //   FacebookAuth.i.webInitialize(
  //     appId: "452131619626499",
  //     cookie: true,
  //     xfbml: true,
  //     version: "v9.0",
  //   );
  // }
  runApp(MyApp(languages: _languages, orderID: _orderID));
}

class MyApp extends StatelessWidget {
  final Map<String, Map<String, String>> languages;
  final int orderID;
  MyApp({@required this.languages, @required this.orderID});



  void _route() {
    Get.find<SplashController>().getConfigData().then((bool isSuccess) async {
      if (isSuccess) {
        if (Get.find<AuthController>().isLoggedIn()) {
          Get.find<AuthController>().updateToken();
          await Get.find<WishListController>().getWishList();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if(GetPlatform.isWeb) {
      Get.find<SplashController>().initSharedData();
      if(Get.find<LocationController>().getUserAddress() != null && Get.find<LocationController>().getUserAddress().zoneIds == null) {
        Get.find<AuthController>().clearSharedAddress();
      }
      Get.find<CartController>().getCartData();
      _route();
    }

    return GetBuilder<ThemeController>(builder: (themeController) {
      return GetBuilder<LocalizationController>(builder: (localizeController) {
        return GetBuilder<SplashController>(builder: (splashController) {
          return (GetPlatform.isWeb && splashController.configModel == null) ? SizedBox() : GetMaterialApp(
            title: AppConstants.APP_NAME,
            debugShowCheckedModeBanner: false,
            navigatorKey: Get.key,
            scrollBehavior: MaterialScrollBehavior().copyWith(
              dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
            ),
            theme: themeController.darkTheme ? themeController.darkColor == null ? dark() : dark(color
                : themeController.darkColor) : themeController.lightColor == null ? light()
                : light(color: themeController.lightColor),
            locale: localizeController.locale,
            translations: Messages(languages: languages),
            fallbackLocale: Locale(AppConstants.languages[0].languageCode, AppConstants.languages[0].countryCode),
            initialRoute: GetPlatform.isWeb ? RouteHelper.getInitialRoute() : RouteHelper.getSplashRoute(orderID),
            getPages: RouteHelper.routes,
            defaultTransition: Transition.topLevel,
            transitionDuration: Duration(milliseconds: 500),
          );
        });
      });
    });
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class DynamicLinkService {

  // String shortDynamicLink = 'https://pulabazaarapp.page.link';
  String shortDynamicLink = 'https://pulabazaarapp.page.link';


  @override
  void initState() {
    // super.initState();
  }

  @override
  void shareDynamicLinkProduct({itemUrl}) {
    DynamicLinkService().shareProductLink(
      url: itemUrl,
    );
  }

  DynamicLinkParameters dynamicLinkParameters({Uri url, String title, String image, String moduleId}) {
    return DynamicLinkParameters(
      uriPrefix: shortDynamicLink,
      link: url,
      androidParameters: AndroidParameters(
        packageName: "com.pula.bazaar",
        minimumVersion: 0,
      ),
      iosParameters: IOSParameters(
        bundleId: "com.destek.pulabazaar",
        minimumVersion: '0',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: title,
        imageUrl: Uri.parse(image),
      ),
    );
  }

  Future<Uri> generateFirebaseDynamicLink(DynamicLinkParameters params) async {
    var dynamicLinks = FirebaseDynamicLinks.instance;

    if (dynamicLinks!=null) {
      var shortDynamicLink = await dynamicLinks.buildShortLink(params);
      return shortDynamicLink.shortUrl;
    } else {
      return await dynamicLinks.buildLink(params);
    }
  }

  /// share product link that contains Dynamic link
  void shareProductLink({
    String des,
    String moduleId,
    Uri url,
    String name,
    String image,
  }) async {
    var productParams = dynamicLinkParameters(url: url,image: image, title: name, moduleId: moduleId);
    var firebaseDynamicLink = await generateFirebaseDynamicLink(productParams);
    print('[firebase-dynamic-link] $firebaseDynamicLink');
    await Share.share(
      "$des\n${firebaseDynamicLink.toString()}",
    );
  }




  static void initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData)  {
      Uri deepLink = dynamicLinkData.link;
      print('[firebase-dynamic-link] getInitialLink: $deepLink');

      String id = deepLink.queryParameters['id'];
      String moduleId = deepLink.queryParameters['moduleId'];
      print(moduleId);
      handleDynamicLink(id,moduleId,dynamicLinkData.link.path);
    }).onError((e) {
      print('[firebase-dynamic-link] error: ${e.message}');
    });

    final PendingDynamicLinkData initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink != null) {
      Uri deepLink = initialLink.link;

      print('[firebase-dynamic-link] getInitialLink: $deepLink');

      String id = deepLink.queryParameters['id'];
      String moduleId = deepLink.queryParameters['moduleId'];
      print(moduleId);

      await handleDynamicLink(id,moduleId, deepLink.path);



      // GetPage(name: '/store', page: () {
      //   return getRoute(Get.arguments != null ? Get.arguments : StoreScreen(
      //     store: Store(id: int.parse(Get.parameters[id])),
      //     fromModule: Get.parameters['page'] == 'module',
      //   ));
      // });
      //
      // if(Get.find<AuthController>().isLoggedIn()) {
      //   Get.find<StoreController>().getStoreDetails(Store(id: int.parse(id)), true);
      //   if(Get.find<CategoryController>().categoryList == null) {
      //     Get.find<CategoryController>().getCategoryList(true);
      //   }
      //   Get.find<StoreController>().getStoreItemList(int.parse(id), 1, 'all', false);
      //   Get.toNamed(
      //     RouteHelper.getStoreRoute(int.parse(id), 'store'),
      //     // arguments: StoreScreen(store: _storeList, fromModule: true),
      //   );
      // }
    }
  }

  static Future<void> handleDynamicLink(
      String id,String moduleId, final url) async {

    bool item = url.contains('/item');
    print(item);

    if(url.contains('/store')){
      Get.find<StoreController>().getStoreDetails(Store(id: int.parse(id)), true);
      if(Get.find<CategoryController>().categoryList == null) {
        Get.find<CategoryController>().getCategoryList(true);
      }
      Get.find<StoreController>().getStoreItemList(int.parse(id), 1, 'all', false);
      // List<Store> _storeList = isFeature != null ? StoreController().featuredStoreList
      //     : StoreController().latestStoreList;

      Get.find<SplashController>().getModules();
      if( Get.find<SplashController>().moduleList != null) {
        for(ModuleModel module in Get.find<SplashController>().moduleList) {
          if(module.id == moduleId) {
            Get.find<SplashController>().setModule(module);
            break;
          }
        }
      }
      Get.toNamed(
        RouteHelper.getStoreRoute(int.parse(id), 'store'),
      );
      // if(Get.find<AuthController>().isLoggedIn()) {
      //   Get.find<StoreController>().getStoreDetails(Store(id: int.parse(id)), true);
      //   if(Get.find<CategoryController>().categoryList == null) {
      //     Get.find<CategoryController>().getCategoryList(true);
      //   }
      //   Get.find<StoreController>().getStoreItemList(int.parse(id), 1, 'all', false);
      //   // List<Store> _storeList = isFeature != null ? StoreController().featuredStoreList
      //   //     : StoreController().latestStoreList;
      //
      //   Get.find<SplashController>().getModules();
      //   if( Get.find<SplashController>().moduleList != null) {
      //     for(ModuleModel module in Get.find<SplashController>().moduleList) {
      //       if(module.id == moduleId) {
      //         Get.find<SplashController>().setModule(module);
      //         break;
      //       }
      //     }
      //   }
      //   Get.toNamed(
      //     RouteHelper.getStoreRoute(int.parse(id), 'store'),
      //   );
      // }
    }else if(url.contains('/item')){

      Get.find<StoreController>().getStoreDetails(Store(id: int.parse(id)), true);
      if(Get.find<CategoryController>().categoryList == null) {
        Get.find<CategoryController>().getCategoryList(true);
      }
      Get.find<StoreController>().getStoreItemList(int.parse(id), 1, 'all', false);
      await Get.find<ItemController>().getPopularItemList(true, 'all', false);

      // List<Store> _storeList = isFeature != null ? StoreController().featuredStoreList
      //     : StoreController().latestStoreList;
      Get.find<SplashController>().getModules();
      if( Get.find<SplashController>().moduleList != null) {
        for(ModuleModel module in Get.find<SplashController>().moduleList) {
          if(module.id == moduleId) {
            Get.find<SplashController>().setModule(module);
            break;
          }
        }
      }
      Get.toNamed(
        RouteHelper.getItemDetailsRoute(int.parse(id), item),
      );
      // if(Get.find<AuthController>().isLoggedIn()) {
      //   Get.find<StoreController>().getStoreDetails(Store(id: int.parse(id)), true);
      //   if(Get.find<CategoryController>().categoryList == null) {
      //     Get.find<CategoryController>().getCategoryList(true);
      //   }
      //   Get.find<StoreController>().getStoreItemList(int.parse(id), 1, 'all', false);
      //   await Get.find<ItemController>().getPopularItemList(true, 'all', false);
      //
      //   // List<Store> _storeList = isFeature != null ? StoreController().featuredStoreList
      //   //     : StoreController().latestStoreList;
      //   Get.find<SplashController>().getModules();
      //   if( Get.find<SplashController>().moduleList != null) {
      //     for(ModuleModel module in Get.find<SplashController>().moduleList) {
      //       if(module.id == moduleId) {
      //         Get.find<SplashController>().setModule(module);
      //         break;
      //       }
      //     }
      //   }
      //   Get.toNamed(
      //     RouteHelper.getItemDetailsRoute(int.parse(id), item),
      //   );
      // }
    }


  }
}
