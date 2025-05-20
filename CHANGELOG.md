## 0.0.1 - Initial Release (May 20, 2025)

### Features

-   Core `AdaptiveWidget` for tracking user interactions with Flutter widgets
-   `AdaptiveLayout` container for automatically reorganizing widgets based on usage
-   Interaction tracking system that monitors user behavior
-   Layout storage using SharedPreferences
-   Rule engine with multiple built-in optimization strategies:
    -   MostUsedFirstRule - Prioritizes frequently used widgets
    -   LeastUsedFirstRule - Prioritizes rarely used widgets
    -   HighlightOutliersRule - Identifies widgets with unusual usage patterns
-   Simple initialization API through `AdaptiveUIUX.init()` method
-   Comprehensive configuration options

### Notes

-   This is an initial beta release
-   Local storage only (SharedPreferences)
