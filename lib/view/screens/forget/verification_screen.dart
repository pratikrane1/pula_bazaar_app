import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:phone_number/phone_number.dart';
import 'package:sixam_mart/controller/auth_controller.dart';
import 'package:sixam_mart/controller/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/view/base/custom_app_bar.dart';
import 'package:sixam_mart/view/base/custom_button.dart';
import 'package:sixam_mart/view/base/custom_dialog.dart';
import 'package:sixam_mart/view/base/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sixam_mart/view/base/footer_view.dart';
import 'package:sixam_mart/view/base/menu_drawer.dart';

class VerificationScreen extends StatefulWidget {
  final String number;
  final bool fromSignUp;
  final String countryCode;
  final String token;
  final String password;
  VerificationScreen({@required this.countryCode,@required this.number, @required this.password, @required this.fromSignUp,
    @required this.token});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String _number;
  Timer _timer;
  int _seconds = 0;
  var otp;
  AuthCredential authservice;
  UserCredential authResult;
  var number,firebaseUser_Id;
  String authStatus="",deviceId="",token="";
  String pass='12345678';
  final TextEditingController _otpController = TextEditingController();
  bool loading = false;
  var verificationId;







  @override
  void initState() {
    super.initState();

    _number = widget.number.startsWith('+') ? widget.countryCode+widget.number : '+'+widget.countryCode+widget.number;
    verificationId = widget.token ?? '';
    _startTimer();

  }

