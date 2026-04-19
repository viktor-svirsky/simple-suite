APP_NAME = SimpleNotes
SCHEME = SimpleNotes
PROJECT = $(APP_NAME).xcodeproj
VERSION ?= $(shell cat VERSION 2>/dev/null || echo 0.0.0-dev)
DEST_TEST ?= platform=iOS Simulator,name=iPhone 16 Pro

.PHONY: generate test build ipa clean

generate:
	xcodegen generate

test: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination '$(DEST_TEST)' \
		test \
		CODE_SIGNING_ALLOWED=NO

build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination 'generic/platform=iOS Simulator' \
		-configuration Debug \
		build \
		CODE_SIGNING_ALLOWED=NO \
		MARKETING_VERSION=$(VERSION) \
		CURRENT_PROJECT_VERSION=$(VERSION)

# Ad-hoc signed IPA for AltStore distribution.
# CODE_SIGN_IDENTITY=- / CODE_SIGNING_ALLOWED=NO mirrors the ccusage widget pipeline.
ipa: generate
	rm -rf /tmp/$(APP_NAME).xcarchive /tmp/$(APP_NAME)IPA
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-configuration Release \
		-archivePath /tmp/$(APP_NAME).xcarchive \
		-destination 'generic/platform=iOS' \
		archive \
		CODE_SIGN_IDENTITY=- \
		CODE_SIGNING_ALLOWED=NO \
		MARKETING_VERSION=$(VERSION) \
		CURRENT_PROJECT_VERSION=$(VERSION)
	mkdir -p /tmp/$(APP_NAME)IPA/Payload
	cp -r /tmp/$(APP_NAME).xcarchive/Products/Applications/$(APP_NAME).app \
		/tmp/$(APP_NAME)IPA/Payload/
	cd /tmp/$(APP_NAME)IPA && zip -r /tmp/$(APP_NAME).ipa Payload/
	@echo "IPA built: /tmp/$(APP_NAME).ipa (v$(VERSION))"

clean:
	rm -rf $(PROJECT) /tmp/$(APP_NAME).xcarchive /tmp/$(APP_NAME)IPA /tmp/$(APP_NAME).ipa
