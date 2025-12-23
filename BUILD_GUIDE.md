# Build & Installation Guide - LED Glow

This guide documents the steps to build, sign, and install the LED Glow app on your real iOS device.

## 1. Prerequisites
- **Xcode 16+**: Required for iOS 18+ deployment.
- **XcodeGen**: Used to generate the `.xcodeproj`.
- **Apple Developer Account**: For code signing.
- **Physical Hardware**: ELK-BLEDDM / Lotus Lantern BLE controller.

## 2. Local Build Steps
1. **Generate Project**:
   ```bash
   brew install xcodegen
   xcodegen generate
   ```
2. **Open in Xcode**:
   ```bash
   open LEDControl.xcodeproj
   ```
3. **Configure Signing**:
   - Select the `LEDControl` target.
   - Go to `Signing & Capabilities`.
   - Update the `Bundle Identifier` to match your profile.
   - Select your Development Team.

4. **Deploy to Device**:
   - Connect your iPhone via USB.
   - Select your iPhone as the build target.
   - Press `Cmd + R`.

## 3. CI/CD with Codemagic
We've provided a `codemagic.yaml` for automated IPA generation.
1. Connect your Git repository to Codemagic.
2. In **Environment Variables**, add:
   - `APP_STORE_CONNECT_KEY_IDENTIFIER`
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_PRIVATE_KEY`
3. Trigger the `ios-workflow`.
4. Download the signed `.ipa` from the build artifacts.

## 4. Hardware Sideloading (Alternative)
If you don't use Xcode, you can use the IPA with:
- **AltStore / Sideloadly**:
  - Drag the generated `.ipa` into the tool.
  - Sign with your Apple ID.
  - Recommended for testing without a full dev setup.

## 5. Testing on Real Hardware
1. Power your LED Strip.
2. Open **LED Glow**.
3. Go to **Settings** and ensure Bluetooth is scanning.
4. Selected the discovered device.
5. Use the **Diagnostics** tab to verify byte-transfers in real-time.
