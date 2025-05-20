import 'package:flutter/material.dart';
import 'package:adaptive_ui_ux/adaptive_ui_ux.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the adaptive UI UX package
  await AdaptiveUIUX.init(
    customConfig: AdaptiveConfig(
      threshold: 5, // Change layout after 5 interactions
      layoutMode: LayoutMode.stacked,
      enableAutoAdjust: true,
      enableDebugLogging: true,
    ),
  );

  runApp(const AdaptiveUiUxExampleApp());
}

class AdaptiveUiUxExampleApp extends StatelessWidget {
  const AdaptiveUiUxExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive UI UX Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tapCount = 0;
  final Map<String, int> _widgetTapCounts = {};
  String? _layoutStatus;

  @override
  void initState() {
    super.initState();

    // Note: No need to initialize manually as we're using AdaptiveUIUX.init() in main()
    _subscribeToEvents();
  }

  void _subscribeToEvents() {
    // Subscribe to interaction events for our UI counter
    InteractionTracker.instance.onInteraction.listen((event) {
      setState(() {
        _tapCount++;
        _widgetTapCounts[event.widgetId] =
            (_widgetTapCounts[event.widgetId] ?? 0) + 1;

        // Auto adjust layout after every 5 taps
        if (_tapCount % 5 == 0) {
          // The rule engine will handle adjustments automatically since we
          // set enableAutoAdjust to true in AdaptiveUIUX.init()
          setState(() {
            _layoutStatus = 'Layout evaluation triggered at tap $_tapCount';
          });
        }
      });
    });

    // Subscribe to layout changes for status updates
    LayoutStore.instance.onLayoutChange.listen((layout) {
      setState(() {
        _layoutStatus = 'Layout updated: ${layout.positions.length} widgets';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive UI UX Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tap the widgets below:',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                'Total Taps: $_tapCount',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (_layoutStatus != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _layoutStatus!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.blue,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AdaptiveLayout(
                  enableAutoAdjustments: true,
                  minInteractionsBeforeAdjust: 5,
                  autoAdjustInterval: const Duration(seconds: 1),
                  layoutStore: LayoutStore.instance,
                  tracker: InteractionTracker.instance,
                  padding: const EdgeInsets.all(8),
                  children: [
                    _buildAdaptiveWidget(
                      'card1',
                      Colors.red,
                      'Card 1',
                      Icons.favorite,
                    ),
                    _buildAdaptiveWidget(
                      'card2',
                      Colors.green,
                      'Card 2',
                      Icons.star,
                    ),
                    _buildAdaptiveWidget(
                      'card3',
                      Colors.blue,
                      'Card 3',
                      Icons.thumb_up,
                    ),
                    _buildAdaptiveWidget(
                      'card4',
                      Colors.orange,
                      'Card 4',
                      Icons.lightbulb,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Widgets will rearrange based on usage',
                style: TextStyle(fontSize: 14),
              ),
              const Text(
                'after every 5 taps',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetLayout,
        tooltip: 'Reset Layout',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  AdaptiveWidget _buildAdaptiveWidget(
    String id,
    Color color,
    String label,
    IconData icon,
  ) {
    return AdaptiveWidget(
      id: id,
      trackTaps: true,
      trackLongPress: true,
      onInteraction: (event) {
        if (event.type == InteractionType.tap) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label tapped!'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Tapped: ${_widgetTapCounts[id] ?? 0} times',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetLayout() async {
    // Create a new layout with default positions
    await LayoutStore.instance.createLayout(
      name: 'Reset Layout',
      initialPositions: [
        WidgetPosition(widgetId: 'card1', order: 0),
        WidgetPosition(widgetId: 'card2', order: 1),
        WidgetPosition(widgetId: 'card3', order: 2),
        WidgetPosition(widgetId: 'card4', order: 3),
      ],
    ).then((layout) {
      LayoutStore.instance.setCurrentLayout(layout.id);
    });

    // Clear interaction events
    await InteractionTracker.instance.clearAllEvents();

    setState(() {
      _tapCount = 0;
      _widgetTapCounts.clear();
      _layoutStatus = 'Layout reset';
    });
  }

  @override
  void dispose() {
    // No need to manually cleanup as we're using the singleton instances
    super.dispose();
  }
}
