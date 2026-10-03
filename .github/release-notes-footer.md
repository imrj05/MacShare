## Installing this release

**Mac Share is not notarized by Apple**, so macOS will block it the first time you open it. That's expected — here is how to allow it:

1. Download the `MacShare-x.y.z.dmg` attached below, open it, and drag **Mac Share** onto the **Applications** shortcut.
2. Eject the DMG, then open **Mac Share** from your Applications folder. macOS blocks it once — click **Done**.
3. Open **System Settings → Privacy & Security**, scroll down to **Security**, and click **Open Anyway** next to the message about Mac Share. Authenticate, then click **Open**.

On macOS 14 (Sonoma) and earlier, Control-click the app in Finder and choose **Open → Open** instead of step 3 — macOS 15 removed that shortcut.

If macOS says **"Mac Share is damaged and can't be opened"**, that's the download quarantine flag rather than a broken build. Clear it in Terminal, then open the app again:

```bash
xattr -dr com.apple.quarantine "/Applications/Mac Share.app"
```

Verify your download against the attached `MacShare-x.y.z.dmg.sha256` file. Full instructions: [README → Installation](https://github.com/imrj05/MacShare#installation).
