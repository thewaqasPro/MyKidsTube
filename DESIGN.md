# DESIGN.md — MyKidsTube Design System & Architecture

This document establishes the UI/UX architecture, layout specifications, and design tokens for **MyKidsTube** across both the Flutter mobile client (`apps/mobile`) and the web application.

The primary objective is to replicate the familiar, production-grade interface of YouTube while stripping away all unnecessary noise, algorithmic clutter, and intrusive UI elements.

---

## 1. Visual Design Tokens

### Color Palette

| Token | Light Mode | Dark Mode | Usage |
| :--- | :--- | :--- | :--- |
| `--color-brand` | `#FF0000` | `#FF0000` | Play icon, active states, scrubber bar |
| `--color-bg-canvas` | `#FFFFFF` | `#0F0F0F` | Page and scaffold base backgrounds |
| `--color-bg-surface` | `#F2F2F2` | `#222222` | Chips, search inputs, subtle containers |
| `--color-bg-hover` | `#E5E5E5` | `#272727` | Hover states, pill selection alternative |
| `--color-border` | `#E5E5E5` | `#303030` | Structural dividers, outline pills |
| `--color-text-primary` | `#0F0F0F` | `#F1F1F1` | Video titles, primary headers |
| `--color-text-secondary` | `#606060` | `#AAAAAA` | Metadata, channel titles, timestamps |
| `--color-badge-bg` | `rgba(0, 0, 0, 0.8)` | `rgba(0, 0, 0, 0.8)` | Timestamp duration overlay |

### Typography

- **Font Family:** `Roboto`, `YouTube Sans`, or system `-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`
- **Video Title:** Font size `14px`–`15px`, line-height `1.3`, weight `500` (Medium). Must truncate strictly at **2 lines** using ellipsis (`...`).
- **Channel Name & Metadata:** Font size `12px`–`13px`, line-height `1.2`, weight `400` (Regular), muted color.
- **Section Headers:** Font size `16px`–`18px`, weight `600` (Semi-Bold).

---

## 2. Layout & Responsive Geometry

### Global Grid (Web)
- **Mobile (< 640px):** 1 column, zero horizontal gutter for thumbnails (edge-to-edge feel).
- **Tablet (640px – 1024px):** 2 columns, `16px` gap.
- **Desktop (1024px – 1440px):** 3 columns, `16px` horizontal gap, `32px` vertical gap.
- **Large Screens (> 1440px):** 4 columns, maximum container width pinned or dynamic centered grid.

### Mobile Geometry (Flutter)
- Feed items render with an edge-to-edge `16:9` preview or a card with `12px` corner radius.
- Margin between feed items: `24px` vertical spacing.

---

## 3. Core Component Specifications

### 3.1 App Header / Top Navigation
- **Height:** `56px`
- **Left Slot:** Brand mark (YouTube red rounded square with white play triangle) + "Kids" / "MyKidsTube" wordmark (`FontWeight.w700`).
- **Center Slot (Web):** Centered search pill input (`rounded-full`, `36px`–`40px` height) with a subtle inset border and search icon attached on the right.
- **Right Slot:** Search icon (on mobile), Settings/Parental gate avatar button.

### 3.2 Category Filter Pills
- Horizontal scroll view placed directly beneath the header (`height: 48px`, `padding: 8px 16px`).
- **Shape:** Stadium shape / full pill border radius (`9999px` or `BorderRadius.circular(20)`).
- **Selected State:**
  - Light mode: Fill `#0F0F0F`, text `#FFFFFF`
  - Dark mode: Fill `#F1F1F1`, text `#0F0F0F`
- **Unselected State:**
  - Light mode: Fill `#F2F2F2`, text `#0F0F0F`
  - Dark mode: Fill `#272727`, text `#F1F1F1`
- **Border:** None or `0.5px` subtle border.

### 3.3 Video Feed Card (`VideoCard`)

+-------------------------------------------------------------+
|                                                             |
|                                                             |
|                    16:9 Thumbnail Image                     |
|                                                             |
|                                                      | <- Badge
+-------------------------------------------------------------+
|  [Avatar]   Video Title Line 1 Goes Here                    |
|   36x36     Video Title Line 2 if Needed...                 |
|             Channel Name • 12K views • 2 days ago           |
+-------------------------------------------------------------+

1. **Thumbnail Container:**
   - Strict `16:9` aspect ratio.
   - Border radius: `12px` (Web and contained cards) or `0px` (Full-bleed mobile feed).
   - Background fallback: `#E0E0E0` (Light) / `#202020` (Dark).
2. **Duration Badge:**
   - Position: Bottom-right, `8px` offset.
   - Background: `rgba(0, 0, 0, 0.8)`.
   - Text: `11px`, bold, white.
   - Border radius: `4px`.
3. **Info Section:**
   - Padding: `12px 0 16px 0`.
   - Left: `36x36px` circular channel avatar image.
   - Right: Column containing:
     - Title clamped to 2 lines (`maxLines: 2, overflow: TextOverflow.ellipsis`).
     - Metadata line: Single-line string separated by bullets (`•`).

### 3.4 Player View
- **Top:** Sticky `16:9` video playback container.
- **Scrubber Bar:** High-contrast YouTube red (`#FF0000`) track with smooth scrubbing.
- **Below Player:**
  - Title: Full unabbreviated title (`16px`, `FontWeight.w600`).
  - Metadata row: View count and publish date.
  - Channel badge: Circular avatar, channel name, and subscriber count.
  - Minimal action row: Only **Favorite/Save**, **Audio Toggle**, and **Full Screen**.

---

## 4. Anti-Patterns & Exclusions

To preserve focus and child-safety, the following elements are **prohibited**:

- **No generic AI styles:** No multi-color gradient text, no neon borders, no glassmorphism backdrop blurs, no elevated drop shadows (`box-shadow: none` or subtle flat elevation).
- **No algorithmic noise:** No comments section, no live chats, no recommendation side-rabbit-holes.
- **No social triggers:** No dislike counts, no share-to-social popups, no download buttons, no donate buttons.
- **No deep menus:** No 3-dot overflow menus loaded with irrelevant options.

---

## 5. Implementation Mapping

### Flutter (`apps/mobile`)

```dart
// Theme setup sample
ThemeData youtubeTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF),
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: isDark ? const Color(0xFFF1F1F1) : const Color(0xFF0F0F0F)),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: isDark ? const Color(0xFF272727) : const Color(0xFFF2F2F2),
    ),
  );
}
