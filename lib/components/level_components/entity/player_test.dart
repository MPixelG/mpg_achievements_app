/*
class TestPlayer extends IsometricPlayer{

  late KeyboardCharacterController<TestPlayer> controller;

  TestPlayer({required super.playerCharacter}){
    controller = KeyboardCharacterController(buildControlBundle());
  }

  @override
  Future<void> onLoad() async {
    add(controller);
    return super.onLoad();
  }


  @override
  ControlActionBundle<TestPlayer> buildControlBundle(){
    return ControlActionBundle<TestPlayer>({
      ControlAction("moveUp", key: "W", run: (parent) => parent.velocity.y--),
      ControlAction("moveLeft", key: "A", run: (parent) => parent.velocity.x--),
      ControlAction("moveDown", key: "S", run: (parent) => parent.velocity.z++),
      ControlAction("moveRight", key: "D", run: (parent) {
        parent.velocity.x++;
      }),
    });
  }
}*/
