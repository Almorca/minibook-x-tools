# Tools

Hardware utilities for the Chuwi Minibook X.

## n150-ec-byte-bios

Read/write EC (Embedded Controller) bytes via debugfs to enable advanced BIOS settings.

⚠️ **Safety**: Writing to the EC is inherently risky. The script includes safety checks and a countdown before writes. Use `--dry-run` for testing. ⚠️

**Purpose**: Writes specific values to EC offset 0xF0 to unlock hidden BIOS options on the N150 platform.

**Requirements**:
- Root access
- `ec_sys` kernel module with write support enabled
- `CONFIG_ACPI_EC_DEBUGFS` enabled in kernel

**Usage**:
```bash
sudo ./n150-ec-byte-bios -h              # Show help
sudo ./n150-ec-byte-bios -m              # Display EC memory map
sudo ./n150-ec-byte-bios -r              # Read current value at 0xF0
sudo ./n150-ec-byte-bios -w -t 0xAA -i   # Write 0xAA to 0xF0 (requires -i confirmation)
```

## License

MIT License - See [LICENSE](LICENSE) file for details.
