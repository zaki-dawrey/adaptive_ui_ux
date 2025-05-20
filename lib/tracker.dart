import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models/interaction_event.dart';
import 'backends/local_store.dart';

/// Callback function for when interactions occur
typedef InteractionCallback = void Function(InteractionEvent event);

/// Tracks and logs user interactions with adaptive widgets
class InteractionTracker {
  /// Storage backend for interaction events
  final StorageBackend _storage;

  /// Callbacks to be called when interactions occur
  final List<InteractionCallback> _callbacks = [];

  /// Stream controller for interaction events
  final StreamController<InteractionEvent> _streamController =
      StreamController<InteractionEvent>.broadcast();

  /// Singleton instance of the interaction tracker
  static InteractionTracker? _instance;

  /// Get the singleton instance of the interaction tracker
  static InteractionTracker get instance =>
      _instance ??
      (_instance = InteractionTracker._internal(LocalStorageBackend()));

  /// Private constructor
  InteractionTracker._internal(this._storage) {
    _init();
  }

  /// Factory constructor that accepts a custom storage backend
  factory InteractionTracker({StorageBackend? storage}) {
    if (_instance != null) {
      if (storage != null && _instance!._storage != storage) {
        // If a different storage is provided, create a new instance
        return InteractionTracker._internal(storage);
      }
      return _instance!;
    }
    return _instance =
        InteractionTracker._internal(storage ?? LocalStorageBackend());
  }

  /// Stream of interaction events
  Stream<InteractionEvent> get onInteraction => _streamController.stream;

  /// Initialize the tracker
  Future<void> _init() async {
    if (_storage is LocalStorageBackend) {
      await (_storage as LocalStorageBackend).initialize();
    }
  }

  /// Track a user interaction
  Future<void> trackInteraction(
    String widgetId,
    InteractionType type, {
    dynamic value,
  }) async {
    final event = InteractionEvent(
      widgetId: widgetId,
      type: type,
      value: value,
    );

    // Log to storage
    try {
      await _storage.logInteractionEvent(event);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log interaction: $e');
      }
    }

    // Notify listeners
    _notifyListeners(event);
  }

  /// Add a callback to be called when interactions occur
  void addListener(InteractionCallback callback) {
    _callbacks.add(callback);
  }

  /// Remove a previously added callback
  void removeListener(InteractionCallback callback) {
    _callbacks.remove(callback);
  }

  /// Get all interaction events for a widget
  Future<List<InteractionEvent>> getEventsForWidget(String widgetId) {
    return _storage.getInteractionEvents(widgetId);
  }

  /// Get all interaction events
  Future<List<InteractionEvent>> getAllEvents() {
    return _storage.getAllInteractionEvents();
  }

  /// Clear all interaction events
  Future<void> clearAllEvents() async {
    await _storage.clearInteractionEvents();
  }

  /// Set the storage backend
  void setStorageBackend(StorageBackend storage) {
    _instance = InteractionTracker._internal(storage);
  }

  void _notifyListeners(InteractionEvent event) {
    // Notify callbacks
    for (final callback in _callbacks) {
      try {
        callback(event);
      } catch (e) {
        if (kDebugMode) {
          print('Error in interaction callback: $e');
        }
      }
    }

    // Notify stream listeners
    _streamController.add(event);
  }

  /// Dispose the tracker
  void dispose() {
    _streamController.close();
  }
}
