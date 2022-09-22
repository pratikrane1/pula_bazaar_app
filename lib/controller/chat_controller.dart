
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/data/api/api_checker.dart';
import 'package:sixam_mart/data/api/api_client.dart';
import 'package:sixam_mart/data/model/response/chat_model.dart';
import 'package:sixam_mart/data/model/response/order_model.dart';
import 'package:sixam_mart/data/repository/chat_repo.dart';

class ChatController extends GetxController implements GetxService{
  final ChatRepo chatRepo;
  ChatController({@required this.chatRepo});

  List<bool> _showDate;
  List<XFile> _imageFiles;
  bool _isSendButtonActive = false;
  bool _isSeen = false;
  bool _isSend = true;
  bool _isMe = false;
  bool _isLoading= false;
  bool get isLoading => _isLoading;

  List<bool> get showDate => _showDate;
  List<XFile> get imageFiles => _imageFiles;
  bool get isSendButtonActive => _isSendButtonActive;
  bool get isSeen => _isSeen;
  bool get isSend => _isSend;
  bool get isMe => _isMe;
  List<Messages>  _deliveryManMessage = [];
  List<Messages>  _messageList = [];
  List<Messages> get messageList => _messageList;
  List<Messages> get deliveryManMessage => _deliveryManMessage;
  List<Messages>  _adminManMessage = [];
  List<Messages> get adminManMessages => _adminManMessage;
  List <XFile>_chatImage = [];
  List<XFile> get chatImage => _chatImage;

  Future<void> getMessages(int offset, OrderModel orderModel, bool isFirst, {bool isStore = false}) async {
    if(isStore){
      print('Come to chat with restaurant');
    }
    Response _response;
    if(isFirst) {
      _messageList = [];
    }
    if(orderModel == null) {
      print('=================Come to chat with admin=============');
      _response = await chatRepo.getAdminMessage(offset);
    }else {
      if(isStore){
        print('======================Come to chat with restaurant===================');
        _response = await chatRepo.getStoreMessage(orderModel.store.id, 1);
      }else{
        print('=================Come to chat with deliveryman====================');
        _response = await chatRepo.getDeliveryManMessage(orderModel.id, 1);
      }
    }
    if (_response != null&& _response.body['messages'] != {} && _response.statusCode == 200) {
      _messageList = [];
      _messageList.addAll(ChatModel.fromJson(_response.body).messages);
    } else {
      ApiChecker.checkApi(_response);
    }
    update();
  }


  void pickImage(bool isRemove) async {
    if(isRemove) {
      _imageFiles = [];
      _chatImage = [];
    }else {
      _imageFiles = await ImagePicker().pickMultiImage(imageQuality: 40);
      if (_imageFiles != null) {
        _chatImage = imageFiles;
        _isSendButtonActive = true;
      }
    }
    update();
  }
  void removeImage(int index){
    chatImage.removeAt(index);
    update();
  }

  Future<Response> sendMessage({@required String message, @required OrderModel order, @required bool isStore}) async {
    Response _response;
    _isLoading = true;
    update();

    List<MultipartBody> _myImages = [];
    _chatImage.forEach((image) {
      _myImages.add(MultipartBody('images[]', image));
    });

    if(order == null) {
      _response = await chatRepo.sendMessageToAdmin(message, _myImages);
    }else {
      if(isStore){
        _response = await chatRepo.sendMessageToRestaurant(message, _myImages, order.store.id);
      }else{
        _response = await chatRepo.sendMessageToDeliveryMan(message, _myImages, order.deliveryMan.id);
      }
    }
    print(_response.statusCode);
    if (_response.statusCode == 200) {
      if(order == null) {
        getMessages(1, order, false, isStore: false);
        print('---------again call admin---------');
      }else {
        if(isStore){
          getMessages(1, order, false, isStore: true);
          print('---------again call restaurant---------');
        }else{
          getMessages(1, order, false);
          print('---------again call deliveryman---------');
        }
      }
      _isLoading = false;
    }
    _imageFiles = [];
    _chatImage = [];
    _isSendButtonActive = false;
    update();
    _isLoading = false;
    return _response;
  }

  void toggleSendButtonActivity() {
    _isSendButtonActive = !_isSendButtonActive;
    update();
  }

  void setImageList(List<XFile> images) {
    _imageFiles = [];
    _imageFiles = images;
    _isSendButtonActive = true;
    update();
  }

  void setIsMe(bool value) {
    _isMe = value;
  }

}