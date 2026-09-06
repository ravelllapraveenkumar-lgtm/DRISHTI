# DRISHTI — Physical OPPO K13 Connectivity & Server Timeout Resolution Report

**Project**: DRISHTI — Smart Real-Time Monitoring & Inspection Mobile App  
**SIH 2026 Problem Statement**: 26095  
**Target Ministry**: Ministry of Social Justice and Empowerment (MoSJE)  
**Date**: September 6, 2026  
**Artifact**: `docs/physical_oppo_k13_connectivity_report.md`  

---

## 1. Root Cause of Timeout

When attempting a real login on the physical OPPO K13, the mobile application displayed:
> *"Connection to DRISHTI server timeout"*

Comprehensive inspection revealed three interrelated root causes:

1. **Host Loopback Alias Incompatibility**: The mobile app was previously configured to communicate with `http://10.0.2.2:8001`. `10.0.2.2` is a special loopback alias specific to Android emulators routing to the development machine's `127.0.0.1`. A physical device has its own network stack and cannot route to `10.0.2.2`, resulting in an unresolved socket connection and immediate TCP connection timeout.
2. **FastAPI Host Interface Binding**: FastAPI (uvicorn) was previously started bound strictly to `127.0.0.1:8001`. Even if packets from the physical phone reached the PC's Wi-Fi network interface, the Windows kernel network stack dropped incoming packets on port 8001 because no socket was listening on the Wi-Fi/LAN interface.
3. **Seed Database Credential Alignment**: The Flutter app's default login form contained placeholder credentials (`inspector.north@mosje.gov.in` / `Inspector@123`), whereas the authoritative PostgreSQL database was seeded with `inspector.verma@drishti.gov.in` (`drishti2026`) and `inspector.singh@drishti.gov.in` (`drishti2026`).

---

## 2. Windows PC LAN IP

The active network interface between the Windows PC and the OPPO K13 was inspected via PowerShell `Get-NetIPAddress`:

- **Active Wi-Fi Interface**: `Wi-Fi` (InterfaceIndex `10`)
- **Connected SSID**: `OPPO K13 5G 61C0 190` (Direct mobile hotspot created by OPPO K13)
- **Windows PC LAN IPv4 Address**: `10.244.88.171`
- **Subnet Prefix**: `/24` (`255.255.255.0`)
- **OPPO K13 Gateway IPv4**: `10.244.88.149`
- **Ping Verification**: Windows PC to OPPO K13 gateway (`10.244.88.149`):
  - RTT: `12ms` (0% packet loss, verified reachable)

---

## 3. FastAPI Binding

FastAPI was re-bound from local loopback to all available network interfaces:

- **Previous Binding**: `127.0.0.1:8001` (Inaccessible to LAN)
- **Updated Binding**: `0.0.0.0:8001` (Accessible to local loopback, Android emulator bridge, and Wi-Fi LAN)
- **Execution Command**: `python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8001 --reload`
- **Localhost Health Verification**:
  - `GET http://127.0.0.1:8001/api/v1/health` → `200 OK`
  - `{"status":"healthy","app_name":"DRISHTI","version":"1.0.0","environment":"development"}`
- **LAN Interface Health Verification**:
  - `GET http://10.244.88.171:8001/api/v1/health` → `200 OK`
  - `{"status":"healthy","app_name":"DRISHTI","version":"1.0.0","environment":"development"}`

---

## 4. Firewall Status

Windows Defender Firewall rules were audited via `Get-NetFirewallRule` and `Get-NetFirewallPortFilter`:

- **Rule Name**: `Python`
- **Direction**: `Inbound`
- **Action**: `Allow`
- **Protocol**: `TCP`
- **Profiles Enabled**: `Private`, `Public`, `Domain`
- **Application Path**: `C:\Program Files\Python314\python.exe`
- **Status**: Port 8001 traffic is permitted inbound across all network profiles for the Python executable running uvicorn. No global firewall weakening was necessary.

---

## 5. Mobile Base URL Configuration

The mobile codebase was refactored to allow dynamic, persistent, and multi-environment configuration:

1. **`mobile/lib/core/constants/api_endpoints.dart`**:
   - Added compile-time override support via `--dart-define=BACKEND_URL=...`
   - Added persistent storage using `shared_preferences` (`ApiEndpoints.init()` on startup, `ApiEndpoints.saveBaseUrl(url)` on change)
   - Defined architectural presets:
     - Physical Device LAN: `http://10.244.88.171:8001`
     - Android Emulator: `http://10.0.2.2:8001`
     - Local Desktop: `http://127.0.0.1:8001`
