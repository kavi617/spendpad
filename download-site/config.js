// Keep release details here. Replace releaseTag and apkAsset only after
// uploading a production APK to a GitHub Release.
export const siteConfig = {
  appName: 'SpendPad',
  version: '1.0.0',
  versionCode: 1,
  packageId: 'com.example.spendpad',
  minAndroid: 'Android 7.0 (API 24)',
  repository: 'https://github.com/kavi617/spendpad',
  releaseTag: 'v1.0.0',
  apkAsset: 'SpendPad-1.0.0.apk',
  releaseDate: '',
  apkSize: '',
};

export const releaseUrl = siteConfig.releaseTag
  ? `${siteConfig.repository}/releases/tag/${siteConfig.releaseTag}`
  : '';

export const apkUrl = siteConfig.releaseTag && siteConfig.apkAsset
  ? `${siteConfig.repository}/releases/download/${siteConfig.releaseTag}/${siteConfig.apkAsset}`
  : '';