  void _startTimer() {
    _seconds = 60;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _seconds = _seconds - 1;
      if(_seconds == 0) {
        timer?.cancel();
        _timer?.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();

    _timer?.cancel();
  }

  Future<dynamic> checkotp(dynamic phone,AuthController authController,String verificationId) async {
    otp = authController.verificationCode;

    if (verificationId != null && otp != null) {
      try {
        // authservice =await FirebaseAuth.instance(
        //     PhoneAuthProvider.credential(
        //   verificationId: verificationId,
        //   smsCode: otp,
        // ));
        authservice =
            PhoneAuthProvider.credential(
              verificationId: verificationId,
              smsCode: otp,
            );
      } catch (e) {
        print(e);
      }
    }
    // call signin method
    signIn(authservice,authController, phone);
  }

  signIn(AuthCredential credential,AuthController authController, phone) async {
    authResult = await FirebaseAuth.instance
        .signInWithCredential(credential)
        .catchError((onError) {
      print('SignIn Error: ${onError.toString()}\n\n');
    });

    if (authResult != null) {
      firebaseUser_Id=authResult.user.uid.toString();

      print("fb_id"+firebaseUser_Id);
      _login(authController, widget.number);

    } else {
      // Fluttertoast.showToast(msg: 'Please enter valid sms code');
      showCustomSnackBar('Please enter valid sms code');
    }
  }

  Future<void> verifyPhoneNumber(BuildContext context,AuthController authController,String number) async {

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: number,
        timeout: const Duration(seconds: 15),
        verificationCompleted: (AuthCredential authCredential) {
          //  signIn(authCredential);
          print('verfication completed called sent called');
          // _otpController.text = authCredential.token.toString();
        },
        verificationFailed: (FirebaseAuthException authException) {
          print(authException.message.toString() + "Inside auth failed");
          setState(() {
            authStatus = authException.message;
          });
          if (authStatus != "") {
            showCustomSnackBar(authStatus);
          }
        },
        codeSent: (String verId, [int forceCodeResent]) {
          setState(() {

            verificationId = verId;
            loading = false;
            // checkotp(number,authController,verificationId);
          });
        },
        codeAutoRetrievalTimeout: (String verId) {

          setState(() {
            authStatus = "TIMEOUT";
          });
        },
      );
    }catch(e){
      print(e);
      showCustomSnackBar(e);
    }

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'otp_verification'.tr),
      endDrawer: MenuDrawer(),
      body: SafeArea(child: Center(child: Scrollbar(child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: FooterView(child: Container(
          width: context.width > 700 ? 700 : context.width,
          padding: context.width > 700 ? EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT) : null,
          margin: context.width > 700 ? EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT) : null,
          decoration: context.width > 700 ? BoxDecoration(
            color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
            boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 700 : 300], blurRadius: 5, spreadRadius: 1)],
          ) : null,
          child: GetBuilder<AuthController>(builder: (authController) {
            return Column(children: [

              Get.find<SplashController>().configModel.demo ? Text(
                'for_demo_purpose'.tr, style: robotoRegular,
              ) : RichText(text: TextSpan(children: [
                TextSpan(text: 'enter_the_verification_sent_to'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
                TextSpan(text: ' $_number', style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyText1.color)),
              ]), textAlign: TextAlign.center),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 35),

                child: PinCodeTextField(
                  controller: _otpController,
                  length: 6,
                  appContext: context,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.slide,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    fieldHeight: 55,
                    fieldWidth: 55,
                    borderWidth: 1,
                    borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    selectedFillColor: Colors.white,
                    inactiveFillColor: Theme.of(context).disabledColor.withOpacity(0.2),
                    inactiveColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    activeColor: Theme.of(context).primaryColor.withOpacity(0.4),
                    activeFillColor: Theme.of(context).disabledColor.withOpacity(0.2),
                  ),
                  animationDuration: Duration(milliseconds: 300),
                  backgroundColor: Colors.transparent,
                  enableActiveFill: true,
                  onChanged: authController.updateVerificationCode,
                  beforeTextPaste: (text) => true,
                ),
              ),



              // (widget.password != null && widget.password.isNotEmpty) ?
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  'did_not_receive_the_code'.tr,
                  style: robotoRegular.copyWith(color: Theme.of(context).disabledColor),
                ),
                TextButton(
                  onPressed: _seconds < 1 ? () {
                    _startTimer();
                    verifyPhoneNumber(context,authController, _number);

                    // if(widget.fromSignUp) {
                    //   authController.login(_number, widget.password).then((value) {
                    //     if (value.isSuccess) {
                    //       _startTimer();
                    //       showCustomSnackBar('resend_code_successful'.tr, isError: false);
                    //     } else {
                    //       showCustomSnackBar(value.message);
                    //     }
                    //   });
                    // }else {
                    //   authController.forgetPassword(_number).then((value) {
                    //     if (value.isSuccess) {
                    //       _startTimer();
                    //       showCustomSnackBar('resend_code_successful'.tr, isError: false);
                    //     } else {
                    //       showCustomSnackBar(value.message);
                    //     }
                    //   });
                    // }
                  } : null,
                  child: Text('${'resend'.tr}${_seconds > 0 ? ' ($_seconds)' : ''}'),
                ),
              ]) ,
                  // : SizedBox(),

              authController.verificationCode.length == 6 ? !authController.isLoading ? Padding(
                padding: const EdgeInsets.all(10.0),
                child: CustomButton(
                  buttonText: 'verify'.tr,
                  onPressed: () async {
                    otp = authController.verificationCode;
                    // checkotp(widget.number,widget.token.toString());

                  if (verificationId != null && otp != null) {
                        try {
                          // authservice =await FirebaseAuth.instance(
                          //     PhoneAuthProvider.credential(
                          //   verificationId: verificationId,
                          //   smsCode: otp,
                          // ));
                          authservice =
                              PhoneAuthProvider.credential(
                                verificationId: verificationId,
                                smsCode: otp,
                              );
                        } catch (e) {
                          print(e);
                          showCustomSnackBar(e);
                        }

                        if (authservice != null){
                          authResult = await FirebaseAuth.instance
                              .signInWithCredential(authservice)
                              .catchError((onError) {
                            print('SignIn Error: ${onError.toString()}\n\n');
                          });

                          if (authResult != null) {
                            firebaseUser_Id=authResult.user.uid.toString();

                            print("fb_id"+firebaseUser_Id);
                            _login(authController, widget.number);

                          } else {
                            showCustomSnackBar('Please enter valid sms code');
                          }
                        }
                      }
                      // call signin method
                      // signIn(authservice, phone);




                    // if(widget.fromSignUp) {
                    //   authController.verifyPhone(_number, widget.token).then((value) {
                    //     if(value.isSuccess) {
                    //       showAnimatedDialog(context, Center(
                    //         child: Container(
                    //           width: 300,
                    //           padding: EdgeInsets.all(Dimensions.PADDING_SIZE_EXTRA_LARGE),
                    //           decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.RADIUS_EXTRA_LARGE)),
                    //           child: Column(mainAxisSize: MainAxisSize.min, children: [
                    //             Image.asset(Images.checked, width: 100, height: 100),
                    //             SizedBox(height: Dimensions.PADDING_SIZE_LARGE),
                    //             Text('verified'.tr, style: robotoBold.copyWith(
                    //               fontSize: 30, color: Theme.of(context).textTheme.bodyText1.color,
                    //               decoration: TextDecoration.none,
                    //             )),
                    //           ]),
                    //         ),
                    //       ), dismissible: false);
                    //       Future.delayed(Duration(seconds: 2), () {
                    //         Get.offNamed(RouteHelper.getAccessLocationRoute('verification'));
                    //       });
                    //     }else {
                    //       showCustomSnackBar(value.message);
                    //     }
                    //   });
                    // }else {
                    //   authController.verifyToken(_number).then((value) {
                    //     if(value.isSuccess) {
                    //       Get.toNamed(RouteHelper.getResetPasswordRoute(_number, authController.verificationCode, 'reset-password'));
                    //     }else {
                    //       showCustomSnackBar(value.message);
                    //     }
                    //   });
                    // }
                  },
                ),
              ) : Center(child: CircularProgressIndicator()) : SizedBox.shrink(),

            ]);
          }),
        )),
      )))),
    );
  }

  void _login(AuthController authController, String countryDialCode) async {
    String _numberWithCountryCode =  '+'+widget.countryCode.trim()+widget.number.trim();
    bool _isValid = GetPlatform.isWeb ? true : false;

    // PhoneNumber phoneNumber = await PhoneNumberUtil().parse(_number);
    if(!GetPlatform.isWeb) {
      try {
        PhoneNumber phoneNumber =
        await PhoneNumberUtil().parse(_numberWithCountryCode);
        _numberWithCountryCode =
            '+' + phoneNumber.countryCode + phoneNumber.nationalNumber;
         // phoneNumber = await PhoneNumberUtil().parse(widget.number);
        // _number;
        _isValid = true;
      } catch (e) {}
    }

      // if(!_isValid){
      //   showCustomSnackBar('invalid_phone_number'.tr);
      // }
      // else{
        authController.login(_numberWithCountryCode, pass).then((status) async {
          if (status.isSuccess) {
            if (authController.isActiveRememberMe) {
              authController.saveUserNumberAndPassword(
                  widget.number, pass, widget.countryCode);
            } else {
              authController.clearUserNumberAndPassword();
            }
            String _token = status.message.substring(1, status.message.length);
            // if(Get.find<SplashController>().configModel.customerVerification && int.parse(status.message[0]) == 0) {
            //   List<int> _encoded = utf8.encode(widget.password);
            //   String _data = base64Encode(_encoded);
            //   Get.toNamed(RouteHelper.getVerificationRoute(_numberWithCountryCode, number, _token, RouteHelper.signUp, _data));
            // }else {
            Get.toNamed(RouteHelper.getAccessLocationRoute('sign-in'));
            // }
          } else {
            Get.toNamed(RouteHelper.getSignUpRoute(_number));
            // showCustomSnackBar(status.message);
          }
        });
      // }

  }

}
