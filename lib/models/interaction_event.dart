
/// Represents the type of interaction a user has with a widget
enum InteractionType {
  tap,
  longPress,
  hover,
  focus,
  scroll,
  swipe,
  custom,
}

/// Represents an interaction event with an adaptive widget
class InteractionEvent {
  /// Unique identifier for the widget that was interacted with
  final String widgetId;

  /// The type of interaction that occurred
  final InteractionType type;

  /// Optional value associated with the interaction (e.g., scroll position)
  final dynamic value;

  /// Timestamp when the interaction occurred
  final DateTime timestamp;

  /// Constructor for creating a new interaction event
  InteractionEvent({
    required this.widgetId,
    required this.type,
    this.value,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert the interaction event to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'widgetId': widgetId,
      'type': type.toString().split('.').last,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create an interaction event from a JSON map
  factory InteractionEvent.fromJson(Map<String, dynamic> json) {
    return InteractionEvent(
      widgetId: json['widgetId'],
      type: InteractionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => InteractionType.custom,
      ),
      value: json['value'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
