# Adaptive UI UX

A Flutter package for creating adaptive UIs that automatically adjust based on user interaction patterns. This package helps build interfaces that evolve to better serve your users by tracking widget usage and reorganizing layouts to prioritize frequently used elements.

## Features

-   **AdaptiveWidget**: Wrap any Flutter widget to track user interactions (taps, long presses, hover, etc.)
-   **AdaptiveLayout**: Container that intelligently rearranges child widgets based on real usage patterns
-   **Interaction Tracking**: Built-in system for monitoring how users interact with your interface
-   **Layout Storage**: Automatically persists optimized layouts using SharedPreferences
-   **Rule Engine**: Configurable system with multiple optimization strategies
-   **Zero User Configuration**: Works automatically in the background with sensible defaults

## Getting Started

### Installation

Add this package to your pubspec.yaml file:

```yaml
dependencies:
    adaptive_ui_ux: ^0.0.1
```

Run the following command to install:

```bash
flutter pub get
```

### Initialization

Initialize the package in your `main.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:adaptive_ui_ux/adaptive_ui_ux.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AdaptiveUIUX
  await AdaptiveUIUX.init(
    customConfig: AdaptiveConfig(
      threshold: 10, // How many interactions before layout changes
      layoutMode: LayoutMode.stacked, // Use stacked layout
      enableAutoAdjust: true, // Auto-adjust layouts
      enableDebugLogging: true, // Log events for debugging
    ),
  );

  runApp(MyApp());
}
```

## Basic Usage

### Example App

Here's a simple example showing how to use the core features:

```dart
import 'package:flutter/material.dart';
import 'package:adaptive_ui_ux/adaptive_ui_ux.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Adaptive UI UX Demo')),
      body: AdaptiveLayout(
        // Automatically adjust layout after 10 interactions
        enableAutoAdjustments: true,
        minInteractionsBeforeAdjust: 10,
        children: [
          // Create adaptive widgets
          AdaptiveWidget(
            id: 'button1',
            child: ElevatedButton(
              onPressed: () {},
              child: Text('Buy Now'),
            ),
          ),
          AdaptiveWidget(
            id: 'button2',
            child: ElevatedButton(
              onPressed: () {},
              child: Text('Button 2'),
            ),
          ),
          AdaptiveWidget(
            id: 'button3',
            child: ElevatedButton(
              onPressed: () {},
              child: Text('Button 3'),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Advanced Usage

#### Custom Layout Store

```dart
// Initialize a custom layout store
final layoutStore = LayoutStore();

// Use it with your AdaptiveLayout
AdaptiveLayout(
  layoutStore: layoutStore,
  // ...
)
```

#### Custom Rules

```dart
// Create a rule engine with custom rules
final ruleEngine = RuleEngine(
  rules: [
    MostUsedFirstRule(),
    HighlightOutliersRule(threshold: 1.5),
  ],
);

// Or set rules later
ruleEngine.setRules([
  MostUsedFirstRule(),
  PreserveOrderRule(['important_widget_id']),
]);
```

#### Configuration Options

```dart
// Initialize with custom configuration
await AdaptiveUIUX.init(
  customConfig: AdaptiveConfig(
    threshold: 15,              // Change layout after 15 interactions
    layoutMode: LayoutMode.grid, // Use grid layout instead of stacked
    enableAutoAdjust: true,     // Enable automatic layout adjustments
    enableDebugLogging: true,   // Log interactions and layout changes
  ),
);

