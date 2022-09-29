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
import 'package:url_strategy/url_strategy.dart';
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
      apiKey: 'AIzaSyDFN-73p8zKVZbA0i5DtO215XzAb-xuGSE',
      appId: '1:1000163153346:web:4f702a4b5adbd5c906b25b',
      messagingSenderId: 'G-L1GNL2YV61',
      projectId: 'ammart-8885e',
    ));
  }
  await Firebase.initializeApp();

  // await Firebase.initializeApp(options: DefaultFirebaseConfig.platformOptions);

  // Get any initial links
  DynamicLinkService().initDynamicLinks();
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

  String shortDynamicLink = 'https://pulabazaarapp.page.link/test';

  @override
  void shareDynamicLinkProduct({itemUrl}) {
    DynamicLinkService().shareProductLink(
      productUrl: itemUrl,
    );
  }

  DynamicLinkParameters dynamicLinkParameters({String url}) {
    return DynamicLinkParameters(
      uriPrefix: shortDynamicLink,
      link: Uri.parse(url),
      androidParameters: AndroidParameters(
        packageName: "com.pula.bazaar",
        minimumVersion: 21,
      ),
      // iosParameters: IOSParameters(
      //   bundleId: firebaseDynamicLinkConfig['iOSBundleId'],
      //   minimumVersion: firebaseDynamicLinkConfig['iOSAppMinimumVersion'],
      //   appStoreId: firebaseDynamicLinkConfig['iOSAppStoreId'],
      // ),
    );
  }

  Future<Uri> generateFirebaseDynamicLink(DynamicLinkParameters params) async {
    var dynamicLinks = FirebaseDynamicLinks.instance;

    if (shortDynamicLink==null) {
      var shortDynamicLink = await dynamicLinks.buildShortLink(params);
      return shortDynamicLink.shortUrl;
    } else {
      return await dynamicLinks.buildLink(params);
    }
  }

  /// share product link that contains Dynamic link
  void shareProductLink({
    String productUrl,
  }) async {
    var productParams = dynamicLinkParameters(url: productUrl);
    var firebaseDynamicLink = await generateFirebaseDynamicLink(productParams);
    print('[firebase-dynamic-link] $firebaseDynamicLink');
    await Share.share(
      firebaseDynamicLink.toString(),
    );
  }

   void initDynamicLinks() async {


    var initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
    SnackBar(content: Text("$initialLink"),);

    if (initialLink != null) {
      final deepLink = initialLink.link;
      print('[firebase-dynamic-link] getInitialLink: $deepLink');
      SnackBar(content: Text("$deepLink"),);
      await handleDynamicLink(deepLink.toString(), );
    }

     FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
       handleDynamicLink(dynamicLinkData.link.path, );
     }).onError((e) {
       print('[firebase-dynamic-link] error: ${e.message}');
     });
  }
  //
  //Navigate to ProductDetail screen by entering productURL
  static Future<void> handleDynamicLink(
      String url, ) async {
    try {
      // _showLoading(context);

      /// PRODUCT CASE
      if (url.contains('/store/')
          ) {
        /// Note: the deepLink URL will look like: https://mstore.io/product/stitch-detail-tunic-dress/
        // final product = await Services().api.getProductByPermalink(url);
        final product = url;
        print(product);
        // if (product != null) {
        //   await Get.toNamed(
        //     RouteHelper.getStoreRoute(id, isFeatured ? 'module' : 'store'),
        //     arguments: StoreScreen(store: _storeList[index], fromModule: isFeatured),
        //   );
        // }

        /// PRODUCT CATEGORY CASE
      }
        // else if (url.contains('/product-category/')) {
      //   final category =
      //   await Services().api.getProductCategoryByPermalink(url);
      //   if (category != null) {
      //     await FluxNavigate.pushNamed(
      //       RouteList.backdrop,
      //       arguments: BackDropArguments(
      //         cateId: category.id,
      //         cateName: category.name,
      //       ),
      //     );
      //   }
      //
      //   /// VENDOR CASE
      // } else if (url.contains('/store/')) {
      //   final vendor = await Services().api.getStoreByPermalink(url);
      //   if (vendor != null) {
      //     await FluxNavigate.pushNamed(
      //       RouteList.storeDetail,
      //       arguments: StoreDetailArgument(store: vendor),
      //     );
      //   }
      // } else {
      //   var blog = await Services().api.getBlogByPermalink(url);
      //   if (blog != null) {
      //     await FluxNavigate.pushNamed(
      //       RouteList.detailBlog,
      //       arguments: BlogDetailArguments(blog: blog),
      //     );
      //   }
      // }
    } catch (err) {
      // _showErrorMessage(context);
    }
  }
  //
  // static void _showLoading(context) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(S.current.loadingLink),
  //       duration: const Duration(seconds: 3),
  //       action: SnackBarAction(
  //         label: 'DISMISS',
  //         onPressed: () {
  //           ScaffoldMessenger.of(context).hideCurrentSnackBar();
  //         },
  //       ),
  //     ),
  //   );
  // }
  //
  // static void _showErrorMessage(context) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(S.current.canNotLoadThisLink),
  //       duration: const Duration(seconds: 2),
  //       action: SnackBarAction(
  //         label: 'DISMISS',
  //         onPressed: () {
  //           ScaffoldMessenger.of(context).hideCurrentSnackBar();
  //         },
  //       ),
  //     ),
  //   );
  // }



  // Future<String> generateProductCategoryUrl(dynamic productCategoryId) async {
  //   final cate = await _service.api
  //       .getProductCategoryById(categoryId: productCategoryId);
  //   var url;
  //   if (cate != null) {
  //     url = serverConfig['url'] + '/product-category/' + cate.slug;
  //   }
  //   return url;
  // }
}
