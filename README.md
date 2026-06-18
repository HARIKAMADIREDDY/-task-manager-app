# Task Manager App

A highly polished, offline-capable Task Manager application built with Flutter. This project demonstrates advanced architectural patterns, hybrid state management, and secure JWT authentication.

## 🚀 Features Implemented
* **Authentication:** Full Login screen with secure JWT validation and automatic silent session refreshing.
* **Hybrid State Management:** Merges remote API tasks with local custom data seamlessly.
* **Offline Mode:** Fully functional without an internet connection using local Hive caching.
* **Task Operations:** Create, Read, Update, and Soft-Delete (Bin) tasks.
* **Dynamic Weather Integration:** Automatically geocodes task locations and displays real-time weather badges.
* **Advanced UI/UX:** Infinite scroll pagination, custom Priority & Favorite indicators, dropdown filtering, and responsive design.

## 📡 APIs Used
* **DummyJSON API (`https://dummyjson.com`)**
  * `/auth/login` - Initial user authentication
  * `/auth/refresh` - Background session refresh
  * `/todos` - Fetching, adding, updating, and deleting tasks
* **Open-Meteo API (`https://api.open-meteo.com`)**
  * `/v1/search` (Geocoding API) - Converts city names into Latitude/Longitude
  * `/v1/forecast` (Weather API) - Fetches real-time temperature and weather conditions

## 🔐 JWT Authentication Flow
1. **Login:** User submits credentials to `/auth/login`. The server returns a short-lived `accessToken` and a long-lived `refreshToken`.
2. **Interception:** A Dio `InterceptorsWrapper` acts as a middleman, automatically injecting the `accessToken` into the `Authorization: Bearer` header of every outgoing network request.
3. **Silent Refresh:** If an API request fails with a `401 Unauthorized` (Token Expired) error, the interceptor pauses the app, sends the `refreshToken` to `/auth/refresh` to get a new `accessToken`, saves it, and silently retries the original failed request.

## 💾 Token Storage & Local Storage
* **Token Storage:** `flutter_secure_storage` is used to encrypt and securely store the JWT tokens in the device's keychain.
* **Local Storage:** `Hive` (a lightweight, blazing-fast NoSQL database) is used for offline caching. 
  * A **4-Box Architecture** is used to separate concerns:
    1. `tasksBox`: Caches the main API task list for offline viewing.
    2. `addedTasksBox`: Permanently saves tasks created by the user to prevent them from being wiped on API sync.
    3. `deletedTasksBox`: Acts as a local "Trash Bin" for soft-deleted tasks.
    4. `weatherBox`: Caches weather data to minimize redundant API calls.

## 🧠 State Management
* **Riverpod** is used for robust, scalable state management. 
* Providers are separated into logical layers (e.g., `taskProvider`, `authProvider`, `weatherProvider`), ensuring the UI remains completely decoupled from business logic.

## 🛠 Project Setup & Run Instructions

### Prerequisites
* Flutter SDK (3.x or higher)
* Dart SDK

### Steps to Run
1. Clone the repository to your local machine.
2. Open a terminal and navigate to the project directory.
3. Run `flutter pub get` to install all required dependencies (Dio, Riverpod, Hive, etc.).
4. Connect an Android/iOS emulator or a physical device.
5. Run `flutter run` to launch the application.

### Test Credentials
To test the login flow, use any user from the DummyJSON database:
* **Username:** `evelyng`
* **Password:** `evelyngpass`

## ⚠️ Assumptions & Known Issues
* **BFF Pattern Assumption:** Because the DummyJSON `addTodo` API only accepts `todo`, `completed`, and `userId`, it actively drops custom fields like `priority` and `isFavorite`. The app assumes a Backend-For-Frontend (BFF) approach, re-attaching these local fields to the API response before saving to Hive.
* **API Pagination Limitations:** The DummyJSON API does not allow filtering tasks by custom local criteria (like Favorites or Bin). Therefore, infinite scroll pagination is disabled for local-only filters to prevent endless loading loops.