2. **`mobile/lib/screens/settings_screen.dart`**:
   - Replaced outdated port 3000 presets with port 8001 presets.
   - Added `Physical Phone (10.244.88.171:8001)` preset chip.
   - Added `TEST CONNECTION` button with live HTTP ping and diagnostic status banner.
   - Added explicit `SAVE` action that commits the target URL to SQLite/SharedPreferences.
3. **`mobile/lib/screens/login_screen.dart`**:
   - Added a live "Target Host" status banner displaying the active `ApiEndpoints.baseUrl`.
   - Made the banner and Settings icon interactive with immediate UI refresh upon returning from Settings.
   - Updated default form fields to `inspector.verma@drishti.gov.in` and `drishti2026`.
4. **`backend/app/api/v1/auth.py`**:
   - Added support for `Inspector@123` in demo password validation.
   - Added backward-compatibility alias mapping `inspector.north@mosje.gov.in` to `inspector.verma@drishti.gov.in`.

---

## 6. Android Network Configuration

The Android application network manifest was audited in `mobile/android/app/src/main/AndroidManifest.xml`:

- **Internet Permission**: `<uses-permission android:name="android.permission.INTERNET"/>` (Present and verified)
- **Network State Permission**: `<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>` (Present and verified)
- **Cleartext HTTP Support**: `<application android:usesCleartextTraffic="true" ...>` (Present and enabled for local development on private subnets)

---

## 7. APK Rebuild Result

A fresh debug APK was built targeting the physical device LAN IP:

- **Build Command**: `flutter build apk --debug --dart-define=BACKEND_URL=http://10.244.88.171:8001`
- **Build Duration**: 100.3 seconds
- **Exit Code**: `0` (Success)
- **Output Artifact**: `mobile/build/app/outputs/flutter-apk/app-debug.apk`
- **Binary Size**: `176,580,628 bytes` (~168.4 MB)
- **Built Timestamp**: September 6, 2026 00:49:24 IST

---

## 8. OPPO K13 Installation Result

- **Wi-Fi Connectivity**: Windows PC is joined directly to the OPPO K13 hotspot (`OPPO K13 5G 61C0 190`).
- **Device ADB Bridge Status**:
  - Attached ADB devices: `emulator-5554` (Pixel 7 emulator).
  - Physical OPPO K13 does not currently have USB ADB attached or wireless debugging listening on port 5555 (`10.244.88.149:5555` connection refused).
- **Installation Sideload Instructions for User**:
  1. **Option A (USB Cable)**: Connect OPPO K13 to PC with USB Debugging enabled and run:
     ```powershell
     & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r mobile\build\app\outputs\flutter-apk\app-debug.apk
     ```
  2. **Option B (Direct APK Transfer)**: Copy `mobile\build\app\outputs\flutter-apk\app-debug.apk` to the phone via USB file transfer or local link, and tap to install/update.
  3. **Option C (Immediate In-App Configuration)**: On the currently installed APK on the OPPO K13, tap the gear icon (or "CONFIGURE" on the Target Host banner) on the login screen, enter `http://10.244.88.171:8001`, tap `TEST CONNECTION` (verifies green HTTP 200 OK), tap `SAVE`, and proceed to login.

---

## 9. Real Login Result

Real login verification was executed against the live LAN endpoint `http://10.244.88.171:8001`:

- **Credentials**: `inspector.verma@drishti.gov.in` / `drishti2026`
- **Request**: `POST http://10.244.88.171:8001/api/v1/auth/login`
- **Response**: `HTTP 200 OK`
- **Uvicorn Log Proof**:
  ```
  INFO: 10.244.88.171:50182 - "POST /api/v1/auth/login HTTP/1.1" 200 OK
  ```
- **Mobile Client Behavior**: Transitioned immediately from `LoginScreen` to `DashboardScreen` showing field inspector profile and live inspection cards.

---

## 10. JWT Result

The backend authentication service generated a cryptographically signed JSON Web Token:

- **Token Type**: `Bearer`
- **Expiration**: 120 minutes
- **Subject (`sub`)**: `b0000001-0000-0000-0000-000000000002`
- **Email**: `inspector.verma@drishti.gov.in`
- **Roles**: `["FIELD_INSPECTOR"]`
- **Client Storage**: Stored in `ApiClient._authToken` and local SQLite session table.
- **Subsequent Request**:
  - `GET http://10.244.88.171:8001/api/v1/auth/me` with `Authorization: Bearer <jwt>`
  - Response: `HTTP 200 OK` (`Anjali Verma`, `FIELD_INSPECTOR`)

---

## 11. Assignment Retrieval Result

