import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'models/layout_config.dart';
import 'backends/local_store.dart';

/// Manages layout configurations for adaptive layouts
class LayoutStore extends ChangeNotifier {
  /// Storage backend for layout configurations
  final StorageBackend _storage;

  /// Cache of layout configurations
  final Map<String, LayoutConfig> _configCache = {};

  /// ID of the current active layout configuration
  String? _currentLayoutId;

  /// Stream controller for layout changes
  final StreamController<LayoutConfig> _layoutChangeController =
      StreamController<LayoutConfig>.broadcast();

  /// Singleton instance of the layout store
  static LayoutStore? _instance;

  /// Get the singleton instance of the layout store
  static LayoutStore get instance =>
      _instance ?? (_instance = LayoutStore._internal(LocalStorageBackend()));

  /// Private constructor
  LayoutStore._internal(this._storage) {
    _init();
  }

  /// Factory constructor that accepts a custom storage backend
  factory LayoutStore({StorageBackend? storage}) {
    if (_instance != null) {
      if (storage != null && _instance!._storage != storage) {
        // If a different storage is provided, create a new instance
        return LayoutStore._internal(storage);
      }
      return _instance!;
    }
    return _instance = LayoutStore._internal(storage ?? LocalStorageBackend());
  }

  /// Stream of layout changes
  Stream<LayoutConfig> get onLayoutChange => _layoutChangeController.stream;

  /// Current active layout configuration
  LayoutConfig? get currentLayout =>
      _currentLayoutId != null ? _configCache[_currentLayoutId] : null;

  /// Initialize the store
  Future<void> _init() async {
    if (_storage is LocalStorageBackend) {
      await (_storage as LocalStorageBackend).initialize();
    }

    await _loadConfigsFromStorage();
  }

  /// Load all configurations from storage to the cache
  Future<void> _loadConfigsFromStorage() async {
    try {
      final configs = await _storage.getAllLayoutConfigs();
      for (final config in configs) {
        _configCache[config.id] = config;
      }

      // Set the first config as current if there is no current
      if (_currentLayoutId == null && configs.isNotEmpty) {
        _currentLayoutId = configs.first.id;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load configurations: $e');
      }
    }
  }

  /// Create a new layout configuration
  Future<LayoutConfig> createLayout({
    required String name,
    List<WidgetPosition>? initialPositions,
  }) async {
    final id = const Uuid().v4();
    final config = LayoutConfig(
      id: id,
      name: name,
      positions: initialPositions ?? [],
    );

    await _saveConfig(config);
    return config;
  }

  /// Get a layout configuration by ID
  Future<LayoutConfig?> getLayout(String id) async {
    if (_configCache.containsKey(id)) {
      return _configCache[id];
    }

    final config = await _storage.getLayoutConfig(id);
    if (config != null) {
      _configCache[id] = config;
    }

    return config;
  }

  /// Get all layout configurations
  Future<List<LayoutConfig>> getAllLayouts() async {
    await _loadConfigsFromStorage();
    return _configCache.values.toList();
  }

  /// Set the current active layout
  Future<void> setCurrentLayout(String id) async {
    if (!_configCache.containsKey(id)) {
      final config = await _storage.getLayoutConfig(id);
      if (config == null) {
        throw Exception('Layout configuration not found: $id');
      }
      _configCache[id] = config;
    }

    _currentLayoutId = id;
    notifyListeners();
    _notifyLayoutChange();
  }

  /// Update a widget position in the current layout
  Future<void> updateWidgetPosition(WidgetPosition position) async {
    if (_currentLayoutId == null) {
      throw Exception('No current layout selected');
    }

    final layout = _configCache[_currentLayoutId]!;

    // Find the existing position or add a new one
    final existingIndex =
        layout.positions.indexWhere((p) => p.widgetId == position.widgetId);

    if (existingIndex >= 0) {
      layout.positions[existingIndex] = position;
    } else {
      layout.positions.add(position);
    }

    layout.lastModified = DateTime.now();

    await _saveConfig(layout);
  }

  /// Remove a widget position from the current layout
  Future<void> removeWidgetPosition(String widgetId) async {
    if (_currentLayoutId == null) {
      throw Exception('No current layout selected');
    }

    final layout = _configCache[_currentLayoutId]!;

    layout.positions.removeWhere((p) => p.widgetId == widgetId);
    layout.lastModified = DateTime.now();

    await _saveConfig(layout);
  }

  /// Reorder widget positions in the current layout
  Future<void> reorderWidgets(List<String> widgetIds) async {
    if (_currentLayoutId == null) {
      throw Exception('No current layout selected');
    }

    final layout = _configCache[_currentLayoutId]!;

    // Update order based on the new list
    for (int i = 0; i < widgetIds.length; i++) {
      final widgetId = widgetIds[i];
      final position = layout.positions.firstWhere(
        (p) => p.widgetId == widgetId,
        orElse: () => WidgetPosition(
          widgetId: widgetId,
          order: i,
        ),
      );

      position.order = i;

      // Update or add the position
      final existingIndex =
          layout.positions.indexWhere((p) => p.widgetId == widgetId);

      if (existingIndex >= 0) {
        layout.positions[existingIndex] = position;
      } else {
        layout.positions.add(position);
      }
    }

    // Sort positions by order
    layout.positions.sort((a, b) => a.order.compareTo(b.order));

    layout.lastModified = DateTime.now();

    await _saveConfig(layout);
  }

  /// Delete a layout configuration
  Future<void> deleteLayout(String id) async {
    // Remove from cache
    _configCache.remove(id);

    // Remove from storage
    await _storage.deleteLayoutConfig(id);

    // If this was the current layout, reset the current layout
    if (_currentLayoutId == id) {
      _currentLayoutId =
          _configCache.isNotEmpty ? _configCache.keys.first : null;
      notifyListeners();

      if (_currentLayoutId != null) {
        _notifyLayoutChange();
      }
    }
  }

  /// Save a layout configuration
  Future<void> _saveConfig(LayoutConfig config) async {
    // Update the cache
    _configCache[config.id] = config;

    // Save to storage
    await _storage.saveLayoutConfig(config);

    // Notify listeners
    notifyListeners();

    // Notify stream listeners
    if (config.id == _currentLayoutId) {
      _notifyLayoutChange();
    }
  }

  void _notifyLayoutChange() {
    if (_currentLayoutId != null &&
        _configCache.containsKey(_currentLayoutId!)) {
      _layoutChangeController.add(_configCache[_currentLayoutId!]!);
    }
  }

  @override
  void dispose() {
    _layoutChangeController.close();
    super.dispose();
  }
}
