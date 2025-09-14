# APK Testing Workflow

A comprehensive guide for testing APK files on macOS using Android emulators, including ADB commands, debugging techniques, and automated testing strategies.

## Table of Contents

- [Pre-Installation Testing](#pre-installation-testing)
- [Installation Testing](#installation-testing)
- [Functional Testing](#functional-testing)
- [Performance Testing](#performance-testing)
- [ADB Command Reference](#adb-command-reference)
- [Debugging Techniques](#debugging-techniques)
- [Automated Testing Scripts](#automated-testing-scripts)
- [Testing Different Scenarios](#testing-different-scenarios)
- [Log Analysis](#log-analysis)
- [Best Practices](#best-practices)

## Pre-Installation Testing

Before installing an APK, perform these preliminary checks:

### 1. APK File Analysis

```bash
# Check APK file integrity
file your-app.apk
ls -la your-app.apk

# Extract APK information using aapt
aapt dump badging your-app.apk

# Get detailed package information
aapt dump xmltree your-app.apk AndroidManifest.xml

# Check APK permissions
aapt dump permissions your-app.apk

# Verify APK signature
jarsigner -verify -verbose your-app.apk
```

### 2. APK Content Inspection

```bash
# Extract APK contents for inspection
mkdir apk-inspection
cd apk-inspection
unzip ../your-app.apk

# Check native libraries
ls -la lib/

# Check assets and resources
ls -la assets/
ls -la res/

# View manifest file (if extracted)
cat AndroidManifest.xml
```

### 3. Compatibility Check

```bash
# Get target SDK and minimum SDK versions
aapt dump badging your-app.apk | grep "sdkVersion\|targetSdkVersion"

# Check supported architectures
aapt dump badging your-app.apk | grep "native-code"

# Verify supported screen densities
aapt dump badging your-app.apk | grep "densities"
```

## Installation Testing

### 1. Basic Installation

```bash
# Install APK
adb install your-app.apk

# Install with replace flag (if already installed)
adb install -r your-app.apk

# Install with downgrade allowed
adb install -d your-app.apk

# Install to specific device
adb -s <device-id> install your-app.apk
```

### 2. Installation Verification

```bash
# Verify installation
adb shell pm list packages | grep your.package.name

# Get detailed package information
adb shell dumpsys package your.package.name

# Check installed APK path
adb shell pm path your.package.name

# Verify package integrity
adb shell pm verify your.package.name
```

### 3. Permission Verification

```bash
# List all permissions for the app
adb shell dumpsys package your.package.name | grep permission

# Grant specific permissions
adb shell pm grant your.package.name android.permission.CAMERA
adb shell pm grant your.package.name android.permission.WRITE_EXTERNAL_STORAGE

# Revoke permissions
adb shell pm revoke your.package.name android.permission.CAMERA
```

## Functional Testing

### 1. Launch Testing

```bash
# Get main activity name
adb shell dumpsys package your.package.name | grep -A 1 "android.intent.action.MAIN"

# Launch app via monkey
adb shell monkey -p your.package.name -c android.intent.category.LAUNCHER 1

# Launch specific activity
adb shell am start -n your.package.name/.MainActivity

# Launch with intent data
adb shell am start -a android.intent.action.VIEW -d "http://example.com" your.package.name
```

### 2. User Interaction Testing

```bash
# Generate random user events
adb shell monkey -p your.package.name -v 100

# Generate specific events with seed for reproducibility
adb shell monkey -p your.package.name -s 12345 -v 100

# Focus on specific event types
adb shell monkey -p your.package.name --pct-touch 70 --pct-motion 30 100

# Ignore crashes and ANRs (for stress testing)
adb shell monkey -p your.package.name --ignore-crashes --ignore-timeouts 1000
```

### 3. Input Simulation

```bash
# Send text input
adb shell input text "Hello World"

# Send key events
adb shell input keyevent KEYCODE_ENTER
adb shell input keyevent KEYCODE_BACK
adb shell input keyevent KEYCODE_HOME

# Send touch events
adb shell input tap 500 500
adb shell input swipe 300 500 700 500 1000

# Send hardware key events
adb shell input keyevent KEYCODE_VOLUME_UP
adb shell input keyevent KEYCODE_POWER
```

## Performance Testing

### 1. Memory Usage Analysis

```bash
# Monitor memory usage
adb shell dumpsys meminfo your.package.name

# Get memory usage over time
while true; do
  adb shell dumpsys meminfo your.package.name | grep TOTAL
  sleep 5
done

# Check for memory leaks
adb shell dumpsys procstats --hours 1 your.package.name
```

### 2. CPU Usage Monitoring

```bash
# Monitor CPU usage
adb shell top -n 1 | grep your.package.name

# Continuous CPU monitoring
adb shell top | grep your.package.name

# Get detailed process information
adb shell ps | grep your.package.name
```

### 3. Battery Usage Analysis

```bash
# Check battery usage
adb shell dumpsys batterystats your.package.name

# Reset battery stats
adb shell dumpsys batterystats --reset

# Monitor power consumption
adb shell dumpsys power
```

### 4. Network Activity

```bash
# Monitor network usage
adb shell dumpsys netstats detail

# Check network connectivity
adb shell ping google.com

# View network interfaces
adb shell netcfg
```

## ADB Command Reference

### Essential ADB Commands

```bash
# Device Management
adb devices                          # List connected devices
adb connect <ip>:<port>             # Connect to device over network
adb disconnect                      # Disconnect from all devices
adb reboot                         # Reboot device
adb reboot bootloader              # Reboot to bootloader
adb reboot recovery               # Reboot to recovery mode

# Package Management
adb install <apk>                  # Install APK
adb uninstall <package>           # Uninstall package
adb shell pm clear <package>      # Clear app data
adb shell pm disable <package>    # Disable app
adb shell pm enable <package>     # Enable app
adb shell pm list packages        # List all packages

# File Transfer
adb push <local> <remote>         # Copy file to device
adb pull <remote> <local>         # Copy file from device
adb shell                         # Open shell on device

# Debugging
adb logcat                        # View log output
adb logcat -c                     # Clear log
adb logcat | grep <tag>          # Filter logs
adb bugreport                    # Generate bug report

# Screen Capture
adb shell screencap /sdcard/screen.png    # Take screenshot
adb shell screenrecord /sdcard/demo.mp4   # Record screen
```

### Advanced ADB Commands

```bash
# Process Management
adb shell ps                           # List running processes
adb shell kill <pid>                  # Kill process
adb shell am kill <package>           # Kill app process
adb shell am force-stop <package>     # Force stop app

# System Information
adb shell getprop                     # Get system properties
adb shell dumpsys                    # Dump system services
adb shell df                         # Check disk usage
adb shell free                       # Check memory usage

# Developer Options
adb shell settings put global adb_enabled 1              # Enable ADB
adb shell settings put global development_settings_enabled 1  # Enable dev settings
adb shell wm size                    # Get screen resolution
adb shell wm density                 # Get screen density
```

## Debugging Techniques

### 1. Logcat Analysis

```bash
# Basic logcat
adb logcat

# Filter by tag
adb logcat -s YourTag

# Filter by priority (V, D, I, W, E, F)
adb logcat *:E

# Filter by package
adb logcat | grep "$(adb shell ps | grep your.package.name | awk '{print $2}')"

# Save logs to file
adb logcat > app-logs.txt

# Real-time filtered logging
adb logcat -s YourTag:D AndroidRuntime:E
```

### 2. Crash Analysis

```bash
# Monitor for crashes
adb logcat | grep -i "fatal\|exception\|crash"

# Get ANR traces
adb shell cat /data/anr/traces.txt

# Check system crash logs
adb shell dumpsys dropbox --print

# Generate and pull bug report
adb bugreport bugreport.zip
```

### 3. Network Debugging

```bash
# Monitor network requests
adb logcat | grep -i "http\|url\|network"

# Check network state
adb shell dumpsys connectivity

# Test connectivity
adb shell ping 8.8.8.8
adb shell curl -I http://google.com
```

## Automated Testing Scripts

### 1. Basic Testing Script

Create `test-apk.sh`:

```bash
#!/bin/bash
# Basic APK testing script

APK_FILE=$1
PACKAGE_NAME=$2

if [ -z "$APK_FILE" ] || [ -z "$PACKAGE_NAME" ]; then
    echo "Usage: $0 <apk-file> <package-name>"
    exit 1
fi

echo "Starting APK testing for $PACKAGE_NAME"

# Install APK
echo "Installing APK..."
adb install -r "$APK_FILE"

# Wait for installation
sleep 3

# Launch app
echo "Launching app..."
adb shell monkey -p "$PACKAGE_NAME" -c android.intent.category.LAUNCHER 1

# Wait for app to start
sleep 5

# Generate some user events
echo "Generating user events..."
adb shell monkey -p "$PACKAGE_NAME" --pct-touch 80 --pct-motion 20 50

# Check memory usage
echo "Checking memory usage..."
adb shell dumpsys meminfo "$PACKAGE_NAME"

# Stop app
echo "Stopping app..."
adb shell am force-stop "$PACKAGE_NAME"

echo "Testing completed!"
```

### 2. Performance Testing Script

Create `performance-test.sh`:

```bash
#!/bin/bash
# Performance testing script

PACKAGE_NAME=$1
DURATION=${2:-60}  # Default 60 seconds

echo "Starting performance test for $PACKAGE_NAME (Duration: ${DURATION}s)"

# Start memory monitoring
(
  while true; do
    echo "$(date): $(adb shell dumpsys meminfo $PACKAGE_NAME | grep 'TOTAL' | awk '{print $2}')"
    sleep 5
  done
) > memory-usage.log &
MEMORY_PID=$!

# Start CPU monitoring
(
  while true; do
    adb shell top -n 1 | grep $PACKAGE_NAME
    sleep 5
  done
) > cpu-usage.log &
CPU_PID=$!

# Generate user events
adb shell monkey -p "$PACKAGE_NAME" --throttle 1000 $((DURATION * 10))

# Stop monitoring
kill $MEMORY_PID $CPU_PID 2>/dev/null

echo "Performance test completed. Check memory-usage.log and cpu-usage.log"
```

### 3. Compatibility Testing Script

Create `compatibility-test.sh`:

```bash
#!/bin/bash
# Test APK compatibility across different configurations

APK_FILE=$1

# Test different screen orientations
test_orientations() {
    echo "Testing screen orientations..."
    adb shell content insert --uri content://settings/system --bind name:s:accelerometer_rotation --bind value:i:0
    adb shell content insert --uri content://settings/system --bind name:s:user_rotation --bind value:i:1
    sleep 3
    adb shell content insert --uri content://settings/system --bind name:s:user_rotation --bind value:i:0
    sleep 3
}

# Test different network conditions
test_network() {
    echo "Testing network conditions..."
    adb shell svc wifi disable
    sleep 5
    adb shell svc wifi enable
    sleep 10
}

# Extract package name
PACKAGE_NAME=$(aapt dump badging "$APK_FILE" | grep package | awk '{print $2}' | sed 's/name=//g' | tr -d "'")

echo "Testing compatibility for $PACKAGE_NAME"

# Install and launch
adb install -r "$APK_FILE"
adb shell monkey -p "$PACKAGE_NAME" -c android.intent.category.LAUNCHER 1
sleep 5

# Run tests
test_orientations
test_network

echo "Compatibility testing completed"
```

## Testing Different Scenarios

### 1. Edge Case Testing

```bash
# Test with low memory conditions
adb shell dumpsys meminfo  # Check available memory
# Force memory pressure and test app behavior

# Test with low storage
adb shell df /data  # Check storage
# Fill storage to near capacity and test

# Test with poor network conditions
# Use network throttling or airplane mode toggle
```

### 2. Regression Testing

```bash
# Create baseline performance metrics
baseline_test() {
    PACKAGE=$1
    adb shell dumpsys meminfo $PACKAGE > baseline_memory.txt
    adb shell dumpsys gfxinfo $PACKAGE > baseline_graphics.txt
}

# Compare with new version
compare_performance() {
    PACKAGE=$1
    adb shell dumpsys meminfo $PACKAGE > current_memory.txt
    adb shell dumpsys gfxinfo $PACKAGE > current_graphics.txt
    
    echo "Memory comparison:"
    diff baseline_memory.txt current_memory.txt
}
```

## Log Analysis

### 1. Parse Application Logs

```bash
# Extract app-specific logs
filter_app_logs() {
    PACKAGE=$1
    PID=$(adb shell ps | grep $PACKAGE | awk '{print $2}')
    adb logcat | grep "($PID)"
}

# Analyze error patterns
analyze_errors() {
    adb logcat | grep -E "(ERROR|FATAL|Exception)" | \
    awk '{print $6}' | sort | uniq -c | sort -nr
}
```

### 2. Generate Reports

```bash
# Generate testing report
generate_report() {
    PACKAGE=$1
    REPORT="test_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "APK Testing Report - $(date)" > $REPORT
    echo "Package: $PACKAGE" >> $REPORT
    echo "=========================" >> $REPORT
    
    echo "Memory Usage:" >> $REPORT
    adb shell dumpsys meminfo $PACKAGE >> $REPORT
    
    echo "Performance Metrics:" >> $REPORT
    adb shell dumpsys gfxinfo $PACKAGE >> $REPORT
    
    echo "Report saved to $REPORT"
}
```

## Best Practices

### 1. Testing Environment

- Use clean emulator instances for consistent testing
- Test on multiple Android versions and screen sizes
- Use realistic device configurations (RAM, storage, network)
- Keep emulator performance settings consistent

### 2. Test Data Management

- Use consistent test data sets
- Backup and restore app data between tests
- Clean app data before major test runs
- Document test scenarios and expected outcomes

### 3. Automation

- Automate repetitive testing tasks
- Use version control for test scripts
- Implement continuous integration for APK testing
- Create test suites for different testing phases

### 4. Documentation

- Keep detailed logs of testing sessions
- Document bugs with reproduction steps
- Maintain compatibility matrices
- Track performance benchmarks over time

---

**Made with ❤️ by [M-Hammad-Faisal](https://github.com/m-hammad-faisal)**

For more testing tips and automation scripts, visit the [project repository](https://github.com/m-hammad-faisal/apk-on-mac-guide).
