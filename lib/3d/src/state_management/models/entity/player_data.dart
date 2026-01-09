import 'package:uuid/uuid.dart';

var uuid = Uuid();
class PlayerData {
  String id;
  PlayerData({String? id}) : id = id ?? const Uuid().v4();
}