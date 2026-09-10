# Wahni Order App

A robust, offline-first e-commerce order management Flutter application built for the Wahni IT Solutions technical assessment. The application follows Clean Architecture principles with reactive state management powered by Flutter BLoC, local persistence via Hive, safe REST API integration, and adaptive Material 3 user interfaces.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [API Integration](#api-integration)
- [Hive Persistence](#hive-persistence)
- [BLoC State Management](#bloc-state-management)
- [Quantity Input Behavior](#quantity-input-behavior)
- [Setup Instructions](#setup-instructions)
- [Testing Instructions](#testing-instructions)
- [Known Limitations](#known-limitations)

---

## Project Overview

The Wahni Order App allows users to browse an online product catalog, manage item quantities in a shopping cart, review real-time subtotals and grand totals in Indian Rupee (`₹`), and retain their cart state seamlessly across application restarts. The app ensures 100% synchronization between screens without unnecessary re-renders or state leaks.

---

## Features

* **Live Product Catalog**: Fetches real-world product data dynamically from FakeStoreAPI.
* **Offline-First Persistence**: Caches products and cart item quantities locally using Hive; app remains fully functional offline.
* **Real-Time Screen Synchronization**: Changes in the Cart Screen immediately reflect in the Product Listing and vice-versa.
* **Unique Items AppBar Badge**: Cart badge in the AppBar dynamically displays the count of **distinct unique items** (`CartBloc.uniqueItems`), NOT total quantity.
* **Inline & Dialog Quantity Controllers**: Direct numerical quantity input with strict numeric validation, cursor preservation, plus/minus incrementors, and zero/empty removal.
* **Material 3 UI**: Clean, responsive layout that adapts from 2 columns on mobile to 5 columns on desktop displays, accompanied by Material 3 bottom navigation with badges.
* **Defensive Error Handling**: Graceful fallbacks for network drops, malformed JSON, missing product images, and empty states.

---

## Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Framework** | Flutter 3.47.2 / Dart 3.13.2 |
| **Design System** | Material 3 (`useMaterial3: true`) |
| **State Management** | `flutter_bloc` (v8.1.4), `equatable` (v2.0.7) |
| **Local Persistence** | `hive` (v2.2.3), `hive_flutter` (v1.1.0) |
| **Networking** | `http` (v1.6.0) |
| **Testing** | `flutter_test` (Unit, Widget, and Integration tests) |

---

## Architecture

The project strictly follows layered **Clean Architecture**:

```
lib/
├── bloc/                         # State Management (BLoC Layer)
│   ├── cart/                     # CartBloc, CartEvent, CartState
│   └── product/                  # ProductBloc, ProductEvent, ProductState
├── core/                         # Core utilities & constants
│   └── constants/                # AppConstants (₹), ApiConstants
├── data/                         # Data Layer
│   ├── datasources/              # Remote API & Local Hive Storage
│   │   ├── local_database.dart   # Hive boxes (products_box, cart_box)
│   │   └── product_api_service.dart # HTTP Client & JSON parsing
│   ├── models/                   # ProductModel (safe JSON parsing)
│   └── repositories/             # ProductRepository (offline-first coordinator)
├── screens/                      # Presentation Layer (Views)
│   ├── cart/                     # CartScreen
│   ├── main_screen.dart          # Bottom navigation & IndexedStack
│   └── product_list/             # ProductListScreen (responsive GridView)
└── widgets/                      # Reusable Presentation Components
    ├── cart_item_tile.dart       # Cart item row with image, unit price, subtotal
    ├── cart_summary.dart         # Sticky bottom sheet (grand total & units)
    ├── product_card.dart         # Responsive product card with in-cart badge
    └── quantity_input.dart       # Controlled numeric quantity textfield
```

### Architecture Guarantees
1. **Separation of Concerns**: UI widgets never talk to HTTP or Hive directly.
2. **Single Source of Truth**: `CartBloc` is the sole authority for cart items. No secondary cart states or local `setState` for cart management.
3. **Derived Values**: Totals (subtotal, grand total, total units) are computed dynamically from `product.price * quantity` and are **never persisted** to storage.

---

## API Integration

* **Endpoint**: `https://fakestoreapi.com/products`
* **Field Mapping**:
  * `title` $\rightarrow$ Product name
  * `price` $\rightarrow$ Unit rate (converted via `(json['price'] as num).toDouble()`)
  * `image` $\rightarrow$ Imagery URL (safely parsed to string)
* **Error Handling**: Validates HTTP 200 status code, verifies root is a JSON array, verifies individual object types, and wraps low-level network errors in custom `ApiException`.

---

## Hive Persistence

Local storage is managed by `LocalDatabase` using two isolated Hive boxes:

1. **`products_box`**: Caches the catalog (`id`, `title`, `price`, `image`).
2. **`cart_box`**: Stores only `productId` $\rightarrow$ `quantity`.

### Offline-First Flow
1. App startup immediately loads cached products from Hive (0ms flash).
2. Concurrently fetches fresh products from the API in the background.
3. If API succeeds: updates Hive cache and emits fresh catalog.
4. If API fails: gracefully retains cached products.
5. If API fails and no cache exists: displays error view with a Retry button.

---

## BLoC State Management

### `ProductBloc`
* **Events**: `LoadProducts`, `RefreshProducts`, `RetryProducts`
* **States**: `ProductInitial`, `ProductLoading`, `ProductSuccess(products)`, `ProductFailure(message)`

### `CartBloc`
* **Events**: `LoadCart`, `AddToCart`, `UpdateQuantity`, `RemoveFromCart`
* **State**: `CartState(quantities: Map<int, int>)`
  * Derived getters:
    * `uniqueItems`: number of distinct products (`quantities.length`)
    * `totalQuantity`: sum of all unit counts (`sum(quantities.values)`)
    * `getQuantity(productId)`: returns current quantity or `0`

---

## Quantity Input Behavior

The `QuantityInput` widget (`lib/widgets/quantity_input.dart`) implements precise keyboard, focus, and input behaviors:

* **Lifecycle Safety**: `TextEditingController` and `FocusNode` are created in `initState()`, **never in `build()`**, and cleanly disposed in `dispose()`.
* **Zero Input**: Entering `0` or decrementing to `0` automatically removes the product from the cart and Hive.
* **Empty Input**: Clearing the text field immediately removes the product.
* **Strict Filtering**: Utilizes `FilteringTextInputFormatter.digitsOnly`:
  * Non-numeric text rejected.
  * Negative numbers (`-`) rejected.
  * Decimals (`.`) rejected.
* **Cursor & Focus Stability**: `didUpdateWidget` guards against overwriting the controller while `_focusNode.hasFocus`, preventing cursor jumps and text clobbering during external rebuilds.
* **Upper Bounds**: Clamped up to a safe upper bound (max `9999`) to prevent integer overflow.

---

## Setup Instructions

### Prerequisites
* Flutter SDK (3.24.0 or higher)
* Dart SDK (3.5.0 or higher)
* Chrome / Edge (for Web) or Windows desktop tools

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/akshayvelur/Wahni-Order-App.git
   cd Wahni-Order-App
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run code analysis & formatting:
   ```bash
   dart format .
   flutter analyze
   ```

### Running the App

* **Chrome (Recommended for optimal memory performance)**:
  ```bash
  flutter run -d chrome --release
  ```
* **Or serve pre-built web assets**:
  ```bash
  flutter build web
  python -m http.server 8080 --directory build/web
  ```

---

## Testing Instructions

The application contains 67 comprehensive unit, widget, and integration tests across 6 test suites:

Run all tests:
```bash
flutter test --concurrency=1
```

### Test Suites

| Test Suite | Coverage |
| :--- | :--- |
| `test/product_test.dart` | `ProductModel` safe parsing, number conversion, `ProductApiService` errors & live HTTP |
| `test/hive_repository_test.dart` | Hive boxes, caching, product repository offline-first coordination |
| `test/product_bloc_test.dart` | `ProductBloc` initial, loading, success, failure, refresh, retry transitions |
| `test/cart_bloc_test.dart` | `CartBloc` mutations, derived counts, quantity updates, Hive sync, restart |
| `test/cart_screen_test.dart` | `CartScreen`, `CartSummary`, calculations ($10 \times 3 + $20 \times 2 = $70), screen sync |
| `test/cart_appbar_badge_test.dart` | Unique items badge count (`uniqueItems` NOT `totalQuantity`), tab navigation, Hive restart |
| `test/quantity_input_test.dart` | Digits-only filtering, zero/empty removal, focus stability, rebuild protection |

---

## Known Limitations

1. **FakeStoreAPI Rate Limiting**: If many requests are made in rapid succession without internet, the app will safely fall back to cached Hive data.
2. **Browser LocalStorage Quota**: When running on Web, Hive utilizes IndexedDB/localStorage. Clearing browser data clears the offline cache.
