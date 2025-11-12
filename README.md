# Addon Manager for Firefox

Manage every Firefox extension from a single toolbar button. Addon Manager keeps the beloved Custom Chrome workflow but adapts it for Firefox-exclusive deployments.

## Highlights
- Toolbar context menu adds `Disable all active extensions` / `Restore N extensions`, remembering exactly which add-ons you toggled.
- Groups let you store curated sets of extensions (e.g., “Web Dev”, “Meetings”) and flip them on/off without opening `about:addons`.
- Quick links open an extension’s options page, AMO listing, or sharing URL so teammates can install the same tools.

## Self-hosted / Enterprise Workflow
Firefox only lets an extension enable/disable other add-ons when it is force-installed via enterprise policy. To side-load and keep Addon Manager updated:

1. **Clone & build**
   ```bash
   git clone https://github.com/luascfl/firefox-addon-manager.git
   cd firefox-addon-manager
   zip -r addon-manager-firefox.xpi .
   ```
2. **Host the XPI** somewhere HTTPS-accessible (GitHub Pages, internal CDN, etc.).
3. **Configure the policy** using Firefox’s `ExtensionSettings`. The sample `install-addon-policy.sh` demonstrates how to point the policy to your hosted `.xpi`.
4. **Deploy the policy** via GPO, MDM, or `policies.json`. Firefox will read the `browser_specific_settings.gecko.update_url`, which now points to `https://raw.githubusercontent.com/luascfl/firefox-addon-manager/main/updates.json`, and will follow the JSON entry to download the latest `.xpi`. Update both `updates.json` and the packaged file whenever you ship a new version.

## Credits
Addon Manager is built on the original Custom Chrome – Extension Manager by **@cderm** and **@ciaranmag**. Huge thanks for the design inspiration and feature foundation.
