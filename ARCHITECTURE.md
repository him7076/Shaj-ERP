# Sahaj ERP — Architecture Reference

## 1. Project Overview

Sahaj ERP is a professional, offline-first Clean Architecture ERP application designed for business management. It supports multi-firm setups and operates robustly offline by defaulting to local storage, while synchronizing with the cloud securely in the background.

## 2. Technology Stack

*   **Framework**: Flutter / Dart
*   **State Management**: Riverpod (`flutter_riverpod`)
*   **Routing**: GoRouter (`go_router`)
*   **Local Database**: Isar (`isar`, `isar_flutter_libs`)
*   **Cloud / Sync Services**: Firebase (Core, Auth, Firestore, Storage)
*   **Model Generation**: Freezed (`freezed_annotation`), Json Serializable (`json_annotation`), Isar Generator
*   **UI/Utility Packages**: `pdf`, `printing`, `fl_chart`, `excel`, `app_links`

## 3. Project Structure

The project follows a clean architectural organization inside the `lib/` directory:

*   **`core/`**: Houses global services, constants, shared utility functions, the primary theme configuration, error handlers, and universally shared UI widgets.
*   **`data/`**: Manages the local collections (schemas) and potentially other data layer implementations.
*   **`domain/`**: Contains core business rules and abstract definitions.
*   **`features/`**: The main bulk of the application organized by business modules (e.g., `sales`, `purchases`, `items`, `sync`). Inside each feature, code is further split into layers (e.g., `presentation/screens`).
*   **`main.dart`**: The application entry point.
*   **`router.dart`**: Centralized route configurations for `go_router`.

## 4. Application Entry & Initialization

*   **Entry Point**: `lib/main.dart` starts the application within a `runZonedGuarded` block for global error catching.
*   **Initialization Sequence**:
    1. Flutter widget binding is ensured.
    2. Global `ErrorWidget.builder` is overridden for friendly error UIs.
    3. `SharedPreferences` is loaded.
    4. Firebase is initialized asynchronously (non-blocking).
    5. `DatabaseService` (Isar) is initialized.
    6. Background tasks (like `FirebaseMigrationService`) are triggered.
*   **Riverpod Initialization**: The `MyApp` widget is wrapped in a `ProviderScope`, passing initial overrides (like shared preferences and database service instances).
*   **Web Fallback Initialization**: If running on Web, `WebMockIsar` is initialized instead of the native Isar implementation, along with demo data seeding if required.

## 5. Navigation & Routing

*   **Solution**: `go_router`.
*   **Routing File**: Centralized in `lib/router.dart`.
*   **Layout Pattern**: Uses a `ShellRoute` pattern wrapped by a `MainLayout` widget, allowing a persistent navigation drawer/bottom-bar to remain on screen while the inner content routes change.
*   **Platform Behavior**: The routing structure remains the same across mobile and web, but the surrounding layout adapts visually (e.g., Side Drawer vs. Bottom Navigation Bar) based on viewport width.

## 6. UI Architecture

*   **Shared Widgets**: Found in `lib/core/widgets/`. Commonly used are `NeuCard`, `ModernTextField`, `CustomDrawer`, and `MainLayout`.
*   **Form Components**: Major data entry screens are built as large monolithic `StatefulWidget` classes incorporating dense UI structures.
*   **Dropdown Components**: Standardized dropdowns exist for entities, including `SearchableItemDropdown` and `SearchablePartyDropdown`.
*   **UI Conventions**: Focuses on high information density, utilizing modals/bottom-sheets for sub-selections (like `FullScreenItemEntry` for cart management).

## 7. Responsive Architecture

The existing application is fully responsive out of the box using built-in mechanisms.

*   **`ResponsiveFormRow`**: A critical utility widget used to place form elements side-by-side on wide screens (`Row`) and stack them vertically on narrow mobile screens (`Column`).
*   **Breakpoint/Layout Behavior**: Relies heavily on `LayoutBuilder` and `MediaQuery` to adjust margins, typography sizes, and layouts dynamically.
*   **Mobile Behavior**: Stacks elements, relies on `SafeArea` for notches, uses Bottom Navigation/Bottom Sheets, and constrains wide dialogs.
*   **Web/Tablet Behavior**: Expands to fill available space using horizontal rows, wider cards, and a permanent Side Drawer.

## 8. State & Business Logic

*   **Riverpod Architecture**: Extensively relies on `flutter_riverpod` for state exposure, dependency injection, and reactivity.
*   **Notifiers / Providers**: Modules define `StateNotifier` or `Notifier` classes to maintain current operational state (like carts, selected dates, or filter states).
*   **Services**: Reusable business logic resides in `lib/core/services/` (e.g., `profit_service.dart`, `pdf_service.dart`).
*   **Communication**: UI layers (presentation) rarely process raw data. They invoke methods on Riverpod providers or direct Service singletons, which then read/write to the database and update state.

## 9. Local Data / Isar

