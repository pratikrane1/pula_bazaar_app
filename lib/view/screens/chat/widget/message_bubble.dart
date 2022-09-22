import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/controller/splash_controller.dart';
import 'package:sixam_mart/controller/user_controller.dart';
import 'package:sixam_mart/data/model/response/chat_model.dart';
import 'package:sixam_mart/data/model/response/config_model.dart';
import 'package:sixam_mart/data/model/response/order_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/view/base/custom_image.dart';
import 'package:sixam_mart/view/screens/chat/widget/image_dialog.dart';

class MessageBubble extends StatefulWidget {
  final Messages messages;
  final bool isAdmin;
  final OrderModel orderModel;
  final bool isStore;

  const MessageBubble({Key key, this.messages, this.isAdmin, this.orderModel, this.isStore}) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  String _receiverName;
  String _receiverImage;
  BaseUrls _baseUrl;

  @override
  Widget build(BuildContext context) {

    _baseUrl = Get.find<SplashController>().configModel.baseUrls;

    if(widget.messages.isReply == 1){

      if(widget.messages.adminId != null && widget.isAdmin && !widget.isStore){
        print('admin chat start');
        _receiverName = Get.find<SplashController>().configModel.businessName;
        _receiverImage = _baseUrl.businessLogoUrl+'/'+(Get.find<SplashController>().configModel.logo ?? '');
      }
      else if(widget.messages.deliverymanId != null && !widget.isStore){
        print('deliveryman chat start');

        _receiverName = widget.orderModel.deliveryMan.fName + ' ' + widget.orderModel.deliveryMan.lName;
        _receiverImage = _baseUrl.deliveryManImageUrl+'/'+(widget.orderModel.deliveryMan.image ?? '');
      }
      else if(widget.messages.restaurantId != null && widget.isStore){
        print('store chat start');

        _receiverName = widget.orderModel.store.name;
        _receiverImage = _baseUrl.storeImageUrl+'/'+(widget.orderModel.store.logo ?? '');
      }
    }

    return (widget.messages.isReply != null && widget.messages.isReply == 1) ?
    Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_DEFAULT, vertical: Dimensions.PADDING_SIZE_EXTRA_SMALL),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.PADDING_SIZE_SMALL)),
      padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Text(_receiverName ?? '', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge)),
        SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

        Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [

          ClipRRect(
            child: CustomImage(
              fit: BoxFit.cover, width: 40, height: 40,
              image: _receiverImage,
            ),
            borderRadius: BorderRadius.circular(20.0),
          ),
          SizedBox(width: 10),

          Flexible(
            child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  if(widget.messages.isReply != null && widget.messages.isReply == 1)  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).secondaryHeaderColor,
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(Dimensions.RADIUS_DEFAULT),
                          topRight: Radius.circular(Dimensions.RADIUS_DEFAULT),
                          bottomLeft: Radius.circular(Dimensions.RADIUS_DEFAULT),
                        ),
                      ),
                      padding: EdgeInsets.all(widget.messages.message != null ? Dimensions.PADDING_SIZE_DEFAULT : 0),
                      child: Text(widget.messages.message??''),
                    ),
                  ),
                  SizedBox(height: 8.0),

                  widget.messages.image != null ? GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          childAspectRatio: 1,
                          crossAxisCount: ResponsiveHelper.isDesktop(context) ? 8 : 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 5
                      ),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: widget.messages.image.length,
                      itemBuilder: (BuildContext context, index){
                        return  widget.messages.image.length > 0 ? Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            hoverColor: Colors.transparent,
                            onTap: () => showDialog(context: context, builder: (ctx) => ImageDialog(imageUrl: '${_baseUrl.chatImageUrl}/${widget.messages.image[index]}')),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Dimensions.PADDING_SIZE_SMALL),
                              child: CustomImage(
                                height: 100, width: 100, fit: BoxFit.cover,
                                image: '${_baseUrl.chatImageUrl}/${widget.messages.image[index] ?? ''}',
                              ),
                            ),
                          ),
                        ) : SizedBox();

                      }) : SizedBox(),
                ]),
          ),
        ]),
        SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

        Text(
          DateConverter.localDateToIsoStringAMPM(DateTime.parse(widget.messages.createdAt)),
          style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
        ),
      ]),
    )

    : Container(
      padding: const EdgeInsets.symmetric(horizontal:Dimensions.PADDING_SIZE_DEFAULT),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.PADDING_SIZE_SMALL)),
      child: GetBuilder<UserController>(builder: (profileController) {

        return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${profileController.userInfoModel != null ? profileController.userInfoModel.fName ?? '' : ''} '
                '${profileController.userInfoModel != null ? profileController.userInfoModel.lName ?? '' : ''}',
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
          ),
          SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

          Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [

            Flexible(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [

                (widget.messages.message != null && widget.messages.message.isNotEmpty) ? Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(Dimensions.RADIUS_DEFAULT),
                        bottomRight: Radius.circular(Dimensions.RADIUS_DEFAULT),
                        bottomLeft: Radius.circular(Dimensions.RADIUS_DEFAULT),
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(widget.messages.message != null ? Dimensions.PADDING_SIZE_DEFAULT : 0),
                      child: Text(widget.messages.message??''),
                    ),
                  ),
                ) : SizedBox(),

                widget.messages.image != null ? Directionality(
                  textDirection: TextDirection.rtl,
                  child: GridView.builder(
                      reverse: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          childAspectRatio: 1,
                          crossAxisCount: ResponsiveHelper.isDesktop(context) ? 8 : 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 5
                      ),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: widget.messages.image.length,
                      itemBuilder: (BuildContext context, index){
                        return  widget.messages.image.length > 0 ?
                        InkWell(
                          onTap: () => showDialog(context: context, builder: (ctx)  =>  ImageDialog(imageUrl: '${_baseUrl.chatImageUrl}/${widget.messages.image[index] ?? ''}')),
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: Dimensions.PADDING_SIZE_SMALL , right:  0,
                              top: (widget.messages.message != null && widget.messages.message.isNotEmpty) ? Dimensions.PADDING_SIZE_SMALL : 0,                                       ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                              child: CustomImage(
                                height: 100, width: 100, fit: BoxFit.cover,
                                image: '${_baseUrl.chatImageUrl}/${widget.messages.image[index] ?? ''}',
                              ),
                            ),
                          ),
                        ) : SizedBox();
                      }),
                ) : SizedBox(),
              ]),
            ),
            SizedBox(width: Dimensions.PADDING_SIZE_SMALL),

            ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: CustomImage(
                fit: BoxFit.cover, width: 40, height: 40,
                image: profileController.userInfoModel != null ? '${_baseUrl.customerImageUrl}/${profileController.userInfoModel.image}' : '',
              ),
            ),
          ]),

          Icon(
            widget.messages.checked == 0 ? Icons.check : Icons.done_all,
            size: 12,
            color: widget.messages.checked == 0 ? Theme.of(context).disabledColor : Theme.of(context).primaryColor,
          ),
          SizedBox(height: Dimensions.PADDING_SIZE_SMALL),

          Text(
            DateConverter.localDateToIsoStringAMPM(DateTime.parse(widget.messages.createdAt)),
            style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
          ),
          SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),

        ]);
      }),
    );
  }
}
