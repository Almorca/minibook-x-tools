# cmxd - Chuwi Minibook X Daemon

Userspace daemon for tablet mode detection on the Chuwi Minibook X convertible laptop. Reads accelerometer data, calculates hinge angles and device orientation, and communicates with the cmx kernel module.

## Features

- **Event-driven IIO sampling** - Low CPU usage, high responsiveness
- **Automatic device detection** - Reads assignments from kernel module
- **Auto-configuring** - Sets accelerometers to least sensitive scale for stability
- **Dead zone handling** - 0-45° maintains current mode to prevent jitter
- **Multiple output channels** - Sysfs, Unix socket, DBus (iio-sensor-proxy compatible)

## Building

```bash
make           # Build daemon and shared library
sudo make install  # Install to /usr/sbin and /usr/lib
```

## Usage

```bash
# Run with auto-detected devices
cmxd

# Verbose mode for debugging
cmxd -v

# Custom buffer timeout
cmxd -t 50

# Disable DBus integration
cmxd --no-dbus
```

## Configuration

Edit `/etc/default/cmxd`:

```bash
# Buffer timeout in milliseconds (1-10000)
BUFFER_TIMEOUT_MS=100

# Custom kernel module path (rarely needed)
#SYSFS_DIR=/sys/devices/platform/cmx
```

## Architecture

```
IIO Accelerometers → cmxd (this daemon) → cmx kernel module → Input Events
                         ↓
                    Unix Socket + DBus → Desktop Integration
```

### Mode Detection

- **laptop** (45° - 160°) - Traditional laptop position
- **flat** (160° - 240°) - Device lying flat
- **tent** (240° - 345°) - Tent mode (lid folded back)
- **tablet** (345° - 360°) - Fully folded for tablet use
- **Dead zone** (0° - 45°) - Maintains current mode

### Orientation Detection

- **normal** - Standard landscape
- **right-up** - 90° clockwise (portrait)
- **left-up** - 90° counter-clockwise
- **bottom-up** - 180° rotation

## Communication Channels

### Sysfs (to kernel module)
Writes to `/sys/devices/platform/cmx/`:
- `base_vec` / `lid_vec` - Accelerometer vectors (micro-g)
- `mode` - Current device mode
- `orientation` - Current screen orientation

### Unix Socket (for clients)
JSON events on `/run/cmxd/events.sock`:
```json
{"timestamp": 1234567890.123, "type": "mode", "value": "tablet"}
{"timestamp": 1234567890.456, "type": "orientation", "value": "normal"}
```

### DBus (for desktop)
iio-sensor-proxy compatible signals on system bus (optional, enabled by default).

## Dependencies

- **cmx kernel module** - Platform driver (required)
- **IIO subsystem** - Two MXC4005 accelerometers
- **DBus** - For desktop integration (optional)

## Systemd Integration

```bash
# Enable and start service
sudo systemctl enable --now cmxd.service

# Check status
sudo systemctl status cmxd

# View logs
sudo journalctl -u cmxd -f
```

## Command Line Options

```
-t, --timeout-ms MS    Buffer timeout in milliseconds (default: 100)
-s, --sysfs-path PATH  Kernel module sysfs path
-v, --verbose          Enable verbose logging
    --no-dbus          Disable DBus event publishing
-h, --help             Show help
-V, --version          Show version
```

## Protocol Library

Includes `libcmx.so` shared library with protocol definitions for client applications. Header installed to `/usr/include/libcmx/cmxd-protocol.h`.

## Manual Page

See `man cmxd` for detailed documentation.
