# Firefox Add-on Manager

A lightweight Firefox WebExtension to help inspect and manage installed add-ons from the browser (extension UI, developer tooling, and utilities). Designed to be simple, extensible, and easy to run locally.

## About
This repository contains the source for a Firefox WebExtension that provides a focused interface and tooling to inspect, enable/disable, and manage installed browser add-ons. The project is implemented with JavaScript, HTML, CSS and includes shell helper scripts where appropriate.

## Features
- Browser-side UI for viewing installed extensions and their metadata
- Enable/disable extensions without leaving the tool
- Quick access to extension folders and developer information
- Designed as a WebExtension compatible with Firefox
- Lightweight and easily extensible

## Getting started
To try this extension locally:

1. Open Firefox and go to about:debugging (or the equivalent Developer Tools > Debug Add-ons page).
2. Choose "This Firefox" (or "Load Temporary Add-on").
3. Select the extension's manifest file (manifest.json) from the repository root or the build output.
4. The extension will load temporarily and you can interact with it from the toolbar or the extension list.

Packaging and distribution: when you're ready to distribute, package the extension into an XPI. Common approaches include using Mozilla's web-ext tooling or zipping the extension folder and signing/uploading through addons.mozilla.org (AMO). (This README intentionally omits step-by-step publishing instructions.)

## Usage
- Open the extension from the toolbar or via the Extensions page.
- Browse the list of installed add-ons and inspect details.
- Use the provided controls to enable/disable or inspect extension directories and metadata.
- For debugging, use the built-in developer tools or open the extension's background/action pages.

## Contributing
Contributions are welcome.
- Open an issue to discuss major changes or report bugs.
- Fork the repository, make changes on a branch, and open a pull request.
- Keep changes focused and include tests or manual verification steps where applicable.
- Follow common web extension security practices: avoid exposing secrets, validate inputs, and limit permissions in manifest.json.
