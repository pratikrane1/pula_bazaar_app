import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GuestButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size(20, 50),
        side: BorderSide(color: Theme.of(context).primaryColor, width: 2),

      ),
      onPressed: () {
        Navigator.pushReplacementNamed(context, RouteHelper.getInitialRoute());
      },
      child: SizedBox(
        width: double.infinity,
        child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
          TextSpan(text: '${'skip'.tr} ', style: robotoBold.copyWith(color: Theme.of(context).primaryColor)),
          TextSpan(text: 'Login', style: robotoBold.copyWith(color: Theme.of(context).primaryColor)),
        ])),
      ),
    );
  }
}
