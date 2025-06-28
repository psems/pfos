# Pocket Full of Sunshine

A visually striking, mobile-first, hacker-themed QR code utility for the browser. Generate, increment, and clone QR codes with ease—no backend required.

## Features

- **Three Modes:**
  - **Text:** Generate a QR code from any text.
  - **Increment:** Generate a series of QR codes by incrementing a number.
  - **Clone QR:** Scan a QR code with your device camera or edit the content directly.
- **Mobile-First:** Optimized for iOS Safari, Android Chrome, and Firefox.
- **Accessible:** All controls are keyboard and screen reader accessible.
- **Logging:** Bash-style log with timestamps, marking, and download support.
- **No Backend:** All processing is local; no data leaves your device.
- **Self-Hosted Libraries:** For reliability and offline use.

## Usage

1. **Open the app in your browser** (preferably on a mobile device).
2. **Select a mode** from the dropdown:
   - **Clone QR:** Scan a QR code or edit the content, then generate a new QR code.
   - **Increment:** Enter a start number and step, then generate and increment QR codes.
   - **Text:** Enter any text and generate a QR code.
3. **Scan, edit, or generate** as needed. Use the log to track your QR code history.
4. **Mark** important QR codes or **download** your log for record-keeping.

## Accessibility & Security

- All interactive elements have ARIA labels and are keyboard accessible.
- Camera access requires HTTPS and user permission.
- No user data is sent to a server; all processing is local.
- Libraries are self-hosted for reliability and privacy.

## Development

- **HTML/CSS/JS only.** No build step required.
- All styles are in `style.css`.
- All logic is in `index.html` (script tag at the bottom).
- Libraries (`qrcode.min.js`, `html5-qrcode.min.js`) must be present in the project root.

## Customization

- To change the default QR code, edit the `value` attribute of the text input in `index.html`.
- To adjust the theme, edit `style.css`.

## Attribution

This project uses the following open source libraries:

- [qrcodejs](https://github.com/davidshimjs/qrcodejs) (MIT License)
- [html5-qrcode](https://github.com/mebjas/html5-qrcode) (MIT License)

See their repositories for more information and full license texts.

## License

MIT. See [LICENSE](LICENSE) for details.

---

**Pocket Full of Sunshine** — by GrandMasterFunk
