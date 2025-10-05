import 'package:flame/components.dart';

abstract class CharacterController extends Component{
  CharacterController();
}

enum ControlAction{
  moveUp, moveDown, moveRight, moveLeft, dRespawn, dTeleport, dImmortal, dNoClip, dShowGuiEditor
}