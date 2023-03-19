xcode_clean:
	rm -rf ~/Library/Developer/Xcode/DerivedData/*

beta:
	bundler exec fastlane beta

set_version:
	bundler exec fastlane set_version version:$(v)
