# Technology Comparison Notes: React Native vs Flutter
**Project:** MyKidsTube (Safe Kids Video Player & Parent Portal Client)  
**Date:** October 2026  
**Implementation:** `apps/mobile-rn/` (React Native 0.86, TypeScript, Zustand) vs `apps/mobile/` (Flutter 3.x, Dart, Provider)

---

## 1. Executive Summary
Both implementations achieve 100% behavioral parity: device pairing with 6-digit codes and exponential backoff polling, salted SHA-256 parent PIN security with forced default change, offline-first media downloads with HTTP Range resume and size verification, sandboxed YouTube embed fallback, toddler touch locks, and curated per-profile catalog synchronization.

However, the architectural tradeoffs between React Native and Flutter differ substantially across video playback, storage I/O, native module maintenance, and build pipelines.

---

## 2. Component-by-Component Comparison

### A. Video Playback (`react-native-video` vs Flutter `video_player`)
- **Flutter:** Renders video frames onto a Flutter `Texture` widget within Flutter's Impeller / Skia rendering engine. This allows Flutter widgets (e.g., custom scrubbers, lock buttons, animated overlays) to render directly on top of the video with uniform blending and zero z-index fighting.
- **React Native:** Uses `react-native-video` backed by Android ExoPlayer and iOS AVPlayer. Because the video view is a native platform surface (`SurfaceView` or `TextureView`), overlays like `TouchLockOverlay` and custom player controls require explicit `zIndex` styling and `pointerEvents` coordination.
- **Embed Fallback:** When a video lacks self-hosted MP4 assets or local downloads, both apps seamlessly fall back to a sandboxed YouTube embed (`react-native-webview` vs `webview_flutter`). React Native's WebView implementation felt slightly lighter to instantiate on modern Android.

### B. File Downloads & HTTP Range Resume (`expo-file-system` vs Flutter `dio` + `dart:io`)
- **Flutter:** Downloads streamed byte-by-byte via `dio` into `dart:io` file sinks (`IOSink`). This gave fine-grained control over pausing, reading partial bytes on disk, appending with HTTP `Range: bytes=X-`, and computing checksums.
- **React Native:** Leveraged `expo-file-system`'s `createDownloadResumable`. This executes the download entirely within native Kotlin/Swift worker threads and pipes directly to `.part` files on disk without passing heavy byte chunks over the JavaScript bridge.
- **Integrity & Progress Throttling:** Both platforms required explicit throttling ($\le 4$ notifications/sec or $\ge 1\%$ delta) to prevent event loop starvation during multi-megabyte transfers. Pre-flight storage checks (`FileSystem.getFreeDiskStorageAsync`) and size validation ($\ge 90\%$ of catalog bytes) worked reliably on both.

### C. Offline Database & Storage (`expo-sqlite` vs Flutter `sqflite`)
- **Flutter:** `sqflite` operates via method channels or FFI (`sqlite3`). Transactions and batch operations are reliable and straightforward.
- **React Native:** Modern `expo-sqlite` uses C++ JSI (JavaScript Interface), allowing the JavaScript engine to interact directly with the SQLite database in memory without JSON bridge serialization.
- **Catalog Synchronization:** Both apps execute catalog upserts inside an exclusive transaction, preserving previously downloaded local paths and status. The prune safety cap ($\le 50\%$ video removal threshold before requiring parent confirmation) ensures offline libraries are never wiped unintentionally.

### D. Security & Cryptographic Storage (`expo-secure-store` / `expo-crypto` vs Flutter `flutter_secure_storage`)
- **Salted SHA-256 PIN:** Both platforms enforce the non-negotiable security requirement:
  1. A 16-byte cryptographically secure random salt generated on first run (`Crypto.getRandomBytesAsync`).
  2. The parent PIN is never stored, logged, or serialized in plaintext.
  3. Stored hash equals `sha256(salt:pin)`.
  4. If the active hash matches `sha256(salt:1234)`, the app strictly blocks access to the parent portal until the PIN is updated.
- **Storage:** React Native uses `expo-secure-store` (backed by Android Keystore / EncryptedSharedPreferences and iOS Keychain). Android backup rules explicitly exclude `SecureStore` and `kidstube_v2.db` in `secure_store_backup_rules.xml`.

### E. State Management (Zustand vs Flutter `Provider` / `ChangeNotifier`)
- **Flutter:** Uses `Provider` + `ChangeNotifier`. Calling `notifyListeners()` can cause widespread widget rebuilds unless carefully guarded with `Selector` widgets.
- **React Native:** Uses `zustand`. Zustand’s atomic selector subscriptions (`useAppStore(s => s.activeProfile)`) make it easier to isolate re-renders. For example, download progress events update only the downloading card rather than re-rendering the entire video grid.

### F. Navigation & UX Transitions
- **Flutter:** Flutter's declarative Navigator / imperative `Navigator.push` offers unified transitions across both platforms without third-party dependencies.
- **React Native:** `@react-navigation/native-stack` combined with `react-native-screens` mounts screens into native `Fragment` and `UINavigationController` containers, ensuring true native platform gesture navigation and memory efficiency for stacked screens.

---

## 3. Toolchain & Build Differences
1. **Developer Experience & Setup:**
   - Flutter provides a single command-line tool (`flutter`) that orchestrates compilation, dependency resolution, platform code generation, and running.
   - React Native bare workflow requires coordinating Node.js, Metro bundler, Gradle/AGP, and CocoaPods. Gradle version compatibility (Gradle 9.x with JBR 25) requires explicit configuration of Java environments.
2. **Type Safety:**
   - Flutter's Dart has sound null-safety by default.
   - In React Native, strict TypeScript (`strict: true`, `noImplicitAny: true`) achieved equivalent compile-time safety across all models, navigation routes, and API responses.

---

## 4. Conclusion
For a media-heavy kids application:
- **Flutter** excels at custom canvas animations, unified player-over-video rendering, and self-contained developer tooling.
- **React Native** excels at native background download offloading (native threads without JS bridge overhead), fast JSI-based SQLite queries, and leveraging standard WebViews for sandboxed third-party video embeds.
- Both frameworks successfully satisfy all strict safety, security, and offline requirements of the MyKidsTube product specification.
