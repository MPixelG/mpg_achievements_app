import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/menuBar/dropdown_menu_button.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/menuBar/menu_bar.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/menuBar/menu_bar_button.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/logic_nodes.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/window_system.dart';

///Editor overlay with Window System
class Editor3DOverlay extends StatelessWidget {
  final String id;

  const Editor3DOverlay({required this.id, super.key});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        top: 32,
        child: SizedBox(width: MediaQuery.widthOf(context), height: MediaQuery.heightOf(context) - 33, child: getEditorController(id).windowManager),
      ),
      const EditorMenuBarTest(),

    ],
  ); //uses the window manager of the controller as the widget to show. this way we dont cache widgets directly and dont use states either
}

//the EditorController class. Acts basically as a state for the Editor Overlay. we cant use a state because otherwise the state would get deleted when we hide the Overlay
class EditorController {
  final WindowManager windowManager = WindowManager(
    controller: WindowManagerController(
      loadNodeFromJson({
        "windowType": "windowSplit",
        "proportions": [0.25, 0.75],
        "direction": "horizontal",
        "children": [
          {
            "windowType": "windowLeaf",
            "config": {"id": "test1"},
          },
          {
            "windowType": "windowSplit",
            "proportions": [0.5, 0.5],
            "direction": "vertical",
            "children": [
              {
                "windowType": "windowLeaf",
                "config": {"id": "test1"},
              },
              {
                "windowType": "windowLeaf",
                "config": {"id": "test2"},
              },
            ],
          },
        ],
      }),
    ),
  );
}

final Map<String, EditorController> _controllers = {};
EditorController getEditorController(String id) => _controllers[id] ??= EditorController();

///test menu bar (by claude lol)
class EditorMenuBarTest extends StatelessWidget {
  const EditorMenuBarTest({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.grey[900],
            child: const Center(
              child: Text(
                'Editor Content',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          EditorMenuBar(
            menuBarObjects: [
              DropdownMenuButton(
                label: 'File',
                dropdownWidgets: [
                  _buildMenuItem(
                    context,
                    icon: Icons.insert_drive_file,
                    label: 'New',
                    onTap: () => print('New clicked'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.folder_open,
                    label: 'Open',
                    onTap: () => print('Open clicked'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.save,
                    label: 'Save',
                    onTap: () => print('Save clicked'),
                  ),
                  DropdownMenuButton(
                    label: 'Export',
                    icon: Icons.upload_file,
                    isNested: true,
                    dropdownWidgets: [
                      _buildMenuItem(
                        context,
                        icon: Icons.picture_as_pdf,
                        label: 'Export as PDF',
                        onTap: () => print('Export PDF clicked'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.image,
                        label: 'Export as PNG',
                        onTap: () => print('Export PNG clicked'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.code,
                        label: 'Export as JSON',
                        onTap: () => print('Export JSON clicked'),
                      ),
                      DropdownMenuButton(
                        label: 'Advanced Export',
                        icon: Icons.settings,
                        isNested: true,
                        dropdownWidgets: [
                          _buildMenuItem(
                            context,
                            icon: Icons.compress,
                            label: 'Compressed',
                            onTap: () => print('Compressed export'),
                          ),
                          _buildMenuItem(
                            context,
                            icon: Icons.high_quality,
                            label: 'High Quality',
                            onTap: () => print('HQ export'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildMenuItem(
                    context,
                    icon: Icons.exit_to_app,
                    label: 'Exit',
                    onTap: () => print('Exit clicked'),
                  ),
                ],
              ),
              DropdownMenuButton(
                label: 'Edit',
                dropdownWidgets: [
                  _buildMenuItem(
                    context,
                    icon: Icons.undo,
                    label: 'Undo',
                    onTap: () => print('Undo clicked'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.redo,
                    label: 'Redo',
                    onTap: () => print('Redo clicked'),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildMenuItem(
                    context,
                    icon: Icons.content_cut,
                    label: 'Cut',
                    onTap: () => print('Cut clicked'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.content_copy,
                    label: 'Copy',
                    onTap: () => print('Copy clicked'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.content_paste,
                    label: 'Paste',
                    onTap: () => print('Paste clicked'),
                  ),
                  DropdownMenuButton(
                    label: 'Transform',
                    icon: Icons.transform,
                    isNested: true,
                    dropdownWidgets: [
                      _buildMenuItem(
                        context,
                        icon: Icons.rotate_90_degrees_ccw,
                        label: 'Rotate Left',
                        onTap: () => print('Rotate left'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.rotate_90_degrees_cw,
                        label: 'Rotate Right',
                        onTap: () => print('Rotate right'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.flip,
                        label: 'Flip',
                        onTap: () => print('Flip'),
                      ),
                    ],
                  ),
                ],
              ),
              DropdownMenuButton(
                label: 'View',
                dropdownWidgets: [
                  _buildMenuItem(
                    context,
                    icon: Icons.fullscreen,
                    label: 'Fullscreen',
                    onTap: () => print('Fullscreen clicked'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.grid_on,
                    label: 'Show Grid',
                    onTap: () => print('Show Grid clicked'),
                  ),
                  DropdownMenuButton(
                    label: 'Zoom',
                    icon: Icons.zoom_in,
                    isNested: true,
                    dropdownWidgets: [
                      _buildMenuItem(
                        context,
                        icon: Icons.add,
                        label: 'Zoom In',
                        onTap: () => print('Zoom in'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.remove,
                        label: 'Zoom Out',
                        onTap: () => print('Zoom out'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.fit_screen,
                        label: 'Fit to Screen',
                        onTap: () => print('Fit to screen'),
                      ),
                    ],
                  ),
                ],
              ),
              MenuBarButton(
                onPressed: () => print('Help clicked'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Help',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
}