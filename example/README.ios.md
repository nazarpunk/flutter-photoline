```shell
echo "✅ build - ios ipa"
flutter build ipa
open build/ios/ipa/
```

```shell
echo "✅ podfile"
cd ios || exit
pwd
flutter clean
rm -Rf Pods
rm -Rf .symlinks
rm -Rf Flutter/Flutter.frameworkq
rm -Rf Flutter/Flutter.podspec
#rm -v Podfile
rm -v Podfile.lock
pod cache clean --all
pod deintegrate
pod setup
pod install
pod repo update
```

```shell
echo "✅ watchos clear"
rm -Rf ~/Library/Developer/Xcode/watchOS DeviceSupport
```

https://github.com/CocoaPods/CocoaPods/pull/12009
