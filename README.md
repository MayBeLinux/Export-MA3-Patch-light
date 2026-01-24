# MA3 PDF Exporter

> Export grandMA3 fixture patch data to professionally formatted PDF documents

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![grandMA3](https://img.shields.io/badge/grandMA3-Plugin-orange.svg)](https://www.malighting.com/grandma3/)

## Overview

**MA3 PDF Exporter** is a Lua plugin for grandMA3 lighting consoles that exports your fixture patch data to a clean, printable PDF document. Perfect for documentation, backup records, or sharing patch information with your team.

## Features

-  **PDF Export** — Generate professional PDF documents with fixture tables
-  **Statistics Report** — Optional statistics page with fixture counts and parameter info
-  **USB Auto-Detection** — Automatically detects connected USB drives
-  **Complete Patch Data** — Exports FID, IDType, CID, Name, Fixture Type, Mode, and Universe Address
-  **Grouping Support** — Preserves fixture grouping hierarchy in the export
-  **Grouping Filter** — Select which groupings to include/exclude per stage before exporting
-  **System Info** — Includes show name, date, hostname, and author in the document

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
3. **Select groupings to export:**
   - Each detected grouping is listed with its stage (when multiple stages exist)
   - Set each grouping to **Include** or **Exclude**
   - Ungrouped fixtures can also be included/excluded
4. **Configure export settings:**
   - Enter a document name
   - Enter the programmer name
   - Select the target USB drive
   - Choose whether to include the statistics page
5. **Click OK** to generate the PDF
6. **Find your PDF** in the `MA3_EXPORT_PDF` folder on your USB drive

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

## Changelog

### v2.1.0

#### Bug Fixes

| Bug | Cause | Fix |
|-----|-------|-----|
| **Blank PDF pages** — 13 pages exported with grid lines but no text content | PDF page objects had no `/Resources` dictionary defining fonts. PDF viewers could draw lines but couldn't render text without knowing what `/F1` and `/F2` fonts are. | Added `/Resources` block with Helvetica (F1) and Helvetica-Bold (F2) Type1 font declarations to all page objects. |
| **USB drive selection ignored** — Output always went to the first USB drive regardless of user selection | The code hardcoded `drives[2].path` instead of reading the user's selected drive from the dialog result. | Now reads `settings.selectors["USB Drive"]` and maps it to the correct path via `USBManager.paths`. |
| **Statistics page blank** — Same blank rendering as main PDF, plus potential parsing failures | Missing font resources (same as main PDF) and hardcoded fake xref byte offsets (`10, 50, 100, 200`) that didn't match actual object positions. | Added font resources and implemented proper byte offset tracking for the xref table. |

#### New Features

- **Grouping Selection Filter** — A new dialog appears before the export settings, listing all detected groupings organized by stage. Each grouping (and ungrouped fixtures) can be set to Include or Exclude. Only selected data is exported to PDF.
  - When a single stage exists, groupings are listed without a prefix
  - When multiple stages exist, each grouping is prefixed with its stage name (e.g., `Stage 1 | Moving Lights`)
  - If all items are excluded, an error is shown instead of generating a blank PDF

- **Name Column Truncation** — Fixture names longer than 25 characters are automatically truncated with `...` to prevent text overflow into adjacent columns.

- **UI Theme System** — All dialogs now share a centralized theme configuration (`Config.UI_THEME`), making the interface consistent and easy to customize.

## Author

**LumiArt-Studio**

- GitHub: [@MayBeLinux](https://github.com/MayBeLinux)

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

---

Made with ❤️ for the lighting community
