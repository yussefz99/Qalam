# Testing Patterns

**Analysis Date:** 2026-05-30

## Test Framework

**Runner:**
- Flutter Test (part of Flutter SDK)
- Built-in via `flutter_test` in dev dependencies (`pubspec.yaml`)
- No separate test framework dependency required
- Config: No explicit config file (uses Flutter defaults)

**Assertion Library:**
- Flutter's `expect()` function (from `flutter_test`)
- Matchers: `findsOneWidget`, `findsNothing`, `findsWidgets` for widget finding

**Run Commands:**
```bash
flutter test                          # Run all tests
flutter test --watch                  # Watch mode (re-run on changes)
flutter test test/widget_test.dart    # Run specific test file
flutter test --coverage               # Run with coverage reporting
```

**Coverage:**
- `lcov` format output to `coverage/lcov.info`
- Requires `coverage` package (optional dependency for CI)

## Test File Organization

**Location:**
- All tests in `/test` directory at project root
- Test files mirror source structure (e.g., `test/screens/home_screen_test.dart` mirrors `lib/screens/home_screen.dart`)
- Currently only `test/widget_test.dart` exists (single file pattern)

**Naming:**
- Files: `[subject]_test.dart` (e.g., `widget_test.dart`, `counter_test.dart`)
- Test functions: `testWidgets('description', (tester) { ... })`
- Test suites: `group('ComponentName', () { ... })`

**Structure:**
```
test/
├── widget_test.dart          # Basic widget tests
├── screens/
│   ├── home_screen_test.dart
│   └── lesson_screen_test.dart
├── services/
│   └── tutor_service_test.dart
├── models/
│   └── lesson_model_test.dart
└── fixtures/
    └── sample_data.dart      # Test data factories
```

## Test Structure

**Suite Organization:**
```dart
void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Arrange: Build widget
    await tester.pumpWidget(const MyApp());
    
    // Assert initial state
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    
    // Act: Perform interaction
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    
    // Assert result
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
```

**Patterns Observed:**
- **Arrange-Act-Assert (AAA):** Setup, perform action, verify result
- **WidgetTester:** Primary testing utility for widget interactions
- **Async/await:** Used throughout for async widget operations
- **Finder API:** `find.text()`, `find.byIcon()`, `find.byType()` to locate widgets

## Widget Testing

**WidgetTester Usage:**
```dart
// Build widget in test environment
await tester.pumpWidget(const MyApp());

// Find widgets
find.text('text')          // By text content
find.byIcon(Icons.add)     // By icon
find.byType(Button)        // By widget type
find.byKey(ValueKey('id')) // By key

// Interact with widgets
await tester.tap(find.byIcon(Icons.add));  // Tap button
await tester.scroll(...);                   // Scroll
await tester.drag(...);                     // Drag/swipe
await tester.enterText(...);               // Type text

// Trigger redraws
await tester.pump();            // Single frame
await tester.pumpWidget(...);   // Rebuild widget
await tester.pumpAndSettle();   // Pump until idle
```

**Key WidgetTester matchers:**
- `findsOneWidget` — expects exactly one match
- `findsNothing` — expects zero matches
- `findsWidgets` — expects one or more matches
- `findsNWidgets(n)` — expects exactly n matches

## Mocking

**Framework:** Not yet configured in project

**When Needed:**
- Mock Firebase calls (Auth, Firestore) in unit/widget tests
- Mock ML Kit Digital Ink API for handwriting tests
- Mock Cloud Functions (tutor responses)

**Recommended Approach (for future use):**
- `mockito` package for creating mock objects
- `fake_async` for testing time-dependent code
- Manual mock implementations for simple cases

**Example pattern (to adopt):**
```dart
// Using mockito (when added to pubspec.yaml)
import 'package:mockito/mockito.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  group('AuthService', () {
    late MockFirebaseAuth mockAuth;
    late AuthService authService;
    
    setUp(() {
      mockAuth = MockFirebaseAuth();
      authService = AuthService(auth: mockAuth);
    });
    
    testWidgets('logs in user', (tester) async {
      when(mockAuth.signInWithEmailAndPassword(...))
          .thenAnswer((_) async => UserCredential(...));
      
      // Test login flow
      await authService.login('test@example.com', 'password');
      
      // Verify mock was called
      verify(mockAuth.signInWithEmailAndPassword(...)).called(1);
    });
  });
}
```

## Fixtures and Test Data

**Test Data:**
- Currently defined inline within test files
- No centralized test fixtures or factories yet

