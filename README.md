# MA3 PDF Exporter

> Export grandMA3 fixture patch data to professionally formatted PDF documents

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![grandMA3](https://img.shields.io/badge/grandMA3-Plugin-orange.svg)](https://www.malighting.com/grandma3/)

## Overview

**MA3 PDF Exporter** is a Lua plugin for grandMA3 lighting consoles that exports your fixture patch data to a clean, printable PDF document. Perfect for documentation, backup records, or sharing patch information with your team.

## Features

- 📄 **PDF Export** — Generate professional PDF documents with fixture tables
- 📊 **Statistics Report** — Optional statistics page with fixture counts and parameter info
- 🔌 **USB Auto-Detection** — Automatically detects connected USB drives
- 📋 **Complete Patch Data** — Exports FID, IDType, CID, Name, Fixture Type, Mode, and Universe Address
- 📁 **Grouping Support** — Preserves fixture grouping hierarchy in the export
- 🖥️ **System Info** — Includes show name, date, hostname, and author in the document

## Installation

1. **Download** the `MA3 PDF Exporter V2.lua` file
2. **Copy** the file to your grandMA3 plugins folder:
   - Windows: `C:\ProgramData\MALightingTechnology\gma3_x.x.x\shared\resource\lib_plugins\`
   - Console: `/user/plugins/`
3. **Import** the plugin into a Plugin Pool in grandMA3
4. **Run** the plugin from the console

## Usage

1. **Connect a USB drive** to your console or computer
2. **Execute the plugin** from your Plugin Pool
3. **Configure export settings:**
   - Enter a document name
   - Enter the author/programmer name
   - Select the target USB drive
   - Choose whether to include the statistics page
4. **Click OK** to generate the PDF
5. **Find your PDF** in the `MA3_EXPORT_PDF` folder on your USB drive

## Exported Data

### Fixture Table

| Column | Description |
|--------|-------------|
| FID | Fixture ID |
| IDType | ID Type |
| CID | Channel ID |
| Name | Fixture Name |
| Fixture Type / Mode | Type and DMX mode |
| U.Addrs | Universe and Address |

### Statistics Report (Optional)

- Total fixture count
- Grouping count
- Stage count
- Parameter count
- MA3 device parameter reference table

## Requirements

- **grandMA3** software or console (latest version recommended)
- **USB storage device** for file export

## File Structure

```
USB Drive/
└── MA3_EXPORT_PDF/
    ├── YourDocumentName.pdf
    └── Statistics_Report.pdf (optional)
```

## Author

**LumiArt-Studio**

- GitHub: [@MayBeLinux](https://github.com/MayBeLinux)

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

---

Made with ❤️ for the lighting community
