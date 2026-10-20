# In-App Update System & Release v1.4.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide an in-app "Check for Updates" feature in the Parent Center verifying against a public GitHub repository manifest/API, displaying release notes and direct APK download/install links, and publish a new app update (v1.4.0).

**Architecture:** A dual-source `AppUpdateService` checks update status by inspecting a raw repo manifest `version.json` with fallback to GitHub Releases REST API. It compares semver versions against the local app version (`package_info_plus`). The Parent Settings tab surfaces a "Check for Updates" tile with dynamic badges, and displays an `AppUpdateDialog` allowing parents to review release notes and trigger direct APK download via `url_launcher`.

**Tech Stack:** Dart/Flutter, `package_info_plus`, `url_launcher`, `dio`, Provider, Material 3, GitHub REST API / raw content.

**Spec:** In-app update system with GitHub direct verification, semver comparison, update dialog with release notes & APK download links, and release of v1.4.0.

## Global Constraints
- Target repository: `https://github.com/thewaqasPro/MyKidsTube`
- Direct raw URL: `https://raw.githubusercontent.com/thewaqasPro/MyKidsTube/main/version.json`
- Fallback API: `https://api.github.com/repos/thewaqasPro/MyKidsTube/releases/latest`
- Semver parsing must handle tags with or without leading `v` and build numbers (`1.4.0+4`).
- Must not block UI thread during network queries; gracefully handle offline states.

## Review Focus
1. Offline / Network error during update check: user receives friendly error snackbar without crashes.
2. App already on latest version: dialog clearly states "You're up to date!" with installed version.
3. Semver comparison edge cases: correctly identifies `1.4.0` > `1.3.0`, `1.3.1` > `1.3.0`, and `1.3.0` == `1.3.0`.
4. Release assets selection: prioritizes arm64 or universal APK for Android downloads.
5. URL launch failure: fallback mechanism informs the user with direct link if external browser cannot open.

---

### Task 1: Add Dependencies & Create Version Manifest (`version.json`)

**Files:**
- Modify: `apps/mobile/pubspec.yaml`
- Create: `version.json`
- Test: `apps/mobile/test/version_manifest_test.dart`

**Interfaces:**
- Consumes: None
- Produces: `version.json` schema: `{ "version": String, "versionCode": int, "releaseTitle": String, "releaseNotes": String, "apkDownloadUrl": String, "downloadPageUrl": String }`

- [ ] **Step 1: Write the failing test for version manifest validation**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Add `url_launcher: ^6.3.3` and `package_info_plus: ^9.0.1` to `apps/mobile/pubspec.yaml` and create `version.json` in root**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 2: Implement `AppUpdateService` & Semver Comparison Logic

**Files:**
- Create: `apps/mobile/lib/models/app_update_info.dart`
- Create: `apps/mobile/lib/services/app_update_service.dart`
- Test: `apps/mobile/test/app_update_service_test.dart`

**Interfaces:**
- Consumes: `version.json` format, GitHub Releases REST API JSON
- Produces: `AppUpdateService.checkForUpdate({String? currentVersionOverride}) -> Future<AppUpdateInfo>`, `AppUpdateService.compareSemver(String current, String latest) -> int`

- [ ] **Step 1: Write unit tests covering semver comparison (greater, equal, smaller, with/without 'v') and mock JSON manifest parsing**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `AppUpdateInfo` model and `AppUpdateService`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 3: Integrate Update Checking into `AppProvider`

**Files:**
- Modify: `apps/mobile/lib/providers/app_provider.dart`
- Test: `apps/mobile/test/app_update_provider_test.dart`

**Interfaces:**
- Consumes: `AppUpdateService`
- Produces: `AppProvider.checkForUpdate({bool manual = false}) -> Future<AppUpdateInfo?>`, `AppProvider.availableUpdate` getter

- [ ] **Step 1: Write test verifying AppProvider triggers update check and exposes update state**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement update methods in `AppProvider`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 4: Build Update Dialog & "Check for Updates" UI in Parent Settings

**Files:**
- Create: `apps/mobile/lib/widgets/app_update_dialog.dart`
- Modify: `apps/mobile/lib/screens/parent_dashboard_screen.dart`
- Test: `apps/mobile/test/app_update_ui_test.dart`

**Interfaces:**
- Consumes: `AppUpdateInfo`, `AppProvider.checkForUpdate`
- Produces: `AppUpdateDialog.show(BuildContext, AppUpdateInfo)`, interactive card in `ParentDashboardScreen`

- [ ] **Step 1: Write widget test verifying "Check for Updates" button and dialog presentation**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `AppUpdateDialog` and update `_buildSettingsTab` in `ParentDashboardScreen`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 5: Bump App Version to v1.4.0 & Prepare Release

**Files:**
- Modify: `apps/mobile/pubspec.yaml` (bump to `1.4.0+4`)
- Modify: `version.json` (reflect `1.4.0`)
- Modify: `README.md`
- Test: `apps/mobile/test/version_manifest_test.dart`

**Interfaces:**
- Consumes: All completed features in v1.4.0
- Produces: Git tag `v1.4.0`, updated docs, release-ready repo

- [ ] **Step 1: Update version in `pubspec.yaml` to `1.4.0+4` and update `version.json`**
- [ ] **Step 2: Update `README.md` with new features in v1.4.0**
- [ ] **Step 3: Run full static analysis `flutter analyze` and tests**
- [ ] **Step 4: Commit and push changes, create git tag `v1.4.0`**