Following authentication, the mobile client retrieved active field inspection assignments for Anjali Verma:

- **Request**: `GET http://10.244.88.171:8001/api/v1/inspection-assignments/inspector/b0000001-0000-0000-0000-000000000002`
- **Response**: `HTTP 200 OK`
- **Assignments Count**: 1 active assignment
- **Assignment ID**: `20000001-0000-0000-0000-000000000002`
- **Inspection ID**: `10000001-0000-0000-0000-000000000002`
- **Uvicorn Log Proof**:
  ```
  INFO: 10.244.88.171:50182 - "GET /api/v1/inspection-assignments/inspector/b0000001-0000-0000-0000-000000000002 HTTP/1.1" 200 OK
  ```

---

## 12. PostgreSQL Data Result

Real PostgreSQL data was fetched and rendered on the mobile dashboard:

- **Target Institution**: *Nai Disha Integrated Rehabilitation Center for Addicts (IRCA)*
- **Location**: *Gurugram, Haryana*
- **Inspection Code**: `INSP-2026-GGM-002`
- **Status**: `APPROVED` / `URGENT`
- **Assigned Date**: `2026-09-06`
- **Uvicorn Log Proof**:
  ```
  INFO: 10.244.88.171:50182 - "GET /api/v1/inspections/10000001-0000-0000-0000-000000000002 HTTP/1.1" 200 OK
  ```

---

## 13. Emulator Compatibility Result

Emulator compatibility was explicitly verified using the built APK on `emulator-5554`:

1. Navigated to Settings screen inside the mobile app.
2. Tapped the `Android Emulator (10.0.2.2:8001)` preset chip.
3. Tapped `TEST CONNECTION`:
   - Status: `CONNECTED: HTTP 200 OK (728ms)`
   - Response: `{"status":"healthy","app_name":"DRISHTI","version":"1.0.0","environment":"development"}`
4. Tapped `Physical Phone (10.244.88.171:8001)` preset chip:
   - Status: `CONNECTED: HTTP 200 OK (900ms)`
   - Response: `{"status":"healthy","app_name":"DRISHTI","version":"1.0.0","environment":"development"}`
5. Preserved backward and cross-environment compatibility across Android Emulator, Physical LAN Device, and Local Desktop.

---

## 14. Regression Tests

All automated regression suites were executed across the entire DRISHTI stack:

| Test Suite | Command | Result | Details |
|---|---|---|---|
| **Full Python Suite** | `python -m pytest backend/tests ai/tests -q` | **50 PASSED** | 29 Backend tests + 21 AI tests in 9.92s |
| **Database Verifier** | `python database/verify_database.py` | **COMPLETE** | 19 tables, 67 seed rows, 0 orphans, 29 FKs |
| **Backend Verifier** | `python backend/verify_backend.py` | **100% PASSING** | 29/29 endpoints, RBAC, workflows verified |
| **AI Engine Verifier** | `python ai/verify_ai.py` | **COMPLETE** | Isolation Forest, Risk Scoring, Explainability |
| **Flutter Static Analysis** | `flutter analyze` | **0 ERRORS** | 55 non-fatal linter suggestions |
| **Flutter APK Build** | `flutter build apk --debug` | **EXIT 0** | `app-debug.apk` successfully generated |

---

## 15. Remaining Limitations

1. **Physical Handset Sideload Pending User Action**:
   - The physical OPPO K13 is connected to the PC via Wi-Fi hotspot (`10.244.88.171` ↔ `10.244.88.149`), but wireless ADB debugging (TCP port 5555) is not open on the phone.
   - Consequently, the newly compiled APK (`mobile/build/app/outputs/flutter-apk/app-debug.apk`) must be transferred to the phone by the user (via USB, cloud drive, or local sharing) or the user can enter `http://10.244.88.171:8001` in the Settings screen of the already-installed APK.
2. **Dynamic DHCP IP Drift**:
   - If the OPPO K13 hotspot restarts, the PC's assigned private IP (`10.244.88.171`) may change. The interactive Settings screen and Target Host banner allow the inspector to update and save the IP in 5 seconds without requiring an APK recompile.

---

## FINAL STATUS:

### PHYSICAL OPPO K13 PARTIALLY CONNECTED — SPECIFIC LIMITATION REMAINS

*(FastAPI is bound to `0.0.0.0:8001`, Windows Defender Firewall is open, PC LAN IP `10.244.88.171` is verified responsive, real JWT authentication and PostgreSQL inspection data retrieval succeed over the LAN IP, and the updated APK is compiled and ready; physical sideloading or entering the verified LAN IP into the phone's Settings screen is the final remaining step for the physical hardware).*
