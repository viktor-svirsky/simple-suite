APP_NAME = SimpleNotes
SCHEME = SimpleNotes
PROJECT = $(APP_NAME).xcodeproj
VERSION ?= $(shell cat VERSION 2>/dev/null || echo 0.0.0-dev)
DEST_TEST ?= platform=iOS Simulator,name=iPhone 16 Pro
SENTRY_DSN ?=
CONFIG ?= Release
# ReleaseCloudKit ships as a separate artifact so the AltStore (Release) IPA
# stays free of the iCloud entitlement.
IPA_NAME ?= $(if $(filter ReleaseCloudKit,$(CONFIG)),$(APP_NAME)CloudKit,$(APP_NAME))

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
	rm -rf /tmp/$(IPA_NAME).xcarchive /tmp/$(IPA_NAME)IPA /tmp/$(IPA_NAME).ipa
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-configuration $(CONFIG) \
		-archivePath /tmp/$(IPA_NAME).xcarchive \
		-destination 'generic/platform=iOS' \
		archive \
		CODE_SIGN_IDENTITY=- \
		CODE_SIGNING_ALLOWED=NO \
		MARKETING_VERSION=$(VERSION) \
		CURRENT_PROJECT_VERSION=$(VERSION) \
		SENTRY_DSN="$(SENTRY_DSN)"
	mkdir -p /tmp/$(IPA_NAME)IPA/Payload
	cp -r /tmp/$(IPA_NAME).xcarchive/Products/Applications/$(APP_NAME).app \
		/tmp/$(IPA_NAME)IPA/Payload/
	cd /tmp/$(IPA_NAME)IPA && zip -r /tmp/$(IPA_NAME).ipa Payload/
	@echo "IPA built: /tmp/$(IPA_NAME).ipa (v$(VERSION), config=$(CONFIG))"

clean:
	rm -rf $(PROJECT) \
		/tmp/$(APP_NAME).xcarchive /tmp/$(APP_NAME)IPA /tmp/$(APP_NAME).ipa \
		/tmp/$(APP_NAME)CloudKit.xcarchive /tmp/$(APP_NAME)CloudKitIPA /tmp/$(APP_NAME)CloudKit.ipa
