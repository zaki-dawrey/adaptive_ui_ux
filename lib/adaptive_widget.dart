import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Keeping this import as it's needed for UUID generation
import 'models/interaction_event.dart';
import 'tracker.dart';

/// A widget wrapper that tracks user interactions
class AdaptiveWidget extends StatefulWidget {
  /// Unique identifier for this widget
  final String id;

  /// The widget to wrap
  final Widget child;

  /// Whether to track tap interactions
  final bool trackTaps;

  /// Whether to track long press interactions
  final bool trackLongPress;

  /// Whether to track hover interactions
  final bool trackHover;

  /// Whether to track focus interactions
  final bool trackFocus;

  /// Callback when the widget is interacted with
  final Function(InteractionEvent)? onInteraction;

  /// Additional constraints to apply to the widget
  final BoxConstraints? constraints;

  /// Create an adaptive widget
  const AdaptiveWidget({
    super.key,
    required this.id,
    required this.child,
    this.trackTaps = true,
    this.trackLongPress = true,
    this.trackHover = false,
    this.trackFocus = false,
    this.onInteraction,
    this.constraints,
  });

  /// Create an adaptive widget with an auto-generated ID
  factory AdaptiveWidget.auto({
    Key? key,
    required Widget child,
    bool trackTaps = true,
    bool trackLongPress = true,
    bool trackHover = false,
    bool trackFocus = false,
    Function(InteractionEvent)? onInteraction,
    BoxConstraints? constraints,
  }) {
    return AdaptiveWidget(
      key: key,
      id: const Uuid().v4(),
      trackTaps: trackTaps,
      trackLongPress: trackLongPress,
      trackHover: trackHover,
      trackFocus: trackFocus,
      onInteraction: onInteraction,
      constraints: constraints,
      child: child,
    );
  }

  @override
  State<AdaptiveWidget> createState() => _AdaptiveWidgetState();
}

class _AdaptiveWidgetState extends State<AdaptiveWidget> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    Widget result = widget.child;

    // Apply constraints if provided
    if (widget.constraints != null) {
      result = ConstrainedBox(
        constraints: widget.constraints!,
        child: result,
      );
    }

    // Wrap with gesture detector for tap tracking if needed
    if (widget.trackTaps || widget.trackLongPress) {
      result = GestureDetector(
        onTap: widget.trackTaps ? _handleTap : null,
        onLongPress: widget.trackLongPress ? _handleLongPress : null,
        behavior: HitTestBehavior.translucent,
        child: result,
      );
    }

    // Wrap with mouse region for hover tracking if needed
    if (widget.trackHover) {
      result = MouseRegion(
        onEnter: (_) => _handleHover(true),
        onExit: (_) => _handleHover(false),
        child: result,
      );
    }

    // Wrap with focus for focus tracking if needed
    if (widget.trackFocus) {
      result = Focus(
        onFocusChange: _handleFocus,
        child: result,
      );
    }

    return result;
  }

  void _handleTap() {
    _trackInteraction(InteractionType.tap);
  }

  void _handleLongPress() {
    _trackInteraction(InteractionType.longPress);
  }

  void _handleHover(bool isHovered) {
    if (_isHovered != isHovered) {
      _isHovered = isHovered;
      if (isHovered) {
        _trackInteraction(InteractionType.hover, value: true);
      }
    }
  }

  void _handleFocus(bool isFocused) {
    if (_isFocused != isFocused) {
      _isFocused = isFocused;
      _trackInteraction(InteractionType.focus, value: isFocused);
    }
  }

  void _trackInteraction(InteractionType type, {dynamic value}) {
    final event = InteractionEvent(
      widgetId: widget.id,
      type: type,
      value: value,
    );

    // Log via the tracker
    InteractionTracker.instance.trackInteraction(
      widget.id,
      type,
      value: value,
    );

    // Notify the callback if provided
    if (widget.onInteraction != null) {
      widget.onInteraction!(event);
    }
  }
}
