# CMX - Chuwi Minibook X Kernel Module

Platform driver for tablet mode detection on the Chuwi Minibook X convertible laptop. Provides `SW_TABLET_MODE` input events and sysfs interface for communication with the userspace daemon (cmxd).

## Prerequisites

This module requires kernel patches from `../cmx-kernel-patch/` to be applied:
- Disables automatic ACPI loading for MXC4005 accelerometer devices (HID `MDA6655`)
- Enables serial-multi-instantiate driver support for multiple MXC4005 instances

Without these patches, the accelerometer devices will not be properly initialized.

## Building

The module build hooks into the kernel build, so you'll need to have taken care of
that first.

```bash
make           # Build module
make modules_install
```

## Sysfs Interface

All sysfs attributes are located at `/sys/devices/platform/cmx/`:

### Data Input/Output (rw)
- **`base_vec`** - Base accelerometer vector: `"x y z"` (micro-g units)
- **`lid_vec`** - Lid accelerometer vector: `"x y z"` (micro-g units)
- **`mode`** - Current mode: `laptop`, `flat`, `tent`, `tablet`
- **`orientation`** - Current orientation: `normal`, `right-up`, `left-up`, `bottom-up`

### Device Information (r)
- **`iio_base_device`** - IIO device name for base accelerometer (typically `iio:device1`)
- **`iio_lid_device`** - IIO device name for lid accelerometer (typically `iio:device0`)

### Event Control (rw)
- **`enable`** - Enable/disable tablet mode events
  - Accepts: `true`/`false`, `1`/`0`, `yes`/`no`, `y`/`n`, `t`/`f` (case-insensitive)
  - Returns: `true` or `false`

## Usage Examples

```bash
# Check current state
cat /sys/devices/platform/cmx/mode
cat /sys/devices/platform/cmx/orientation

# Check assigned IIO devices
cat /sys/devices/platform/cmx/iio_base_device
cat /sys/devices/platform/cmx/iio_lid_device

# Disable tablet mode events
echo "false" > /sys/devices/platform/cmx/enable

# Write accelerometer data (typically done by cmxd)
echo "0 0 9800000" > /sys/devices/platform/cmx/base_vec
echo "0 0 9800000" > /sys/devices/platform/cmx/lid_vec

# Write mode/orientation (typically done by cmxd)
echo "laptop" > /sys/devices/platform/cmx/mode
echo "normal" > /sys/devices/platform/cmx/orientation
```

## Input Events

When enabled, the module generates `SW_TABLET_MODE` input events:
- **0** = Laptop mode
- **1** = Tablet mode (tablet/tent modes)

Monitor with:
```bash
evtest /dev/input/eventX  # Find correct device with SW_TABLET_MODE capability
```

## Communication Flow

```
IIO Accelerometers → cmxd daemon → sysfs (this module) → Input Events
```

The cmxd userspace daemon:
1. Reads raw accelerometer data from IIO devices
2. Calculates hinge angles and device orientation
3. Writes processed data to this module's sysfs interface
4. Module generates input events for desktop integration

## Module Parameters

None. The module automatically discovers IIO accelerometer devices via DMI matching and ACPI enumeration.

## Dependencies

- `serial_multi_instantiate` (soft dependency, loads automatically)
- MXC4005 accelerometer driver (IIO subsystem)
- Kernel patches from `../cmx-kernel-patch/`
