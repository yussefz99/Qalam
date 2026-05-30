# Coding Conventions

**Analysis Date:** 2026-05-30

## Naming Patterns

**Files:**
- Dart files use `snake_case.dart` (e.g., `widget_test.dart`, `main.dart`)
- Flutter follows standard Dart conventions — lowercase with underscores
- Test files use `_test.dart` suffix (e.g., `widget_test.dart`)

**Functions:**
- camelCase for function names (e.g., `runApp()`, `main()`, `_incrementCounter()`)
- Private functions prefixed with underscore: `_functionName()`
- Callbacks and handlers follow the same camelCase convention

**Variables:**
- camelCase for variable names (e.g., `_counter`, `title`, `context`)
- Private fields prefixed with underscore: `_privateVariable`
- Constants use `camelCase` (not SCREAMING_SNAKE_CASE) per Dart convention
- Final keyword used for immutable values: `final String title`

**Types:**
- PascalCase for class names (e.g., `MyApp`, `MyHomePage`, `MyHomePageState`)
- State classes follow `_[WidgetName]State` pattern (e.g., `_MyHomePageState`)
- Extends and implements use PascalCase

## Code Style

**Formatting:**
- Dart formatter is the standard (built into Flutter tooling)
- Run via: `dart format lib/ test/`
- Line length: 80 characters (standard Dart convention)
- Indentation: 2 spaces (not 4)
- No trailing whitespace

**Linting:**
- Tool: `flutter_lints` v6.0.0 (included in `pubspec.yaml`)
- Config file: `analysis_options.yaml`
- Included lint set: `package:flutter_lints/flutter.yaml` (recommended Flutter lints)
- Run via: `flutter analyze`
- Active rules: Flutter's recommended rules (approximately 50+ lints)
- To suppress a lint: `// ignore: lint_name` inline or `// ignore_for_file: lint_name` at file top

**Key lint rules enforced:**
- `avoid_print`: Discourages direct print statements (use logging instead)
- `avoid_returning_null_for_future`: Futures should not return null
- `avoid_returning_null_for_void`: Void methods should not return null
- `empty_catches`: Catch blocks should not be empty
- `avoid_empty_else`: Else clauses must not be empty
- `no_adjacent_strings_in_list`: Adjacent string literals in collections
- `prefer_const_constructors`: Use const where possible
- `prefer_const_declarations`: Use const for immutable values
- `prefer_const_constructors_in_immutables`: Const constructors in immutable widgets

## Import Organization

**Order:**
1. Dart SDK imports (`dart:` prefix)
2. Package imports (`package:` prefix)
3. Relative imports (`./` or `../`)

**Examples from codebase:**
```dart
import 'dart:async';  // SDK first
import 'package:flutter/material.dart';  // Flutter package
import 'package:flutter_test/flutter_test.dart';  // Test packages
import 'package:qalam/main.dart';  // Relative project imports
```

**Path Aliases:**
- Not currently configured
- When needed: defined in `pubspec.yaml` under `dependencies` with path mappings

## Error Handling

**Patterns:**
- Use `try-catch` blocks for exception handling
- Catch specific exceptions, not generic `Exception`
- Flutter automatically handles unhandled exceptions in release builds
- For UI-blocking errors: wrap in `try-catch` and update state or show error UI
- Avoid silent failures; log or propagate errors when caught

**Return Values:**
- Return `null` only when semantically appropriate (prefer typed returns)
- Use `Future<T>` for async operations, not `Future<T?>` unless nullable
- Use `Null` return type sparingly (prefer `void` for side-effect functions)

## Logging

**Framework:** `print()` or standard Dart logging (no external logging library configured)

**Patterns:**
- Use `debugPrint()` for development-only logs (automatically stripped in release)
- `print()` logs to stdout/stderr
- For production logging: consider integrating a logging package if audit trail needed
- Format: descriptive message, include context where helpful
- Avoid logging sensitive data (child data, credentials)

## Comments

**When to Comment:**
- Explain the "why" not the "what" (code shows what)
- Document non-obvious logic or algorithmic decisions
- Explain complex state management interactions
- Use `///` for public API documentation (dartdoc)
- Use `//` for inline comments within functions

**JSDoc/TSDoc:**
- Dart uses dartdoc comments with `///`
- Format:
  ```dart
  /// Increments the counter and triggers a rebuild.
  ///
  /// This demonstrates the basic state management pattern in Flutter.
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
  ```
- All public classes, methods, and properties should have dartdoc comments

## Function Design

**Size:** 
- Keep functions focused on a single responsibility
- Aim for 20-50 lines max; extract complex logic into helper methods
- Flutter `build()` methods are acceptable exceptions (can grow larger for UI)

**Parameters:**
- Use named parameters for optional values (prevents positional confusion)
- Prefix private parameters with underscore (convention not strict)
- Use `required` keyword for mandatory named parameters

**Return Values:**
- Explicitly type all return values (no implicit `dynamic`)
- Use `Future<T>` for async operations
- Return `void` only for truly side-effect-only functions

## Module Design

**Exports:**
- Use `lib/` as the public API root
- Main entry: `lib/main.dart` (contains app root and initial widgets)
- Public exports go to `lib/` — private implementation goes to subdirectories
- Use `export` statements in barrel files to re-export commonly used types

**Barrel Files:**
- Not yet used in this project
- When introducing: create `lib/module_name.dart` that exports all public APIs from that module
- Example: `lib/screens.dart` exports all screen widgets

## Widget Construction

**StatelessWidget Pattern:**
- Use for UI that doesn't change after construction
- All final fields, immutable
- Override `build(BuildContext context)` only

**StatefulWidget Pattern:**
- Use `const` constructor when possible
- Separate mutable state into `State` subclass
- Private State class naming: `_[WidgetName]State` (e.g., `_MyHomePageState`)
- All widget fields must be `final`

**Example from codebase:**
```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});  // const constructor
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(...);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  
  final String title;  // final field
  
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;  // mutable state
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

## Const Usage

- **Use `const` liberally** for performance (enables tree-shaking and optimizations)
- All widget constructors should support `const` when fields are immutable
- Use `const` in constructor calls: `MyWidget(child: const Text('text'))`
- Dart linter enforces this via `prefer_const_constructors`

---

*Convention analysis: 2026-05-30*
