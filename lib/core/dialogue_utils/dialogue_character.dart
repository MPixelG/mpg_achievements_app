import 'package:vector_math/vector_math_64.dart';

abstract interface class DialogueCharacter {
  Vector3 get worldPosition;
  String? get characterName;
  int? get entityId;
}