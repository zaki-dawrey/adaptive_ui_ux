import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'adaptive_widget.dart';
import 'layout_store.dart';
import 'models/layout_config.dart';
import 'rule_engine.dart';
import 'tracker.dart';

/// A layout widget that arranges adaptive widgets based on usage patterns
class AdaptiveLayout extends StatefulWidget {
  /// List of adaptive widgets to arrange
  final List<AdaptiveWidget> children;

  /// Layout orientation (vertical or horizontal)
  final Axis direction;

  /// Whether to enable automatic layout adjustments
  final bool enableAutoAdjustments;

  /// Interval for automatic layout adjustments
  final Duration autoAdjustInterval;

  /// Minimum number of interactions before applying layout adjustments
  final int minInteractionsBeforeAdjust;

  /// Rules for layout adjustment
  final List<LayoutRule>? rules;

  /// Layout store for persisting configurations
  final LayoutStore? layoutStore;

  /// Interaction tracker for tracking widget usage
  final InteractionTracker? tracker;

  /// ID of the layout configuration to use
  final String? layoutId;

  /// Callback when the layout changes
  final Function(LayoutConfig)? onLayoutChanged;

  /// Padding around the layout
  final EdgeInsetsGeometry? padding;

  /// Constructor
  const AdaptiveLayout({
    super.key,
    required this.children,
    this.direction = Axis.vertical,
    this.enableAutoAdjustments = true,
    this.autoAdjustInterval = const Duration(seconds: 30),
    this.minInteractionsBeforeAdjust = 5,
    this.rules,
    this.layoutStore,
    this.tracker,
    this.layoutId,
    this.onLayoutChanged,
    this.padding,
  });

  @override
  State<AdaptiveLayout> createState() => _AdaptiveLayoutState();
}

class _AdaptiveLayoutState extends State<AdaptiveLayout> {
  late LayoutStore _layoutStore;
  late InteractionTracker _tracker;
  late RuleEngine _ruleEngine;
  LayoutConfig? _currentLayout;
  String? _layoutId;
  StreamSubscription? _layoutChangeSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize dependencies
    _layoutStore = widget.layoutStore ?? LayoutStore.instance;
    _tracker = widget.tracker ?? InteractionTracker.instance;

    _layoutId = widget.layoutId;

    // Set up rule engine
    _ruleEngine = RuleEngine(
      tracker: _tracker,
      layoutStore: _layoutStore,
      rules: widget.rules,
      minInteractions: widget.minInteractionsBeforeAdjust,
    );

    // Listen for layout changes
    _layoutChangeSubscription =
        _layoutStore.onLayoutChange.listen(_handleLayoutChange);

    // Initialize layout configuration
    _initializeLayout();

    // Start auto-adjustments if enabled
    if (widget.enableAutoAdjustments) {
      _ruleEngine.startAutoAdjustments(
        interval: widget.autoAdjustInterval,
      );
    }
  }

  Future<void> _initializeLayout() async {
    // Try to load the specified layout
    if (_layoutId != null) {
      _currentLayout = await _layoutStore.getLayout(_layoutId!);
    }

    // If no layout is found, create a new one
    if (_currentLayout == null) {
      // Create positions for all children
      final positions = widget.children.asMap().entries.map((entry) {
        return WidgetPosition(
          widgetId: entry.value.id,
          order: entry.key,
        );
      }).toList();

      // Create a new layout
      _currentLayout = await _layoutStore.createLayout(
        name: 'Layout ${const Uuid().v4().substring(0, 8)}',
        initialPositions: positions,
      );

      _layoutId = _currentLayout!.id;
      await _layoutStore.setCurrentLayout(_layoutId!);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _handleLayoutChange(LayoutConfig layout) {
    setState(() {
      _currentLayout = layout;
    });

    if (widget.onLayoutChanged != null) {
      widget.onLayoutChanged!(layout);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLayout == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Sort children based on layout positions
    final sortedChildren = _sortChildrenByLayout(widget.children);

    // Build the layout
    Widget result = widget.direction == Axis.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: sortedChildren,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: sortedChildren,
          );

    // Apply padding if specified
    if (widget.padding != null) {
      result = Padding(
        padding: widget.padding!,
        child: result,
      );
    }

    return result;
  }

  List<Widget> _sortChildrenByLayout(List<AdaptiveWidget> children) {
    if (_currentLayout == null) return children;

    // Create a map of widget ID to widget
    final widgetMap = {for (var child in children) child.id: child};

    // Get positions
    final positions = _currentLayout!.positions;

    // Sort children based on positions
    final sortedChildren = <Widget>[];

    // First add widgets with positions
    for (final position in positions) {
      final widget = widgetMap[position.widgetId];
      if (widget != null && position.visible) {
        final child = position.constraints != null
            ? ConstrainedBox(
                constraints: position.constraints!,
                child: widget,
              )
            : widget;

        sortedChildren.add(child);

        // Remove from map so we don't add it twice
        widgetMap.remove(position.widgetId);
      }
    }

    // Add remaining widgets that don't have positions
    sortedChildren.addAll(widgetMap.values);

    return sortedChildren;
  }

  @override
  void dispose() {
    // Stop auto-adjustments
    if (widget.enableAutoAdjustments) {
      _ruleEngine.stopAutoAdjustments();
    }

    // Cancel layout change subscription
    _layoutChangeSubscription?.cancel();

    super.dispose();
  }
}
