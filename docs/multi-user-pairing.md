# Multi-User & Multi-Family Guide

This document explains how to configure KidsTube for multiple children across multiple devices, as well as how to share the server with friends while maintaining total privacy.

---

## 1. Hierarchy Concept

```
Family Account (Waqas's Household)
   ├── Child 1: Maya (Age 3, Toddler) ────────── Device 1: Maya's iPad
   ├── Child 2: Noah (Age 7, Early Reader) ──── Device 2: Noah's Android Phone
   └── Child 3: Leo (Age 9, Big Kid) ────────── Device 3: Leo's Phone

Family Account (Friend's Household)
   └── Child 1: Sarah (Age 5) ───────────────── Device 4: Sarah's Tablet
```

---

## 2. Onboarding 5 Kids & 5 Devices

### Step 1: Create Profiles
1. Open the Web Dashboard: `http://YOUR_VPS_IP:8080/`
2. Click the **Child Profiles** tab.
3. Click **Add Child Profile** for each of your kids:
   - Name: *Maya* | Avatar: 🐻 Bear | Age: *Toddler*
   - Name: *Noah* | Avatar: 🚀 Rocket | Age: *Early Reader*
   - Name: *Leo* | Avatar: 🦁 Lion | Age: *Big Kid*

### Step 2: Pair the First Child's Phone
1. Install and launch the KidsTube app on Child 1's phone.
2. The phone displays a big screen with a code: **`KID-482`**.
3. On your computer/phone dashboard:
   - Click **Pair Devices**.
   - Type `KID-482`.
   - Select **Maya (Dedicated Phone)** from the dropdown.
   - Click **Pair & Authorize Device**.
4. Child 1's phone immediately unlocks into Maya's personalized space.

Repeat this simple 30-second process for all 5 phones!

---

## 3. Dedicated vs. Shared Tablet Modes

- **Dedicated Mode:** The device is bound to a single child. When the child opens the app, it goes straight to their library.
- **Shared Mode:** If two kids share one tablet in the living room, select **Shared Tablet** during pairing. When the app opens, it displays the colorful **"Who Is Watching?"** screen with their avatars. Tapping an avatar loads that child's videos.

---

## 4. Multi-Family Isolation (Sharing with Friends)

If a friend wants to use your server:

1. **Independent Catalogs:** Your friend gets their own family account. Their videos are isolated from yours.
2. **Parent PIN & Password:** Your friend has their own master PIN to protect settings.
3. **Smart Media Deduplication:** 
   - If both you and your friend add the same YouTube cartoon, the VPS only stores one copy of the `.mp4` file on disk.
   - Both families see the video in their respective apps, saving disk space and download time.
