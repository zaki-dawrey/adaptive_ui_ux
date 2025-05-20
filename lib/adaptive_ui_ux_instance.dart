import 'dart:async';
import 'package:flutter/foundation.dart';
import 'layout_store.dart';
import 'tracker.dart';
import 'rule_engine.dart';

/// Layout modes for the adaptive UI
enum LayoutMode {
  /// Stacked layout (vertically arranged widgets)
  stacked,

  /// Grid layout
  grid,

  /// Free-form layout
  free,
}

/// Configuration options for the adaptive UI
class AdaptiveConfig {
  /// The threshold number of interactions before adapting the layout
  final int threshold;

  /// The layout mode to use
  final LayoutMode layoutMode;

  /// Whether to enable automatic adjustments
  final bool enableAutoAdjust;

  /// Whether to log interactions to console (debug mode)
  final bool enableDebugLogging;

  /// Constructor
  const AdaptiveConfig({
    this.threshold = 10,
    this.layoutMode = LayoutMode.stacked,
    this.enableAutoAdjust = true,
    this.enableDebugLogging = false,
  });
}

/// Main entry point for the Adaptive UI UX package
class AdaptiveUIUX {
  /// The configuration for the adaptive UI
  static AdaptiveConfig config = const AdaptiveConfig();

  /// The layout store
  static late LayoutStore _layoutStore;

  /// The interaction tracker
  static late InteractionTracker _tracker;

  /// The rule engine
  static late RuleEngine _ruleEngine;

  /// Whether the adaptive UI has been initialized
  static bool _initialized = false;

  /// Initialize the adaptive UI
  ///
  /// This method should be called before using any adaptive UI components,
  /// preferably in the main() method of your app.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await AdaptiveUIUX.init();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> init({AdaptiveConfig? customConfig}) async {
    if (_initialized) {
      debugPrint('AdaptiveUIUX already initialized');
      return;
    }

    // Set configuration if provided
    if (customConfig != null) {
      config = customConfig;
    }

    // Initialize dependencies
    _layoutStore = LayoutStore();
    _tracker = InteractionTracker();
    _ruleEngine = RuleEngine(
      tracker: _tracker,
      layoutStore: _layoutStore,
      minInteractions: config.threshold,
    );

    // Start auto-adjustments if enabled
    if (config.enableAutoAdjust) {
      _ruleEngine.startAutoAdjustments();
    }

    // Enable debug logging if requested
    if (config.enableDebugLogging) {
      _enableDebugLogging();
    }

    _initialized = true;
    debugPrint('AdaptiveUIUX initialized successfully');
  }

  /// Enable debug logging for adaptive UI events
  static void _enableDebugLogging() {
    _tracker.onInteraction.listen((event) {
      debugPrint(
          'AdaptiveUIUX: Interaction - ${event.type} on ${event.widgetId}');
    });

    _layoutStore.onLayoutChange.listen((layout) {
      debugPrint('AdaptiveUIUX: Layout changed - ${layout.id}');
    });
  }

  /// Reset all adaptive UI data and configurations
  static Future<void> reset() async {
    if (!_initialized) {
      debugPrint('AdaptiveUIUX not initialized');
      return;
    }
    await _tracker.clearAllEvents();
    _ruleEngine.stopAutoAdjustments();
    _initialized = false;
    debugPrint('AdaptiveUIUX reset successfully');
  }
}
