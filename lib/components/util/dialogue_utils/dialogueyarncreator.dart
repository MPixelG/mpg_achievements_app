
import 'package:flame/components.dart';
import 'package:jenny/jenny.dart';

abstract class DialogueYarnCreator extends Component {

  late YarnProject projectDialogue;
  late String yarnFilePath;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final projectDialogue = _loadYarnFile(yarnFilePath);
    print(projectDialogue);
  }
// Parse the Yarn script into a YarnProject
  Future<YarnProject> _loadYarnFile(String yarnfile) async {
    final yarntest = '''
      title: Start
      ---
      Hello there!
      -> How are you?
      <<jump Happy>>
      -> Go away!
      <<jump Angry>>
      ===
      title: Happy
      ---
      I'm glad to hear that!
      ===
      title: Angry
      ---
      Oh... sorry to bother you.
      ===
    ''';

    final YarnProject project = YarnProject()
      ..parse(yarntest);


    return project;
  }




}






