xcode_clean:
	rm -rf ~/Library/Developer/Xcode/DerivedData/*

release:
	bundler exec fastlane release

set_version:
	bundler exec fastlane set_version version:$(v)
