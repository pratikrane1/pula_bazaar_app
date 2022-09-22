import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/controller/auth_controller.dart';
import 'package:sixam_mart/controller/chat_controller.dart';
import 'package:sixam_mart/controller/splash_controller.dart';
import 'package:sixam_mart/controller/user_controller.dart';
import 'package:sixam_mart/data/model/response/order_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/view/base/custom_image.dart';
import 'package:sixam_mart/view/base/custom_snackbar.dart';
import 'package:sixam_mart/view/base/menu_drawer.dart';
import 'package:sixam_mart/view/base/not_logged_in_screen.dart';
import 'package:sixam_mart/view/base/web_menu_bar.dart';
import 'package:sixam_mart/view/screens/chat/widget/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final OrderModel orderModel;
  final bool isStore;
  const ChatScreen({Key key, @required this.orderModel, @required this.isStore}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputMessageController = TextEditingController();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool _isLoggedIn;
  bool _isFirst = true;
  StreamSubscription _stream;

  @override
  void initState() {
    super.initState();

    if(!kIsWeb){

      _stream = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Message get from notification: ${message.data}");
        Get.find<ChatController>().getMessages(1, widget.orderModel, false, isStore: widget.isStore);
      });
    }

    _isLoggedIn = Get.find<AuthController>().isLoggedIn();

    if(_isLoggedIn){
      if(_isFirst) {
        Get.find<ChatController>().getMessages(1, widget.orderModel, true, isStore: widget.isStore);
      }else {
        Get.find<ChatController>().getMessages(1, widget.orderModel, false, isStore: widget.isStore);
        _isFirst = false;
      }
      if(Get.find<UserController>().userInfoModel == null){
        Get.find<UserController>().getUserInfo();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _stream.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final bool _isAdmin = widget.orderModel == null ? true : false;

    return Scaffold(
      endDrawer: MenuDrawer(),
      appBar: ResponsiveHelper.isDesktop(context) ? WebMenuBar()
        : AppBar(title: _isAdmin ? Text('${Get.find<SplashController>().configModel.businessName}')
          : widget.isStore ? Text(widget.orderModel.store.name)
          : Text(widget.orderModel.deliveryMan.fName +' '+ widget.orderModel.deliveryMan.lName),
          backgroundColor: Theme.of(context).primaryColor,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(width: 40,height: 40,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(width: 2,color: Theme.of(context).cardColor),
                    color: Theme.of(context).cardColor),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: CustomImage(
                    image: _isAdmin ? '${Get.find<SplashController>().configModel.baseUrls.businessLogoUrl}/${(Get.find<SplashController>().configModel.logo ?? '')}' : widget.isStore
                        ? '${Get.find<SplashController>().configModel.baseUrls.storeImageUrl}/${(widget.orderModel.store.logo ?? '')}'
                        : '${Get.find<SplashController>().configModel.baseUrls.deliveryManImageUrl}/${(widget.orderModel.deliveryMan.image ?? '')}',
                  ),
                ),
              ),
            )
          ]),

      body: _isLoggedIn ? SafeArea(
        child: Center(
          child: Container(
            width: ResponsiveHelper.isDesktop(context) ? Dimensions.WEB_MAX_WIDTH : MediaQuery.of(context).size.width,
            child: Column(children: [

              GetBuilder<ChatController>(builder: (chatController) {
                return Expanded(
                  child: chatController.messageList != null ? chatController.messageList.length > 0 ? ListView.builder(
                      reverse: true,
                      physics: AlwaysScrollableScrollPhysics(),
                      itemCount: chatController.messageList.length,
                      itemBuilder: (context, index){
                        return MessageBubble(messages: chatController.messageList[index], isAdmin: _isAdmin, orderModel: widget.orderModel, isStore: widget.isStore);
                      }) : SizedBox() : Center(child: CircularProgressIndicator()),
                );
              }),

              Container(
                color: Theme.of(context).cardColor,
                child: Column(children: [

                  GetBuilder<ChatController>(builder: (chatController) {

                    return chatController.chatImage.length > 0 ? Container(height: 100,
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemCount: chatController.chatImage.length,
                          itemBuilder: (BuildContext context, index){
                            return  chatController.chatImage.length > 0?
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Stack(children: [

                                Container(width: 100, height: 100,
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(20))),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.all(Radius.circular(Dimensions.PADDING_SIZE_DEFAULT)),
                                    child: ResponsiveHelper.isWeb()
                                        ? Image.network(
                                      chatController.chatImage[index].path, width: 100, height: 100, fit: BoxFit.cover,
                                    ) : Image.file(
                                      File(chatController.chatImage[index].path), width: 100, height: 100, fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                                Positioned(top:0, right:0,
                                  child: InkWell(
                                    onTap : () => chatController.removeImage(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(Radius.circular(Dimensions.PADDING_SIZE_DEFAULT))
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(Icons.clear, color: Colors.red, size: 15),
                                      ),
                                    ),
                                  ),
                                )],
                              ),
                            ) : SizedBox();
                          }),
                    ) : SizedBox();
                  }),

                  Row(children: [

                    InkWell(
                      onTap: () async {
                        Get.find<ChatController>().pickImage(false);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_DEFAULT),
                        child: Image.asset(Images.image, width: 25, height: 25, color: Theme.of(context).hintColor),
                      ),
                    ),

                    SizedBox(
                      height: 25,
                      child: VerticalDivider(width: 0, thickness: 1, color: Theme.of(context).hintColor),
                    ),
                    SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),

                    Expanded(
                      child: TextField(
                        inputFormatters: [LengthLimitingTextInputFormatter(Dimensions.MESSAGE_INPUT_LENGTH)],
                        controller: _inputMessageController,
                        textCapitalization: TextCapitalization.sentences,
                        style: robotoRegular,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'type_here'.tr,
                          hintStyle: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeLarge),
                        ),
                        onSubmitted: (String newText) {
                          if(newText.trim().isNotEmpty && !Get.find<ChatController>().isSendButtonActive) {
                            Get.find<ChatController>().toggleSendButtonActivity();
                          }else if(newText.isEmpty && Get.find<ChatController>().isSendButtonActive) {
                            Get.find<ChatController>().toggleSendButtonActivity();
                          }
                        },
                        onChanged: (String newText) {
                          if(newText.trim().isNotEmpty && !Get.find<ChatController>().isSendButtonActive) {
                            Get.find<ChatController>().toggleSendButtonActivity();
                          }else if(newText.isEmpty && Get.find<ChatController>().isSendButtonActive) {
                            Get.find<ChatController>().toggleSendButtonActivity();
                          }
                        },
                      ),
                    ),

                    GetBuilder<ChatController>(builder: (chatController) {
                      return InkWell(
                        onTap: () async {
                          if(chatController.isSendButtonActive){
                            await chatController.sendMessage(message: _inputMessageController.text, order: widget.orderModel, isStore: widget.isStore);
                            _inputMessageController.clear();
                            chatController.toggleSendButtonActivity();
                          }else{
                            showCustomSnackBar('write_somethings'.tr);
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_DEFAULT),
                          child: chatController.isLoading ? SizedBox(
                            width: 25, height: 25,
                            child: CircularProgressIndicator(),
                          ) : Image.asset(
                            Images.send, width: 25, height: 25,
                            color: chatController.isSendButtonActive ? Theme.of(context).primaryColor : Theme.of(context).hintColor,
                          ),
                        ),
                      );
                    }
                    ),

                  ]),
                ]),
              ),
            ],
            ),
          ),
        ),
      ) : NotLoggedInScreen(),
    );
  }
}
