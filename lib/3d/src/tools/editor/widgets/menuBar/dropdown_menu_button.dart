import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/menuBar/menu_bar_button.dart';

class DropdownMenuButton extends StatefulWidget {
  final List<Widget> dropdownWidgets;
  final String label;
  final bool isNested;
  final IconData? icon;
  final VoidCallback? onChildDropdownChanged;
  final Function(bool)? onDropdownStateChanged;

  const DropdownMenuButton({
    super.key,
    required this.label,
    required this.dropdownWidgets,
    this.isNested = false,
    this.icon,
    this.onChildDropdownChanged,
    this.onDropdownStateChanged,
  });

  @override
  State<DropdownMenuButton> createState() => _DropdownMenuButtonState();
}

class _DropdownMenuButtonState extends State<DropdownMenuButton> {
  bool _isHovered = false;
  bool _isDropdownHovered = false;
  bool _hasActiveChild = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  bool get _shouldShowDropdown => _isHovered || _isDropdownHovered || _hasActiveChild;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _notifyParentOfStateChange() {
    widget.onDropdownStateChanged?.call(_shouldShowDropdown);
  }

  void _onChildDropdownStateChanged(bool isOpen) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _hasActiveChild = isOpen;
        });
        _updateOverlay();
        _notifyParentOfStateChange();
        widget.onChildDropdownChanged?.call();
      }
    });
  }

  void _removeOverlay() {
    final wasOpen = _overlayEntry != null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (wasOpen) {
      _notifyParentOfStateChange();
    }
  }

  void _updateOverlay() {
    final wasOpen = _overlayEntry != null;

    if (_shouldShowDropdown) {
      if (_overlayEntry == null) {
        _overlayEntry = _createOverlayEntry();
        Overlay.of(context).insert(_overlayEntry!);
        _notifyParentOfStateChange();
      }
    } else {
      _removeOverlay();
    }
  }

  OverlayEntry _createOverlayEntry() => OverlayEntry(
    builder: (context) => Positioned(
      width: 200,
      child: CompositedTransformFollower(
        link: _layerLink,
        targetAnchor: widget.isNested ? Alignment.topRight : Alignment.bottomLeft,
        followerAnchor: widget.isNested ? Alignment.topLeft : Alignment.topLeft,
        offset: widget.isNested
            ? const Offset(-2, 0)
            : const Offset(0, 0),
        child: MouseRegion(
          onEnter: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isDropdownHovered = true;
                });
                _notifyParentOfStateChange();
                widget.onChildDropdownChanged?.call();
              }
            });
          },
          onExit: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isDropdownHovered = false;
                });
                Future.delayed(const Duration(milliseconds: 10), () {
                  if (mounted) {
                    _updateOverlay();
                    widget.onChildDropdownChanged?.call();
                  }
                });
              }
            });
          },
          child: Material(
            elevation: 8,
            color: Colors.black87.withAlpha(230),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              margin: widget.isNested
                  ? const EdgeInsets.only(left: 0)
                  : const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _wrapChildrenWithCallback(widget.dropdownWidgets),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> _wrapChildrenWithCallback(List<Widget> children) => children.map((child) {
    if (child is DropdownMenuButton) {
      return DropdownMenuButton(
        key: child.key,
        label: child.label,
        dropdownWidgets: child.dropdownWidgets,
        isNested: true,
        icon: child.icon,
        onChildDropdownChanged: widget.onChildDropdownChanged,
        onDropdownStateChanged: _onChildDropdownStateChanged,
      );
    }
    return child;
  }).toList();

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
    link: _layerLink,
    child: MouseRegion(
      onEnter: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isHovered = true;
            });
            _updateOverlay();
            widget.onChildDropdownChanged?.call();
          }
        });
      },
      onExit: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isHovered = false;
            });
            Future.delayed(const Duration(milliseconds: 15), () {
              if (mounted) {
                _updateOverlay();
                widget.onChildDropdownChanged?.call();
              }
            });
          }
        });
      },
      child: widget.isNested
          ? _buildNestedMenuItem()
          : _buildMainMenuItem(),
    ),
  );
  
  

  Widget _buildMainMenuItem() => MenuBarButton(
    onPressed: () {
      setState(() {
        _isHovered = !_isHovered;
      });
      _updateOverlay();
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        widget.label,
        style: const TextStyle(color: Colors.white70),
      ),
    ),
  );

  Widget _buildNestedMenuItem() => InkWell(
    onTap: () {
      setState(() {
        _isHovered = !_isHovered;
      });
      _updateOverlay();
    },
    child: Container(
      color: _isHovered || _isDropdownHovered || _hasActiveChild
          ? Colors.white12
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18, color: Colors.white70),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              widget.label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_right,
            size: 18,
            color: Colors.white54,
          ),
        ],
      ),
    ),
  );
}