*   **Database Service**: Managed centrally via `lib/core/services/database_service.dart`.
*   **Initialization**: Handles active firm detection, opens collections, and contains critical try-catch blocks to safely recover from broken database files by deleting them.
*   **Important Collections**: `Item`, `Party`, `Invoice`, `Purchase`, `Order`, `Transaction`, `Settings`, `User`, `Machinery`, `SyncQueue`.
*   **Multi-firm Behavior**: Supports switching databases by opening an Isar instance named after the `active_firm_id`.
*   **Web Database Fallback**: Since Isar does not fully support Flutter Web, a massive custom class `WebMockIsar` intercepts and mocks Isar behavior purely in memory/localStorage for the web build.
*   **Cascading Updates**: Complex operations (like renaming an Item or Party) execute programmatic cascaded updates across historical transactions locally.

## 10. Firebase & Sync

*   **Firebase Services**: Core, Auth, Firestore, and Storage.
*   **Access Point**: Centralized via `firebase_service.dart` and `sync_service.dart`. The UI does not query Firebase directly for transactional data.
*   **SyncQueue**: The core pattern for offline-first resilience. Writes to the local Isar database create a pending record in `SyncQueueSchema`.
*   **Sync Flow**: 
    1. Local Isar database changes.
    2. Change is appended to local `SyncQueue`.
    3. Background `SyncManager` processes the queue.
    4. Successful push to Firestore removes the queue entry.
*   **Backup**: Snapshot backups are supported locally via file generation (`.sahaj` extension).

## 11. Major Business Modules

*   **Sales**: Invoicing, Point of Sale, Analytics.
*   **Purchases**: Supplier invoices and tracking.
*   **Orders**: Estimates, Quotes, WhatsApp order integration.
*   **Transactions**: Cash, Bank, Credit Notes, Debit Notes, Party Transfers.
*   **Parties**: Customers and Suppliers directory.
*   **Items**: Inventory tracking, Categories, Brands, Units.
*   **Accounting**: Expense recording, basic ledger features.
*   **Reports**: PDF and Excel analytics generation.
*   **Tasks**: Background queuing and syncing.
*   **Machinery**: Specific asset tracking module.
*   **Settings**: Application configuration, firm management.
*   **Vault**: Secured, personal data.
*   **Backup/Sync**: Manual and automatic cloud backups.

## 12. Transaction Form Architecture

*   **Separate Forms**: Main transaction screens are wholly distinct files:
    *   `add_edit_invoice_screen.dart`
    *   `add_edit_purchase_screen.dart`
    *   `add_edit_order_screen.dart`
    *   `add_edit_credit_note_screen.dart`
    *   `add_edit_debit_note_screen.dart`
*   **Duplication Implications**: These forms share visual layouts and cart calculation logic but **do not inherit** from a unified base widget. Modifying tax logic, cart row styling, or dropdown logic requires manually applying the exact same changes across all 5 files.
*   **Shared Sub-Components**: They utilize shared core widgets for specific interactions (e.g., `full_screen_item_entry.dart` to add items to the cart, `searchable_party_dropdown.dart` for supplier/customer selection).

*Future transaction-form changes must inspect all affected forms rather than assuming modifying one form propagates globally.*

## 13. Platform Architecture

*   **Unified Codebase**: Android/Mobile and Web share the exact same UI and Business Logic layers.
*   **Platform Specifics**: The only major divergence is at the persistence layer (`Isar` for mobile vs `WebMockIsar` for web) and minor file-intent handling (`app_links`) which only applies to Android.

## 14. Important Existing Risks

*   **Duplicated Transaction Forms**: The separation of `Invoice`, `Purchase`, `Order`, `CreditNote`, and `DebitNote` screens introduces a severe risk of feature divergence and logic bugs if updates are not strictly mirrored across all files.
*   **Massive StatefulWidgets**: Core transaction screens reach several thousands of lines of code containing entangled UI, state, and complex math logic via `setState`. Extreme care is needed when modifying them to avoid accidental regressions.
*   **WebMockIsar Divergence**: The custom web persistence layer (`WebMockIsar`) poses a risk if new native Isar query logic is used but not accurately supported by the mock implementation, leading to web-only crashes or silent failures.

## 15. Existing Patterns To Reuse

*   **Shared Widgets**: Use `NeuCard`, `ModernTextField` for consistent aesthetics.
*   **Responsive Utilities**: Wrap horizontal elements in `ResponsiveFormRow` to ensure narrow screens don't overflow.
*   **State Management**: Favor Riverpod `ConsumerStatefulWidget` and Notifiers over localized `StatefulWidget` logic when state needs to persist across screens.
*   **Local Persistence**: Read/write exclusively to Isar via standard models. Let the `SyncManager` handle Firebase.
*   **Logging**: Import and utilize `logger.info()` / `logger.error()` instead of `print()` statements.

## 16. Rules For Future AI Implementation

*   Inspect existing architecture before changing it.
*   Reuse existing shared components when appropriate.
*   For changes affecting multiple transaction forms, inspect every affected form.
*   For UI changes, check mobile and web.
*   For responsive changes, use existing responsive patterns.
*   For persistence changes, preserve the existing Isar/sync architecture.
*   Do not introduce duplicate architecture without a clear reason.
*   Do not refactor unrelated code during feature work.
