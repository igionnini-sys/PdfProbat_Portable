# ProbatPdfCraft portable for Windows

Extract the whole ZIP into a folder you can write to, then open `pdfcraft.exe`.
No installer or administrator privileges are needed. Keep `portable.txt` beside
the executable: settings, logs, recovery files and newly created digital IDs
are stored in `PdfCraftData` in that same folder. Copy the whole folder to move
the app and its settings to another PC or a USB drive.

If that folder cannot be written, ProbatPdfCraft reports it and uses the normal user
folders instead. Removing `portable.txt` also selects the normal user folders.

`pdfcraft-cli.exe` provides command-line tools. OCR models and their notices are
in `models`. Keep the supplied licence and notice files with the application.

**Fork Declaration:**
This software is **ProbatPdfCraft**, a corporate offline fork of **PdfCraft v0.18.1** (<https://github.com/storytold/pdfcraft>).
It is configured for complete offline and air-gapped corporate operation (zero telemetry, zero external network calls).
The software is licensed under MIT OR Apache-2.0; bundled dependencies and resources retain their own licences and attribution.

## Rebuilding from these sources

Use a Developer PowerShell with Rust 1.95 or later, the MSVC C++ tools and a
Windows SDK. Set `CRAFT_I18N_DIR` to the craft-i18n checkout pinned in
`craft-i18n.rev` and `CRAFT_FONTS_DIR` to the craft-fonts build input when
translations and the additional fonts are required. Then, from the repo root:

```powershell
$env:PDFCRAFT_BUILD_LABEL = 'portable-csv-fix'
./packaging/windows/package.ps1 -Arch x64 -PortableOnly
```

The ZIP is written to `dist/release`. WiX is not required with `-PortableOnly`.
Without signing credentials the local executables are unsigned.