// Reset adaptive UI data and settings
await AdaptiveUIUX.reset();
```

## Component Documentation

### AdaptiveWidget

The `AdaptiveWidget` is the core building block that wraps your existing Flutter widgets to make them trackable and adaptable.

#### Properties

| Property         | Type           | Default  | Description                              |
| ---------------- | -------------- | -------- | ---------------------------------------- |
| `id`             | String         | Required | Unique identifier for the widget         |
| `child`          | Widget         | Required | The widget to wrap and track             |
| `trackTaps`      | bool           | true     | Whether to track tap interactions        |
| `trackLongPress` | bool           | true     | Whether to track long press interactions |
| `trackHover`     | bool           | false    | Whether to track hover interactions      |
| `trackFocus`     | bool           | false    | Whether to track focus interactions      |
| `onInteraction`  | Function       | null     | Callback when interaction occurs         |
| `constraints`    | BoxConstraints | null     | Optional sizing constraints              |

#### Example

```dart
AdaptiveWidget(
  id: 'unique_widget_id',
  trackTaps: true,       // Track tap events
  trackLongPress: true,  // Track long press events
  trackHover: false,     // Track hover events
  trackFocus: false,     // Track focus events
  onInteraction: (event) {
    print('Interaction: ${event.type} on ${event.widgetId}');
  },
  constraints: BoxConstraints(maxWidth: 200),
  child: ElevatedButton(
    onPressed: () {},
    child: Text('Click Me'),
  ),
)
```

#### Auto ID Generation

You can also let the system generate a unique ID for you:

```dart
AdaptiveWidget.auto(
  child: ElevatedButton(
    onPressed: () {},
    child: Text('Auto ID Button'),
  ),
)
```

### AdaptiveLayout

The `AdaptiveLayout` container arranges and manages `AdaptiveWidget` children, automatically reordering them based on usage patterns.

#### Properties

| Property                      | Type                 | Default       | Description                           |
| ----------------------------- | -------------------- | ------------- | ------------------------------------- |
| `children`                    | List<AdaptiveWidget> | Required      | Widgets to arrange adaptively         |
| `direction`                   | Axis                 | Axis.vertical | Layout orientation                    |
| `enableAutoAdjustments`       | bool                 | true          | Whether to auto-adapt layout          |
| `autoAdjustInterval`          | Duration             | 30 seconds    | Time between layout evaluations       |
| `minInteractionsBeforeAdjust` | int                  | 10            | Interactions needed before adaptation |
| `rules`                       | List<LayoutRule>     | null          | Custom layout rules                   |
| `layoutStore`                 | LayoutStore          | null          | Custom layout storage                 |
| `tracker`                     | InteractionTracker   | null          | Custom interaction tracker            |
| `padding`                     | EdgeInsetsGeometry   | null          | Padding around the layout             |

#### Example

```dart
AdaptiveLayout(
  direction: Axis.vertical,
  enableAutoAdjustments: true,
  autoAdjustInterval: Duration(seconds: 30),
  minInteractionsBeforeAdjust: 10,
  padding: EdgeInsets.all(16),
  onLayoutChanged: (layout) {
    print('Layout changed: ${layout.id}');
  },
  children: [
    // Your AdaptiveWidgets here
  ],
)
```

### Rule Engine

The `RuleEngine` is the brain that analyzes interaction data and applies rules to optimize layout. You generally don't need to interact with it directly, as `AdaptiveLayout` manages it for you.

#### Built-in Rules

| Rule                    | Description                                                                |
| ----------------------- | -------------------------------------------------------------------------- |
| `MostUsedFirstRule`     | Prioritizes widgets with the most interactions                             |
| `LeastUsedFirstRule`    | Prioritizes widgets with the fewest interactions                           |
| `HighlightOutliersRule` | Identifies widgets with usage patterns significantly different from others |

#### Custom Rules

You can create custom rules by implementing the `LayoutRule` interface:

```dart
class MyCustomRule implements LayoutRule {
  @override
  List<String> apply(Map<String, int> interactionCounts) {
    // Your custom logic here
    // Return a list of widget IDs in your preferred order
    return [...];
  }
}
```

#### Manual Control

If you need direct control over the rule engine:

```dart
// Create a rule engine
final ruleEngine = RuleEngine(
  tracker: InteractionTracker.instance,
  layoutStore: LayoutStore.instance,
  rules: [MostUsedFirstRule()],
  minInteractions: 5,
);

// Start automatic adjustments
ruleEngine.startAutoAdjustments(interval: Duration(seconds: 30));

// Manually evaluate rules
await ruleEngine.evaluateAndApplyRules();
```

## Advanced Usage Examples

### E-commerce Product Page

```dart
AdaptiveLayout(
  minInteractionsBeforeAdjust: 5,
  children: [
    AdaptiveWidget(id: 'buy_now', child: BuyNowButton()),
    AdaptiveWidget(id: 'add_to_cart', child: AddToCartButton()),
    AdaptiveWidget(id: 'add_to_wishlist', child: WishlistButton()),
    AdaptiveWidget(id: 'share_product', child: ShareButton()),
    AdaptiveWidget(id: 'reviews', child: ReviewsSection()),
  ],
)
```

### Settings Screen

```dart
AdaptiveLayout(
  direction: Axis.vertical,
  padding: EdgeInsets.all(16.0),
  children: [
    AdaptiveWidget(id: 'account_settings', child: AccountSettingsCard()),
    AdaptiveWidget(id: 'notification_settings', child: NotificationSettingsCard()),
    AdaptiveWidget(id: 'privacy_settings', child: PrivacySettingsCard()),
    AdaptiveWidget(id: 'appearance_settings', child: AppearanceSettingsCard()),
    AdaptiveWidget(id: 'about', child: AboutCard()),
  ],
)
```

## Example App

Check the `/example` folder for a complete example app demonstrating:

-   AdaptiveWidgets with tap tracking
-   AdaptiveLayout with auto-adjustments
-   Layout adaptations based on usage
-   Manual layout reset

## Requirements

-   Flutter 2.0.0 or higher
-   Dart 2.17.0 or higher
-   Android, iOS, Web, macOS, Windows, or Linux

## License

This project is licensed under the MIT License - see the LICENSE file for details.
