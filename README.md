# flutter-photoline

```shell

echo "✅ podfile"
cd example/ios || exit
pwd
flutter clean
rm -Rf Pods
rm -Rf .symlinks
rm -Rf Flutter/Flutter.framework
rm -Rf Flutter/Flutter.podspec
#rm -v Podfile
rm -v Podfile.lock
pod cache clean --all
pod deintegrate
pod setup
pod install
pod repo update
```
