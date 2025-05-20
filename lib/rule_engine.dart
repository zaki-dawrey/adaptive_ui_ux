import 'dart:async';
import 'models/interaction_event.dart';
import 'tracker.dart';
import 'layout_store.dart';

/// A rule for evaluating widget usage
abstract class LayoutRule {
  /// Apply the rule to the analysis result
  /// Returns a list of widgets in their recommended order
  List<String> apply(Map<String, int> interactionCounts);
}

/// A rule that sorts widgets by interaction frequency (most used first)
class MostUsedFirstRule implements LayoutRule {
  @override
  List<String> apply(Map<String, int> interactionCounts) {
    final entries = interactionCounts.entries.toList();
    // Sort by count (descending)
    entries.sort((a, b) => b.value.compareTo(a.value));
    // Return widget IDs in order
    return entries.map((e) => e.key).toList();
  }
}

/// A rule that sorts widgets by interaction frequency (least used first)
class LeastUsedFirstRule implements LayoutRule {
  @override
  List<String> apply(Map<String, int> interactionCounts) {
    final entries = interactionCounts.entries.toList();
    // Sort by count (ascending)
    entries.sort((a, b) => a.value.compareTo(b.value));
    // Return widget IDs in order
    return entries.map((e) => e.key).toList();
  }
}

/// A rule that highlights widgets with anomalously high usage
class HighlightOutliersRule implements LayoutRule {
  final double threshold;

  HighlightOutliersRule({this.threshold = 2.0});

  @override
  List<String> apply(Map<String, int> interactionCounts) {
    if (interactionCounts.isEmpty) return [];

    // Calculate mean interaction count
    final values = interactionCounts.values.toList();
    final mean =
        values.fold<int>(0, (sum, count) => sum + count) / values.length;

    // Get widgets with counts above the threshold
    final outliers = interactionCounts.entries
        .where((entry) => entry.value > mean * threshold)
        .map((e) => e.key)
        .toList();

    // Get the rest of the widgets
    final rest = interactionCounts.entries
        .where((entry) => !outliers.contains(entry.key))
        .map((e) => e.key)
        .toList();

    // Return outliers first, then the rest
    return [...outliers, ...rest];
  }
}

/// A rule that preserves a specific order for certain widgets
class PreserveOrderRule implements LayoutRule {
  final List<String> fixedOrderWidgets;

  PreserveOrderRule(this.fixedOrderWidgets);

  @override
  List<String> apply(Map<String, int> interactionCounts) {
    // Get widgets that are in the fixed order list and in the interaction counts
    final fixedWidgets = fixedOrderWidgets
        .where((id) => interactionCounts.containsKey(id))
        .toList();

    // Get widgets that are not in the fixed order list
    final otherWidgets = interactionCounts.keys
        .where((id) => !fixedOrderWidgets.contains(id))
        .toList();

    // Sort the other widgets by count
    otherWidgets.sort((a, b) =>
        (interactionCounts[b] ?? 0).compareTo(interactionCounts[a] ?? 0));

    // Return fixed widgets first, then the rest
    return [...fixedWidgets, ...otherWidgets];
  }
}

/// Class for analyzing widget usage and suggesting layout changes
class RuleEngine {
  /// Interaction tracker instance
  final InteractionTracker _tracker;

  /// Layout store instance
  final LayoutStore _layoutStore;

  /// Rules for layout adjustment
  final List<LayoutRule> _rules;

  /// Minimum number of interactions before applying rules
  final int _minInteractions;

  /// Timer for periodic rule evaluation
  Timer? _timer;

  /// Flag to track if automatic adjustments are enabled
  bool _autoAdjustEnabled = false;

  /// Create a new rule engine
  RuleEngine({
    InteractionTracker? tracker,
    LayoutStore? layoutStore,
    List<LayoutRule>? rules,
    int minInteractions = 5,
  })  : _tracker = tracker ?? InteractionTracker.instance,
        _layoutStore = layoutStore ?? LayoutStore.instance,
        _rules = rules ?? [MostUsedFirstRule()],
        _minInteractions = minInteractions;

  /// Start automatic layout adjustments
  void startAutoAdjustments({Duration interval = const Duration(seconds: 30)}) {
    if (_autoAdjustEnabled) return;

    _autoAdjustEnabled = true;

    // Set up a timer to periodically evaluate rules
    _timer = Timer.periodic(interval, (_) async {
      await evaluateAndApplyRules();
    });

    // Listen for interactions to count for rule evaluation
    _tracker.addListener(_onInteraction);
  }

  /// Stop automatic layout adjustments
  void stopAutoAdjustments() {
    _autoAdjustEnabled = false;
    _timer?.cancel();
    _timer = null;
    _tracker.removeListener(_onInteraction);
  }

  int _interactionCount = 0;
  void _onInteraction(InteractionEvent event) {
    _interactionCount++;

    // Check if we should evaluate rules based on interaction count
    if (_autoAdjustEnabled && _interactionCount >= _minInteractions) {
      _interactionCount = 0;
      evaluateAndApplyRules();
    }
  }

  /// Evaluate rules and apply the results to the current layout
  Future<bool> evaluateAndApplyRules() async {
    if (_layoutStore.currentLayout == null) {
      return false;
    }

    // Get all interaction events
    final events = await _tracker.getAllEvents();

    // Count interactions by widget
    final counts = <String, int>{};
    for (final event in events) {
      counts[event.widgetId] = (counts[event.widgetId] ?? 0) + 1;
    }

    // Skip if we don't have enough data
    if (counts.isEmpty) {
      return false;
    }

    // Apply rules to get the recommended widget order
    List<String>? recommendedOrder;
    for (final rule in _rules) {
      if (recommendedOrder == null) {
        recommendedOrder = rule.apply(counts);
      } else {
        // Apply subsequent rules only to the result of previous rules
        final filteredCounts = <String, int>{};
        for (final id in recommendedOrder) {
          filteredCounts[id] = counts[id] ?? 0;
        }
        recommendedOrder = rule.apply(filteredCounts);
      }
    }

    if (recommendedOrder == null || recommendedOrder.isEmpty) {
      return false;
    }

    // Apply the new order to the current layout
    await _layoutStore.reorderWidgets(recommendedOrder);

    return true;
  }

  /// Add a rule to the engine
  void addRule(LayoutRule rule) {
    _rules.add(rule);
  }

  /// Remove a rule from the engine
  void removeRule(LayoutRule rule) {
    _rules.remove(rule);
  }

  /// Clear all rules
  void clearRules() {
    _rules.clear();
  }

  /// Set the rules for the engine
  void setRules(List<LayoutRule> rules) {
    _rules
      ..clear()
      ..addAll(rules);
  }
}