**Recommended Location (for future):**
- `test/fixtures/` directory
- Create factory functions or test data builders
- Example: `test/fixtures/lesson_factory.dart`

**Pattern to adopt:**
```dart
// test/fixtures/user_factory.dart
class TestUserFactory {
  static User buildUser({
    String id = 'user-123',
    String name = 'Test Child',
    String? parentEmail,
  }) {
    return User(
      id: id,
      name: name,
      parentEmail: parentEmail ?? 'parent@example.com',
    );
  }
}

// Usage in tests
testWidgets('displays user name', (tester) async {
  final user = TestUserFactory.buildUser(name: 'Ahmed');
  // ... test logic
});
```

## Coverage

**Requirements:** Not enforced in current project

**To Enable:**
- Add `coverage` package to dev dependencies
- Run: `flutter test --coverage`
- View: `coverage/lcov.info` contains line/branch coverage data
- Generate HTML report: `genhtml coverage/lcov.info -o coverage/html`

**Target:** Set minimum coverage gate in CI (e.g., 80% for critical paths, 70% overall)

## Test Types

**Unit Tests:**
- Test individual functions, classes, business logic in isolation
- No widget rendering or Firebase calls
- Use `test()` function (not `testWidgets()`)
- Fast, deterministic, run in isolation
- Example: Testing model constructors, utility functions, data validation

**Widget Tests:**
- Test Flutter widgets and UI interactions
- Use `testWidgets()` function with `WidgetTester`
- Full widget rendering pipeline
- Can interact with UI elements (tap, scroll, text entry)
- Recommended for all UI components
- Current test file: `test/widget_test.dart`

**Integration Tests:**
- Test entire user flows across multiple screens/services
- Not yet configured in this project
- Would use `integration_test` package
- Run on emulator or real device
- Slow but most realistic testing

**E2E Tests:**
- Not currently in use
- Would test complete app scenarios end-to-end
- Same tooling as integration tests

## Common Patterns

**Async Testing:**
```dart
testWidgets('async operations complete', (tester) async {
  await tester.pumpWidget(const MyApp());
  
  // Wait for async operations to complete
  await tester.pumpAndSettle();
  
  // Verify result
  expect(find.text('Loaded'), findsOneWidget);
});
```

**Error Testing:**
```dart
testWidgets('shows error when handwriting fails', (tester) async {
  // Arrange: Mock ML Kit to return error
  mockMLKit.throwError();
  
  await tester.pumpWidget(const DrawingScreen());
  
  // Act: Attempt to draw
  await tester.tap(find.byType(DrawingCanvas));
  await tester.pumpAndSettle();
  
  // Assert: Error displayed
  expect(find.text('Could not process drawing'), findsOneWidget);
});
```

**State Changes:**
```dart
testWidgets('updates counter on button tap', (tester) async {
  await tester.pumpWidget(const MyApp());
  
  // Verify initial state
  expect(find.text('0'), findsOneWidget);
  
  // Trigger state change
  await tester.tap(find.byIcon(Icons.add));
  
  // Pump to apply state changes
  await tester.pump();
  
  // Verify updated state
  expect(find.text('1'), findsOneWidget);
  expect(find.text('0'), findsNothing);
});
```

## Test Organization for Qalam

**Current State:**
- Single test file with one smoke test
- No unit tests yet
- No integration tests
- No fixture factories

**Recommended Test Structure (to build):**
```
test/
├── unit/
│   ├── models/
│   │   └── lesson_test.dart
│   ├── services/
│   │   └── tutor_service_test.dart
│   └── utils/
│       └── validators_test.dart
├── widget/
│   ├── screens/
│   │   ├── home_screen_test.dart
│   │   └── lesson_screen_test.dart
│   ├── widgets/
│   │   └── drawing_canvas_test.dart
│   └── smoke_test.dart
├── integration/
│   └── lesson_flow_test.dart
└── fixtures/
    ├── lesson_factory.dart
    ├── user_factory.dart
    └── sample_data.dart
```

## Testing Constraints (from CLAUDE.md)

**What NOT to test:**
- ML Kit Digital Ink integration (on-device scoring, no network round-trip) — mock if needed, focus on data flow
- Firebase Cloud Functions (tutor responses) — mock function calls in tests, test prompt handling separately
- Real API calls in tests — always mock external services

**What to test heavily:**
- Handwriting analysis data processing pipeline (accepting stroke data, interpreting results)
- State management (within-session history, adaptive responses)
- Tutor feedback generation and display
- Child UX interactions and input validation
- Parent dashboard flows

---

*Testing analysis: 2026-05-30*
