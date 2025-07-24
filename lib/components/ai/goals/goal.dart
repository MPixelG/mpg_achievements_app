import 'package:flame/components.dart';

abstract class Goal extends Component{


  double goalPriority;
  bool Function(double dt) prequisite;
  bool repeat;

  bool _done = false;


  Goal(this.prequisite, this.goalPriority, [this.repeat = true]);

  @override
  void update(double dt) {
    super.update(dt);
    if (_done) {
      removeFromParent();
    }
  }

  void updateGoal(double dt);
}