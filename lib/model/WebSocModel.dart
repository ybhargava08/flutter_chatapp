class WebSocModel {
  String type;

  String fromUserId;

  String toUserId;

  String chatId;

  String value;

static const String TYPING = 'typing';
static const String RECEIPT_DEL = 'delivery';
static const String ACK = 'ack';
static const String RECEIVED_FROM_SERVER = 'ReceivedFromServer';

  WebSocModel(this.type,this.fromUserId, this.toUserId, this.chatId, this.value);

  factory WebSocModel.fromJson(Map<String, dynamic> map) {
    return WebSocModel(
        map['type'],map['fromUserId'], map['toUserId'], map['chatId'], map['value']);
  }

  Map<String,dynamic> toJson() {
        Map<String,dynamic> map = Map();

         map['type'] = type;
         map['fromUserId'] = fromUserId;
         map['toUserId'] = toUserId; 
         map['chatId'] = chatId; 
         map['value'] = value;
         return map;
  }

  @override
  String toString() {
    
    return 'type '+type+' fromUserId '+getVal(fromUserId)+' toUserId '+getVal(toUserId)+' chatId ' +getVal(chatId)
    +' value '+getVal(value);
  }

  String getVal(String val) { 
       if(val == null) {
            return '';
       }
       return val;
  }
}
