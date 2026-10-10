# SpendPad showcase and Android downloads

This is a static, framework-free showcase for SpendPad. It uses the actual Flutter app icon and the five checked-in release screenshots. The visual system follows the app's Material 3 seed green (`#1E9E5A`), pale light scaffold (`#F6F8F5`), and rounded surfaces.

## Preview locally

From the repository root, run:

```sh
cd download-site
python3 -m http.server 8000
```

Open `http://localhost:8000`. A local HTTP server is needed because the site uses a JavaScript ES module.

## Site contents

- `index.html`: sections and accessible controls
- `styles.css`: responsive theme and reduced-motion behavior
- `script.js`: gallery, lightbox, feature explorer, navigation, and release links
- `config.js`: app and current release metadata
- `assets/`: app icon and screenshots copied from `release-artifacts/`

## Release details

The app is currently `1.0.0+1`, Android package `com.example.spendpad`. The existing release APK reports minimum SDK 24 (Android 7.0); this is the compatibility shown on the site. The site is configured for `v1.0.0` and `SpendPad-1.0.0.apk`; those GitHub URLs will work after the release and asset have been uploaded. After publishing, set `releaseDate` and `apkSize` in `config.js` if desired. The asset URL is assembled from the actual repository, tag, and filename.

Do not check signing material into the site. The Android project expects a private `android/key.properties` and JKS file; keep both private. Confirm the signing key is the intended production key before releasing.

## Build and verify a release APK

From the `spendpad/` project directory:

```sh
flutter pub get
flutter build apk --release
```

Expected output: `build/app/outputs/flutter-apk/app-release.apk`. Verify the version and package with Android SDK `apkanalyzer` or `aapt`, and verify the signer with `apksigner verify --print-certs`. Never publish a debug APK. If the release task reports missing signing properties, configure your private `android/key.properties` locally; do not put its values in Git.

## Publish a new version

1. Update `version` in `pubspec.yaml` (for example `1.0.1+2`); increment the build number.
2. Build the release APK and verify its package, version, signing certificate, and size.
3. Set `RELEASE_TAG=v1.0.1` and `APK=build/app/outputs/flutter-apk/app-release.apk` below, then create a release. This uses the current repository remote and refuses an existing tag:

   ```sh
   RELEASE_TAG=v1.0.1
   APK=build/app/outputs/flutter-apk/app-release.apk
   gh release create "$RELEASE_TAG" "$APK#SpendPad-1.0.1.apk" \
     --repo kavi617/spendpad \
     --title "SpendPad $RELEASE_TAG" \
     --notes "SpendPad Android release $RELEASE_TAG. See the project README for verified features and compatibility."
   ```

4. Confirm the release and asset on GitHub. Update `version`, `releaseTag`, `apkAsset` (`SpendPad-1.0.1.apk` in this example), and verified size/date in `config.js`.
5. Preview the site and confirm the APK button targets the asset URL and release notes link targets the release.
6. Commit and push the site and app version changes to `main`.

Previous releases remain available. Do not reuse a release tag or replace an existing asset; increment the version and tag.

## GitHub Pages

The repository workflow at `.github/workflows/static.yml` publishes only `download-site/` to GitHub Pages when it changes on `main`, and can also be run manually from the **Actions** tab. In **Settings → Pages**, select **GitHub Actions** as the source. The site uses relative paths and works under the repository subpath. The expected URL is `https://kavi617.github.io/spendpad/` after a successful deployment; the first deployment can take several minutes.

To enable it, open **Settings → Pages** and set the build/deployment source to **GitHub Actions**. Push the workflow and site files to `main`; then check **Actions → Publish SpendPad showcase** for a successful deployment and open the published URL. Repository Pages settings and deployment still require an authorized GitHub account.
