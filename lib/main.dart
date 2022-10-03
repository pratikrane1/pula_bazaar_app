import 'dart:async';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:sixam_mart/controller/auth_controller.dart';
import 'package:sixam_mart/controller/cart_controller.dart';
import 'package:sixam_mart/controller/localization_controller.dart';
import 'package:sixam_mart/controller/location_controller.dart';
import 'package:sixam_mart/controller/splash_controller.dart';
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
import 'package:sixam_mart/view/screens/location/access_location_screen.dart';
import 'package:sixam_mart/view/screens/store/store_screen.dart';
import 'package:sixam_mart/view/screens/update/update_screen.dart';
import 'package:url_strategy/url_strategy.dart';
import 'data/model/response/store_model.dart';
import 'helper/get_di.dart' as di;
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:uni_links/uni_links.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  if(ResponsiveHelper.isMobilePhone()) {
    HttpOverrides.global = new MyHttpOverrides();
  }
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  if(GetPlatform.isWeb){
    await Firebase.initializeApp(options: FirebaseOptions(
      apiKey: 'AIzaSyDFN-73p8zKVZbA0i5DtO215XzAb-xuGSE',
      appId: '1:1000163153346:web:4f702a4b5adbd5c906b25b',
      messagingSenderId: 'G-L1GNL2YV61',
      projectId: 'ammart-8885e',
    ));
  }
  await Firebase.initializeApp();

  // await Firebase.initializeApp(options: DefaultFirebaseConfig.platformOptions);

  // Get any initial links
  DynamicLinkService.initDynamicLinks();
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
  // final _service = Services();

  String shortDynamicLink = 'https://pulabazaarapp.page.link';
  // String shortDynamicLink = 'https://pulabazaarapp.page.link/store';
  // String shortDynamicLink = 'https://pulabazaarapp.page.link/FGYB';

  Uri _initialURI;
  Uri _currentURI;
  Object _err;

  @override
  void initState() {
    // super.initState();
  }

  @override
  void shareDynamicLinkProduct({itemUrl}) {
    DynamicLinkService().shareProductLink(
      storeID: itemUrl,
    );
  }

  DynamicLinkParameters dynamicLinkParameters({String storeID, String title, String image}) {
    return DynamicLinkParameters(
      uriPrefix: shortDynamicLink,
      link: Uri.parse('https://pulabazaar.com/store?id=$storeID'),
      androidParameters: AndroidParameters(
        packageName: "com.pula.bazaar",
        minimumVersion: 21,
      ),
      // iosParameters: IOSParameters(
      //   bundleId: firebaseDynamicLinkConfig['iOSBundleId'],
      //   minimumVersion: firebaseDynamicLinkConfig['iOSAppMinimumVersion'],
      //   appStoreId: firebaseDynamicLinkConfig['iOSAppStoreId'],
      // ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: title,
        imageUrl: Uri.parse(image),
      ),
    );
  }

  Future<Uri> generateFirebaseDynamicLink(DynamicLinkParameters params) async {
    var dynamicLinks = FirebaseDynamicLinks.instance;

    // if (shortDynamicLink==null) {
    //   var shortDynamicLink = await dynamicLinks.buildShortLink(params);
    //   return shortDynamicLink.shortUrl;
    // } else {
      return await dynamicLinks.buildLink(params);
    // }
  }

  /// share product link that contains Dynamic link
  void shareProductLink({
    String storeID,
    String name,
    String image,
  }) async {
    var productParams = dynamicLinkParameters(storeID: storeID,image: image, title: name);
    var firebaseDynamicLink = await generateFirebaseDynamicLink(productParams);
    print('[firebase-dynamic-link] $firebaseDynamicLink');
    await Share.share(

      firebaseDynamicLink.toString(),
      // name.toString(),
    );
  }




  static void initDynamicLinks() async {
    Store _storeList;

    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      // final Uri uri = dynamicLinkData.link;
      // final queryParams = uri.pathSegments.contains('store');
      // String productId = uri.queryParameters['id'];
      // print(productId);
      final deepLink = dynamicLinkData.link;
      print("Dynamic URL: "+dynamicLinkData.link.queryParameters['store']);
      handleDynamicLink(deepLink);
    }).onError((e) {
      print('[firebase-dynamic-link] error: ${e.message}');
    });

    var initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink != null) {
      final deepLink = initialLink.link;
      // final Uri uri = initialLink.link;
      // final queryParams = uri.pathSegments.contains('store');
      // String productId = uri.queryParameters['id'];
      // print(productId);
      print('[firebase-dynamic-link] getInitialLink: $deepLink');
      // await handleDynamicLink(deepLink, );

      String id = deepLink.queryParameters['id'];


      // GetPage(name: '/store', page: () {
      //   return getRoute(Get.arguments != null ? Get.arguments : StoreScreen(
      //     store: Store(id: int.parse(Get.parameters[id])),
      //     fromModule: Get.parameters['page'] == 'module',
      //   ));
      // });

      // Get.to(
      //     StoreScreen(store: Store(id: int.parse(Get.parameters[id])), fromModule: true)
      // );
      // Navigator.push(context, MaterialPageRoute(builder: (context)=> StoreScreen(store: Store(id: int.parse(Get.parameters[id])), fromModule: true)));
      Get.to(
        RouteHelper.getStoreRoute(int.parse(id), 'store'),
        arguments: StoreScreen(store: _storeList, fromModule: true),
      );
    }
  }

  static getRoute(Widget navigateTo) {
    int _minimumVersion = 0;
    if(GetPlatform.isAndroid) {
      _minimumVersion = Get.find<SplashController>().configModel.appMinimumVersionAndroid;
    }else if(GetPlatform.isIOS) {
      _minimumVersion = Get.find<SplashController>().configModel.appMinimumVersionIos;
    }
    return AppConstants.APP_VERSION < _minimumVersion ? UpdateScreen(isUpdate: true)
        : Get.find<SplashController>().configModel.maintenanceMode ? UpdateScreen(isUpdate: false)
        : Get.find<LocationController>().getUserAddress() == null
        ? AccessLocationScreen(fromSignUp: false, fromHome: false, route: Get.currentRoute) : navigateTo;
  }

  static Future<void> handleDynamicLink(
      Uri url,) async {

    Store _storeList;

      // final queryParams = url.queryParameters['id'];

      var isStore = url.pathSegments.contains('store');
      if(url != null){
        String id = url.queryParameters['id'];

        if(url!=null){

          try{

            await Get.toNamed(
                    RouteHelper.getStoreRoute(int.parse(id), 'store'),
                    arguments: StoreScreen(store: _storeList, fromModule: true),
                  );

          }catch(e){
            print(e);
          }
        }else{
          return null;
        }
      }
      // if (queryParams.isNotEmpty) {
      //   final productId = url.queryParameters['id'];
      //
      //   print("Store ID" + productId);
      //   if (productId != null) {
      //     await Get.toNamed(
      //       RouteHelper.getStoreRoute(int.parse(productId), 'store'),
      //       arguments: StoreScreen(store: _storeList, fromModule: true),
      //     );
      //   }
      // }

  }
}
