# SafeHer Blueprint

## Overview

SafeHer is a personal safety application designed to provide users with a sense of security and peace of mind. The app includes features such as fall detection, emergency alerts, a menstrual cycle tracker, and location sharing. The app is built with Flutter and Firebase, and it is designed to be a reliable and user-friendly tool for personal safety.

## Visual Design Overhaul Plan

The following is a list of the changes that were made to the app's visual design:

*   **Theme:** The app now uses a modern, Material 3 theme with a custom color scheme, typography, and component styles. The theme is defined in the `lib/theme.dart` file, and it can be toggled between light and dark modes.
*   **UI Components:** All of the app's UI components have been updated to use the new theme. This includes the `AppBar`, `Card`, `ElevatedButton`, `NavigationBar`, and `TableCalendar`.
*   **Readability:** The app now uses the `google_fonts` package to add custom fonts to the app, improving readability and giving the app a more professional look.
*   **State Management:** The app now uses the `provider` package to manage the app's theme, making it easy to switch between light and dark modes.

## Current Plan

This was the plan for the visual overhaul of the application:

*   Add `google_fonts` and `provider` to `pubspec.yaml`.
*   Create `lib/theme.dart` to define the application's theme.
*   Refactor `lib/main.dart` to use the new theme and `ThemeProvider`.
*   Refactor `lib/emergency_dashboard.dart` to use the new theme and add a theme toggle.
*   Refactor `lib/menstrual_cycle_page.dart` to use the new theme.
*   Refactor `lib/analysis_page.dart` to use the new theme.
*   Refactor `lib/location_page.dart` to use the new theme.
