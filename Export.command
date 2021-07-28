DIRPATH=$(dirname "$BASH_SOURCE")
PROJECTPATH=$DIRPATH/SalesmateChatSDK

cd "$PROJECTPATH"

echo "PWD"
echo $PWD

rm -r '../build'

xcodebuild clean \
-scheme SalesmateChatSDK \

xcodebuild archive \
-scheme SalesmateChatSDK \
-destination "generic/platform=iOS" \
-archivePath ../build/SalesmateChatSDK-iOS \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES

xcodebuild archive \
-scheme SalesmateChatSDK \
-destination "generic/platform=iOS Simulator" \
-archivePath ../build/SalesmateChatSDK-iOS-Simulator \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES

cd ../build

xcodebuild -create-xcframework \
-framework ./SalesmateChatSDK-iOS-Simulator.xcarchive/Products/Library/Frameworks/SalesmateChatSDK.framework \
-framework ./SalesmateChatSDK-iOS.xcarchive/Products/Library/Frameworks/SalesmateChatSDK.framework \
-output ./SalesmateChatSDK.xcframework