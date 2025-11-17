# Chuwi Minibook X Tools

Linux hardware support for the **Chuwi Minibook X** convertible laptop. Provides tablet mode detection through accelerometer data and integrates with desktop environments.

The cmxd and cmxsd may be useful for other platforms that use two accelerometers in order
to detect tablet mode configuration. The cmx module is only required as the CHUWI Minibook X
platform ACPI does not bring up both accelerometers. If you find that these daemons work for you, please email or message me with your platform information.

## System Architecture

- **[cmx-kernel-patch/](cmx-kernel-patch/)** - Kernel patches for accelerometer device support
- **[cmx/](cmx/)** - Kernel module for tablet mode detection and input events
- **[cmxd/](cmxd/)** - System daemon for accelerometer processing
- **[cmxsd/](cmxsd/)** - User session daemon for desktop integration
- **[tools/](tools/)** - Optional utilities for EC configuration

## Installation & Setup

Follow these steps in order:

### 1. Apply Kernel Patch

Rebuild your kernel after applying the patch in `./cmx-kernel-patch/`. This patch:
- Disables automatic ACPI loading for MXC4005 accelerometer devices
- Enables serial-multi-instantiate support for multiple MXC4005 instances
- Selects serial-multi-instantiate and mxc4005 modules. 

```bash
cd cmx-kernel-patch/
# Follow instructions to apply patch to your kernel source
# Reboot with patched kernel
```

### 2. Configure Kernel

Enable the following options in your kernel configuration:
- `CONFIG_CMX` - Chuwi Minibook X platform driver
  - This will automatically select `CONFIG_MXC4005` and `CONFIG_SERIAL_MULTI_INSTANTIATE`

**Note**: Module build `<M>` has been tested. Compiled-in `<*>` has not been tested.

NOTE: after rebuilding the kernel with the patch, you can do steps 3, 4, and 5 manually, or you can run the normal `make`, `make install` dance from the top-level directory.

### 3. Build & Install Kernel Module

See [cmx/README.md](cmx/README.md) for details.

```bash
cd cmx/
make
sudo make modules_install
sudo modprobe cmx
```

### 4. Build & Install System Daemon

See [cmxd/README.md](cmxd/README.md) for details.

**cmxd** must be started at the system level (by root).

```bash
cd cmxd/
make
sudo make install
sudo systemctl enable --now cmxd
```

### 5. Build & Install Session Daemon

See [cmxsd/README.md](cmxsd/README.md) for details.

**cmxsd** runs per user session. Customize the support scripts for your desktop environment.

```bash
cd cmxsd/
make
sudo make install
make install-user # optional, but scripts customized for your environment are required
systemctl --user enable --now cmxsd
```

### 6. Optional: EC Configuration Tools

See [tools/README.md](tools/README.md) for details.

The support scripts in `./tools/` are optional and may improve performance and enable advanced BIOS settings on the N150 platform device.

## How It Works

```
Hardware                  Kernel                    Userspace
--------                  ------                    ---------
IIO Devices    →    cmx kernel module    ⇄    cmxd (system daemon)
(accelerometers)    (SW_TABLET_MODE events)   (calculates hinge angles)
                                                      ↓
                                              cmxsd (session daemon)
                                              (desktop integration)
```

1. IIO accelerometer devices provide raw sensor data
2. **cmx** kernel module creates input device and sysfs interface
3. **cmxd** reads accelerometer data, calculates hinge angles, updates kernel module
4. **cmx** generates `SW_TABLET_MODE` input events
5. **cmxsd** responds to events and executes desktop environment actions

## License

- **cmx/**, **cmxd/**, **cmxsd/**: GPL-2.0-or-later (see LICENSE files in each directory)
- **tools/**: MIT License (see tools/LICENSE)
- Root directory: Dual-licensed (LICENSE-1 for MIT, LICENSE-2 for GPL-2.0)

## Contributing

See individual component READMEs for development information and testing procedures.
