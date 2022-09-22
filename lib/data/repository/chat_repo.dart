import 'package:get/get_connect/http/src/response/response.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/data/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ChatRepo {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  ChatRepo({@required this.apiClient, @required this.sharedPreferences});


  Future<Response> getDeliveryManMessage(int orderId,int offset) async {
    return await apiClient.getData('${AppConstants.GET_DELIVERYMAN_MESSAGE_URI}?offset=$offset&limit=100&order_id=$orderId');
  }

  Future<Response> getAdminMessage(int offset) async {
    return await apiClient.getData('${AppConstants.GET_ADMIN_MESSAGE_URL}?offset=$offset&limit=100');
  }

  Future<Response> getStoreMessage(int storeId, int offset) async {
    return await apiClient.getData('${AppConstants.GET_STORE_MESSAGE_URL}?store_id=$storeId&offset=$offset&limit=100');
  }

  Future<Response> sendMessageToDeliveryMan(String message, List<MultipartBody> images, int deliverymanId) async {
    return await apiClient.postMultipartData(AppConstants.SEND_MESSAGE_TO_DELIVERYMAN_URL, {'message': message, 'deliveryman_id': deliverymanId.toString()}, images);
  }

  Future<Response> sendMessageToAdmin(String message, List<MultipartBody> images) async {
    return await apiClient.postMultipartData(AppConstants.SEND_MESSAGE_TO_ADMIN_URL, {'message': message, 'admin_id': '1'}, images);
  }

  Future<Response> sendMessageToRestaurant(String message, List<MultipartBody> images, int restaurantId) async {
    return await apiClient.postMultipartData(AppConstants.SEND_MESSAGE_TO_STORE_URL+'?store_id=$restaurantId', {'message': message}, images);
  }

}