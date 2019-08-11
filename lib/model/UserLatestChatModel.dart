class UserLatestChatModel {

  static const String COUNT = 'ct';
  String toUserId;

  String key;

  dynamic value;

  UserLatestChatModel(this.toUserId, this.key, this.value);

  String toString() {
    return toUserId + ' key ' + key + ' value ' + value.toString();
  }
}
