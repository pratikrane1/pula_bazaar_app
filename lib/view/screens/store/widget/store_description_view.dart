import 'package:share_plus/share_plus.dart';
import 'package:sixam_mart/controller/auth_controller.dart';
import 'package:sixam_mart/controller/store_controller.dart';
import 'package:sixam_mart/controller/splash_controller.dart';
import 'package:sixam_mart/controller/wishlist_controller.dart';
import 'package:sixam_mart/data/model/response/address_model.dart';
import 'package:sixam_mart/data/model/response/store_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/view/base/custom_image.dart';
import 'package:sixam_mart/view/base/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;

import 'package:url_launcher/url_launcher.dart';

import '../../../../main.dart';


class StoreDescriptionView extends StatelessWidget {
  final Store store;
  StoreDescriptionView({@required this.store});


  _launchWhatsapp(BuildContext context, Store store) async {
    var whatsapp = store.phone.toString();
    var message = "Hi ${store.name}, I have a Query. Can you please help me?";

    var whatsappURl_android = "whatsapp://send?phone=" + whatsapp +
        "&text=$message";
    var whatappURL_ios = "https://wa.me/$whatsapp?text=${Uri.parse(message)}";
    if (Platform.isIOS) {
      // for iOS phone only
      if (await canLaunch(whatappURL_ios)) {
        await launch(whatappURL_ios, forceSafariVC: false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: new Text("whatsapp no installed")));
      }
    } else {
      // android , web
      if (await canLaunch(whatsappURl_android)) {
        await launch(whatsappURl_android);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: new Text("whatsapp no installed")));
      }
    }
  }


  Future<void> shareReferralCode() async {
    await Share.share(
      'https://pulabazaarapp.page.link/test',
      subject: 'Store URL'
    );
  }

  @override
  Widget build(BuildContext context) {
    bool _isAvailable = Get.find<StoreController>().isStoreOpenNow(store.active, store.schedules);
    Color _textColor = ResponsiveHelper.isDesktop(context) ? Colors.white : null;
    return Column(children: [
      Row(children: [

        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
          child: Stack(children: [
            CustomImage(
              image: '${Get.find<SplashController>().configModel.baseUrls.storeImageUrl}/${store.logo}',
              height: ResponsiveHelper.isDesktop(context) ? 80 : 60, width: ResponsiveHelper.isDesktop(context) ? 100 : 70, fit: BoxFit.cover,
            ),
            _isAvailable ? SizedBox() : Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(Dimensions.RADIUS_SMALL)),
                  color: Colors.black.withOpacity(0.6),
                ),
                child: Text(
                  'closed_now'.tr, textAlign: TextAlign.center,
                  style: robotoRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                ),
              ),
            ),
          ]),
        ),
        SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(
              store.name, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: _textColor),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
            InkWell(
              onTap: () => Get.toNamed(RouteHelper.getSearchStoreItemRoute(store.id)),
              child: ResponsiveHelper.isDesktop(context) ? Container(
                padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT), color: Theme.of(context).primaryColor),
                child: Center(child: Icon(Icons.search, color: Colors.white)),
              ) : Icon(Icons.search, color: Theme.of(context).primaryColor),
            ),
            SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
            GetBuilder<WishListController>(builder: (wishController) {
              bool _isWished = wishController.wishStoreIdList.contains(store.id);
              return InkWell(
                onTap: () {
                  if(Get.find<AuthController>().isLoggedIn()) {
                    _isWished ? wishController.removeFromWishList(store.id, true)
                        : wishController.addToWishList(null, store, true);
                  }else {
                    showCustomSnackBar('you_are_not_logged_in'.tr);
                  }
                },
                child: ResponsiveHelper.isDesktop(context) ? Container(
                  padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT), color: Theme.of(context).primaryColor),
                  child: Center(child: Icon(_isWished ? Icons.favorite : Icons.favorite_border, color: Colors.white)),
                ) : Icon(
                  _isWished ? Icons.favorite : Icons.favorite_border,
                  color: _isWished ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
                ),
              );
            }),
            SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
            InkWell(
              // onTap: () => shareReferralCode(),
              onTap: () {
                DynamicLinkService().shareProductLink(
                    storeID: '${store.id}',
                    name: store.name,
                    image: '${Get.find<SplashController>().configModel.baseUrls.storeImageUrl}/${store.logo}');

              },
              child: ResponsiveHelper.isDesktop(context) ? Container(
                padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT), color: Theme.of(context).primaryColor),
                child: Center(child: Icon(Icons.share_outlined, color: Colors.white)),
              ) : Icon(Icons.share_outlined, color: Theme.of(context).primaryColor),
            ),
          ]),
          SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
          Text(
            store.address ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
          ),
          SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.PADDING_SIZE_EXTRA_SMALL : 0),
          Row(children: [
            Text('minimum_order'.tr, style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor,
            )),
            SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
            Text(
              PriceConverter.convertPrice(store.minimumOrder),
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor),
            ),
          ]),
          SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
          Row(
            children: [

              Icon(Icons.call, size: 15,),
              SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),

              Text(
                store.phone ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
              ),
            ],
          ),

          SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
          Row(
            children: [
              Icon(Icons.email_outlined, size: 15,),
              SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
              Text(
                store.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
              ),
            ],
          )

        ])),

      ]),
      SizedBox(height: ResponsiveHelper.isDesktop(context) ? 30 : Dimensions.PADDING_SIZE_SMALL),

      Row(children: [
        Expanded(child: SizedBox()),
        InkWell(
          onTap: () => Get.toNamed(RouteHelper.getStoreReviewRoute(store.id)),
          child: Column(children: [
            Row(children: [
              Icon(Icons.star, color: Theme.of(context).primaryColor, size: 20),
              SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
              Text(
                store.avgRating.toStringAsFixed(1),
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: _textColor),
              ),
            ]),
            SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
            Text(
              '${store.ratingCount} ${'ratings'.tr}',
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: _textColor),
            ),
          ]),
        ),
        Expanded(child: SizedBox()),
        InkWell(
          onTap: () => Get.toNamed(RouteHelper.getMapRoute(
            AddressModel(
              id: store.id, address: store.address, latitude: store.latitude,
              longitude: store.longitude, contactPersonNumber: '', contactPersonName: '', addressType: '',
            ), 'store',
          )),
          child: Column(children: [
            Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 20),
            SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
            Text('location'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: _textColor)),
          ]),
        ),
        Expanded(child: SizedBox()),
        InkWell(
          onTap: () => _launchWhatsapp(context, store),
          //     Get.toNamed(RouteHelper.getMapRoute(
          //   AddressModel(
          //     id: store.id, address: store.address, latitude: store.latitude,
          //     longitude: store.longitude, contactPersonNumber: '', contactPersonName: '', addressType: '',
          //   ), 'store',
          // )),
          child: Column(children: [
            Icon(Icons.whatsapp, color: Theme.of(context).primaryColor, size: 20),
            SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
            Text('Chat'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: _textColor)),
          ]),
        ),
        Expanded(child: SizedBox()),
        Column(children: [
          Row(children: [
            Icon(Icons.timer, color: Theme.of(context).primaryColor, size: 20),
            SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
            Text(
              store.deliveryTime,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: _textColor),
            ),
          ]),
          SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
          Text('delivery_time'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: _textColor)),
        ]),

        (store.delivery && store.freeDelivery) ? Expanded(child: SizedBox()) : SizedBox(),
        (store.delivery && store.freeDelivery) ? Column(children: [
          Icon(Icons.money_off, color: Theme.of(context).primaryColor, size: 20),
          SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
          Text('free_delivery'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: _textColor)),
        ]) : SizedBox(),
        Expanded(child: SizedBox()),
      ]),
    ]);
  }
}
