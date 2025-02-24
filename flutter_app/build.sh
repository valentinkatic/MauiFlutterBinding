echo "Check flutter"
flutter doctor
echo "Build ios frameworks"
flutter build ios-framework --no-profile
echo "Mixing debug build for simulator with release build"
rm -R build/ios/framework/Release/App.xcframework/ios-arm64_x86_64-simulator
cp -R build/ios/framework/Debug/App.xcframework/ios-arm64_x86_64-simulator build/ios/framework/Release/App.xcframework/ios-arm64_x86_64-simulator
echo "Build android aar"
flutter build aar --no-profile