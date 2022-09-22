class ChatModel {
  int totalSize;
  int limit;
  int offset;
  List<Messages> messages;

  ChatModel({this.totalSize, this.limit, this.offset, this.messages});

  ChatModel.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'];
    limit = json['limit'];
    offset = json['offset'];
    if (json['messages'] != null) {
      messages = <Messages>[];
      json['messages'].forEach((v) {
        messages.add(new Messages.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_size'] = this.totalSize;
    data['limit'] = this.limit;
    data['offset'] = this.offset;
    if (this.messages != null) {
      data['messages'] = this.messages.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Messages {
  int id;
  int userId;
  int adminId;
  int restaurantId;
  int deliverymanId;
  String message;
  int checked;
  List<String> image;
  int isReply;
  String createdAt;
  String updatedAt;

  Messages({
    this.id,
    this.userId,
    this.adminId,
    this.restaurantId,
    this.deliverymanId,
    this.message,
    this.checked,
    this.image,
    this.isReply,
    this.createdAt,
    this.updatedAt,
  });

  Messages.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    adminId = json['admin_id'];
    restaurantId = json['restaurant_id'];
    deliverymanId = json['deliveryman_id'];
    message = json['message'];
    checked = json['checked'];
    if(json['image']!=null){
      image = json['image'].cast<String>();
    }
    isReply = json['is_reply'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['admin_id'] = this.adminId;
    data['restaurant_id'] = this.restaurantId;
    data['deliveryman_id'] = this.deliverymanId;
    data['message'] = this.message;
    data['checked'] = this.checked;
    data['image'] = this.image;
    data['is_reply'] = this.isReply;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;

    return data;
  }
}
