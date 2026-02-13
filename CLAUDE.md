# CLAUDE.md — Pocket Full of Sunshine (PFOS)

## Project Overview

PFOS is a browser-based, mobile-first QR code and barcode utility with a hacker/terminal theme. It generates, increments, and clones QR codes and 1D barcodes entirely client-side — no backend, no build step, no package manager. Version 0.0.7.

Repository: https://github.com/psems/pfos

## Architecture

This is a **static HTML/CSS/JS application** with a flat file structure:

```
pfos/
├── index.html            # Entire application: markup + all JS logic (~670 lines)
├── style.css             # All styles, hacker/terminal theme (~186 lines)
├── test-qr.html          # QR code round-trip validation tests (open in browser)
├── service-worker.js     # PWA offline caching (~34 lines)
├── manifest.json         # PWA manifest
├── qrcode.min.js         # QR code generation library (self-hosted, MIT)
├── html5-qrcode.min.js   # QR/barcode scanner library (self-hosted, MIT)
├── apple-touch-icon.png  # iOS icon
├── icon-192.png          # PWA icon 192x192
├── icon-512.png          # PWA icon 512x512
└── README.md             # User-facing documentation
```

All application logic lives in `index.html` inside two `<script>` tags. There are no separate JS modules or source files.

## Key Technical Facts

- **No build system.** No `package.json`, no bundler, no transpiler. Open `index.html` in a browser to run.
- **Browser-based tests.** `test-qr.html` provides QR round-trip, barcode generation, and input validation tests. Open in a browser to run.
- **No linter/formatter config.** No `.eslintrc`, `.prettierrc`, or similar.
- **No CI/CD.** No GitHub Actions or other pipeline configuration.
- **Vanilla JavaScript (ES6+).** No frameworks, no TypeScript.
- **Single external CDN dependency:** JsBarcode loaded from `cdn.jsdelivr.net` in `index.html:71`.
- **External API:** OpenStreetMap Nominatim for reverse geocoding (optional, used in clone/scan mode).

## Code Organization in index.html

All JavaScript is in `index.html` between lines 138–671. Key functions:

| Function | Purpose |
|---|---|
| `clearQR()` | Clears QR/barcode display areas |
| `logEntry()` | Appends timestamped entries to the log textarea |
| `generateQRCode(text, prefix)` | Core generation function — handles all formats, validation, 1D/2D dispatch |
| `generateTextQR()` | Text mode entry point |
| `startIncrementQR()` | Validates and starts increment mode |
| `generateIncrementQR()` | Generates QR for current increment value |
| `markCurrent()` | Marks current entry in log |
| `downloadLog()` | Exports log as `.txt` file download |
| `generateCloneQR()` | Clone mode entry point |
| `incrementAndGenerateQR()` | Increments counter and regenerates |
| `updateGenerateButtonText()` | Updates button labels when format changes |
| `checkPermissions()` | Passive permission check via `navigator.permissions.query()` (no browser prompts) |
| `DOMContentLoaded` handler | App initialization, default state setup |
| `startCamera()` | Initializes camera scanner with Html5Qrcode |
| `stopCamera()` | Stops camera and cleans up scanner |
| File upload handler | Processes QR images uploaded via file input |

## Application Modes

1. **Clone** (default) — Scan a QR code via camera or file upload, edit content, regenerate. Logs GPS coordinates and address when scanning.
2. **Increment** — Enter a start number and step, generate sequential QR codes.
3. **Text** — Free-form text to QR/barcode.

## Supported Barcode Formats

- **2D:** QR Code, Aztec, Data Matrix, PDF 417 (generated via `qrcode.min.js`)
- **1D:** Code 128, Code 93, Code 39, Codabar, EAN-13, EAN-8, ITF, UPC-A, UPC-E (generated via JsBarcode)

## Development Workflow

### Running the app
Open `index.html` directly in a browser, or serve with any static file server:
```sh
python3 -m http.server 8000
# Then open http://localhost:8000
```
HTTPS is required for camera and geolocation features to work in production.

### Making changes
- **UI/markup:** Edit `index.html` (HTML structure is lines 1–129)
- **Application logic:** Edit `index.html` (JavaScript is lines 138–671)
- **Styles:** Edit `style.css`
- **PWA caching:** Edit `service-worker.js` — update `CACHE_NAME` when cached assets change
- **Libraries:** `qrcode.min.js` and `html5-qrcode.min.js` are vendored minified files in the repo root. Do not edit them directly.

### Deploying
Copy all files to any static hosting (GitHub Pages, Netlify, S3, etc.). No build step needed.

## Conventions and Patterns

- **Color scheme:** `#00ff00` (green) on `#000000` (black), accent `#00ff88`. All UI must maintain this terminal/hacker aesthetic.
- **Font:** Monospace stack — `'Fira Mono', 'Consolas', 'Courier New', monospace`.
- **Mobile-first:** All inputs capped at `max-width: 320px`. Responsive breakpoint at 480px.
- **Accessibility:** All interactive elements require `aria-label` attributes. Keyboard navigation must be preserved.
- **Privacy:** All data processing is client-side. The only external network call is the optional Nominatim reverse geocoding API. No analytics, no tracking.
- **Logging:** All significant actions are logged to the `#log` textarea via `logEntry()` with 24-hour timestamps.
- **Input validation:** `generateQRCode()` validates format-specific requirements (numeric-only for UPC/EAN, length constraints, max 4000 chars).
- **Error handling:** Try/catch around QR generation and camera operations. Errors logged to console and shown via `alert()`.

### Running tests
Open `test-qr.html` in a browser and click "Run All Tests". Tests cover:
- QR code round-trip (generate then scan back) for text, URLs, unicode, special characters, etc.
- 1D barcode generation (Code128, Code39, EAN-13, EAN-8, UPC-A, ITF, Codabar, Code93)
- Input validation (length checks, numeric-only for UPC/EAN, max character limits)

## Common Pitfalls

- The `qr` variable is a global that holds the current QRCode instance. It gets overwritten on each generation.
- The service worker cache version (`pfos-cache-v1`) must be manually bumped when assets change, or users may see stale content.
- JsBarcode is the only CDN dependency — if offline support for 1D barcodes is needed, it must be vendored like the other libraries.
- Permissions are checked passively via `navigator.permissions.query()`. Camera is only activated when the user clicks "Scan QR Code". Location is only requested after a successful scan.

## Dependencies

| Library | Source | Version | Purpose |
|---|---|---|---|
| [qrcodejs](https://github.com/davidshimjs/qrcodejs) | Vendored (`qrcode.min.js`) | — | QR code generation |
| [html5-qrcode](https://github.com/mebjas/html5-qrcode) | Vendored (`html5-qrcode.min.js`) | — | QR/barcode scanning + file upload |
| [JsBarcode](https://github.com/lindell/JsBarcode) | CDN (`jsdelivr`) | 3.11.5 | 1D barcode generation |

## Browser APIs Used

- `navigator.mediaDevices.getUserMedia()` — Camera access for scanning
- `navigator.geolocation` — GPS coordinates during scan
- `navigator.permissions` — Permission state monitoring
- Service Worker API — PWA offline support
- `URL.createObjectURL()` — Log file download

## License

MIT
