import 'package:sixam_mart/data/model/response/address_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressWidget extends StatelessWidget {
  final AddressModel address;
  final bool fromAddress;
  final bool fromCheckout;
  final Function onRemovePressed;
  final Function onEditPressed;
  final Function onTap;
  AddressWidget({@required this.address, @required this.fromAddress, this.onRemovePressed, this.onEditPressed,
    this.onTap, this.fromCheckout = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_SMALL),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? Dimensions.PADDING_SIZE_DEFAULT
              : Dimensions.PADDING_SIZE_SMALL),
          decoration: BoxDecoration(
            color: fromCheckout ? null : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.RADIUS_LARGE),
            border: fromCheckout ? Border.all(color: Theme.of(context).disabledColor, width: 1) : Border.all(
                color: Color(0xFFC791C4),
                width: 1
            ),
            boxShadow: fromCheckout ? null : [BoxShadow(color: Colors.grey[Get.isDarkMode ? 800 : 200], blurRadius: 5, spreadRadius: 1)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              address.addressType == 'home' ? Icons.home_filled : address.addressType == 'office'
                  ? Icons.work : Icons.location_on,
              size: ResponsiveHelper.isDesktop(context) ? 50 : 40, color: Theme.of(context).primaryColor,
            ),
            SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  address.addressType.tr,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                Text(
                  address.address,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.black.withOpacity(0.5)),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
            // fromAddress ? IconButton(
            //   icon: Icon(Icons.edit, color: Colors.blue, size: ResponsiveHelper.isDesktop(context) ? 35 : 25),
            //   onPressed: onEditPressed,
            // ) : SizedBox(),
            fromAddress ? IconButton(
              icon: Icon(Icons.delete, color: Colors.red, size: ResponsiveHelper.isDesktop(context) ? 35 : 25),
              onPressed: onRemovePressed,
            ) : SizedBox(),
          ]),
        ),
      ),
    );
  }
}