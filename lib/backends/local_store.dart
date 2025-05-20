import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/layout_config.dart';
import '../models/interaction_event.dart';

/// Interface for all storage backends
abstract class StorageBackend {
  /// Save a layout configuration
  Future<bool> saveLayoutConfig(LayoutConfig config);

  /// Get a layout configuration by ID
  Future<LayoutConfig?> getLayoutConfig(String id);

  /// Get all layout configurations
  Future<List<LayoutConfig>> getAllLayoutConfigs();

  /// Delete a layout configuration
  Future<bool> deleteLayoutConfig(String id);

  /// Log an interaction event
  Future<bool> logInteractionEvent(InteractionEvent event);

  /// Get all interaction events for a widget
  Future<List<InteractionEvent>> getInteractionEvents(String widgetId);

  /// Get all interaction events
  Future<List<InteractionEvent>> getAllInteractionEvents();

  /// Clear all interaction events
  Future<bool> clearInteractionEvents();
}

/// Local storage implementation using SharedPreferences
class LocalStorageBackend implements StorageBackend {
  static const String _layoutConfigPrefix = 'layout_config_';
  static const String _interactionEventPrefix = 'interaction_event_';
  static const String _allConfigIdsKey = 'all_layout_config_ids';

  /// SharedPreferences instance
  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Initialize the local storage
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  @override
  Future<bool> saveLayoutConfig(LayoutConfig config) async {
    await _ensureInitialized();

    // Update the config's last modified timestamp
    config = LayoutConfig(
      id: config.id,
      name: config.name,
      positions: config.positions,
      lastModified: DateTime.now(),
    );

    // Save the config
    final jsonString = jsonEncode(config.toJson());
    final result =
        await _prefs.setString('$_layoutConfigPrefix${config.id}', jsonString);

    // Update the list of all config IDs
    Set<String> allIds = Set.from(_prefs.getStringList(_allConfigIdsKey) ?? []);
    allIds.add(config.id);
    await _prefs.setStringList(_allConfigIdsKey, allIds.toList());

    return result;
  }

  @override
  Future<LayoutConfig?> getLayoutConfig(String id) async {
    await _ensureInitialized();

    final jsonString = _prefs.getString('$_layoutConfigPrefix$id');
    if (jsonString == null) return null;

    return LayoutConfig.fromJson(jsonDecode(jsonString));
  }

  @override
  Future<List<LayoutConfig>> getAllLayoutConfigs() async {
    await _ensureInitialized();

    final ids = _prefs.getStringList(_allConfigIdsKey) ?? [];
    List<LayoutConfig> configs = [];

    for (final id in ids) {
      final config = await getLayoutConfig(id);
      if (config != null) {
        configs.add(config);
      }
    }

    return configs;
  }

  @override
  Future<bool> deleteLayoutConfig(String id) async {
    await _ensureInitialized();

    // Remove the config
    final result = await _prefs.remove('$_layoutConfigPrefix$id');

    // Update the list of all config IDs
    Set<String> allIds = Set.from(_prefs.getStringList(_allConfigIdsKey) ?? []);
    allIds.remove(id);
    await _prefs.setStringList(_allConfigIdsKey, allIds.toList());

    return result;
  }

  @override
  Future<bool> logInteractionEvent(InteractionEvent event) async {
    await _ensureInitialized();

    // Get existing events for this widget
    List<InteractionEvent> events = await getInteractionEvents(event.widgetId);

    // Add the new event
    events.add(event);

    // Save the updated list
    final jsonStrings = events.map((e) => jsonEncode(e.toJson())).toList();
    final result = await _prefs.setStringList(
      '$_interactionEventPrefix${event.widgetId}',
      jsonStrings,
    );

    // Update the list of all widget IDs with events
    Set<String> allWidgetIds = Set.from(
        _prefs.getStringList('${_interactionEventPrefix}all_widget_ids') ?? []);
    allWidgetIds.add(event.widgetId);
    await _prefs.setStringList(
      '${_interactionEventPrefix}all_widget_ids',
      allWidgetIds.toList(),
    );

    return result;
  }

  @override
  Future<List<InteractionEvent>> getInteractionEvents(String widgetId) async {
    await _ensureInitialized();

    final jsonStrings =
        _prefs.getStringList('$_interactionEventPrefix$widgetId') ?? [];
    return jsonStrings
        .map((jsonString) => InteractionEvent.fromJson(jsonDecode(jsonString)))
        .toList();
  }

  @override
  Future<List<InteractionEvent>> getAllInteractionEvents() async {
    await _ensureInitialized();

    final widgetIds =
        _prefs.getStringList('${_interactionEventPrefix}all_widget_ids') ?? [];
    List<InteractionEvent> allEvents = [];

    for (final widgetId in widgetIds) {
      final events = await getInteractionEvents(widgetId);
      allEvents.addAll(events);
    }

    // Sort by timestamp
    allEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return allEvents;
  }

  @override
  Future<bool> clearInteractionEvents() async {
    await _ensureInitialized();

    final widgetIds =
        _prefs.getStringList('${_interactionEventPrefix}all_widget_ids') ?? [];

    // Remove all event lists
    for (final widgetId in widgetIds) {
      await _prefs.remove('$_interactionEventPrefix$widgetId');
    }

    // Clear the widget IDs list
    return await _prefs.remove('${_interactionEventPrefix}all_widget_ids');
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}
