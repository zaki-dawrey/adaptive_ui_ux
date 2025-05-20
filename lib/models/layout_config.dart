import 'package:flutter/material.dart';

/// Stores position and configuration of a widget in an adaptive layout
class WidgetPosition {
  /// Unique identifier for the widget
  final String widgetId;

  /// Position order in the layout (lower numbers come first)
  int order;

  /// Optional constraints for the widget
  BoxConstraints? constraints;

  /// Optional visibility flag
  bool visible;

  /// Constructor for creating a new widget position
  WidgetPosition({
    required this.widgetId,
    required this.order,
    this.constraints,
    this.visible = true,
  });

  /// Convert the widget position to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'widgetId': widgetId,
      'order': order,
      'constraints': constraints != null
          ? {
              'minWidth': constraints!.minWidth,
              'maxWidth': constraints!.maxWidth,
              'minHeight': constraints!.minHeight,
              'maxHeight': constraints!.maxHeight,
            }
          : null,
      'visible': visible,
    };
  }

  /// Create a widget position from a JSON map
  factory WidgetPosition.fromJson(Map<String, dynamic> json) {
    return WidgetPosition(
      widgetId: json['widgetId'],
      order: json['order'],
      constraints: json['constraints'] != null
          ? BoxConstraints(
              minWidth: json['constraints']['minWidth'],
              maxWidth: json['constraints']['maxWidth'],
              minHeight: json['constraints']['minHeight'],
              maxHeight: json['constraints']['maxHeight'],
            )
          : null,
      visible: json['visible'] ?? true,
    );
  }
}

/// Configuration for an adaptive layout
class LayoutConfig {
  /// Unique identifier for the layout
  final String id;

  /// Name of the layout
  final String name;

  /// Layout positions for all widgets
  final List<WidgetPosition> positions;

  /// Last time the layout was modified
  DateTime lastModified;

  /// Constructor for creating a new layout configuration
  LayoutConfig({
    required this.id,
    required this.name,
    required this.positions,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  /// Convert the layout config to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'positions': positions.map((position) => position.toJson()).toList(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  /// Create a layout config from a JSON map
  factory LayoutConfig.fromJson(Map<String, dynamic> json) {
    return LayoutConfig(
      id: json['id'],
      name: json['name'],
      positions: (json['positions'] as List)
          .map((position) => WidgetPosition.fromJson(position))
          .toList(),
      lastModified: DateTime.parse(json['lastModified']),
    );
  }
}
