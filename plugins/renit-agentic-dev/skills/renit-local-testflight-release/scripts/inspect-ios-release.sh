#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
cd "$repo_root"

expected_host="qa-api.toratora.site"
expected_bundle="com.renit.app"
expected_team="43Q57TAAAQ"
project_file="ios/Renit.xcodeproj/project.pbxproj"
info_plist="ios/Renit/Info.plist"
entitlements="ios/Renit/Renit.entitlements"

block() {
  echo "BLOCKED: $*" >&2
  exit 1
}

for command_name in node xcodebuild plutil security; do
  command -v "$command_name" >/dev/null 2>&1 || block "required command '$command_name' is unavailable"
done

for required_path in app.json app.config.js eas.json "$project_file" "$info_plist" "$entitlements" ios/Renit.xcworkspace/contents.xcworkspacedata ios/Renit/GoogleService-Info.plist; do
  test -f "$required_path" || block "required path '$required_path' is missing"
done

test "${EXPO_PUBLIC_APP_ENV:-QA}" = "QA" || block "EXPO_PUBLIC_APP_ENV must be QA"
test "${EXPO_PUBLIC_QA_API_HOST:-$expected_host}" = "$expected_host" || block "EXPO_PUBLIC_QA_API_HOST must be $expected_host"

resolved_config="$(mktemp)"
trap 'rm -f "$resolved_config"' EXIT
EXPO_PUBLIC_APP_ENV=QA EXPO_PUBLIC_QA_API_HOST="$expected_host" npx expo config --type public --json > "$resolved_config" || block "failed to resolve the QA Expo configuration"
node - "$resolved_config" <<'NODE' || block "resolved Expo configuration is not the expected QA iOS identity"
const config = JSON.parse(require("fs").readFileSync(process.argv[2], "utf8"));
if (
  config.name !== "Renit QA" ||
  config.slug !== "renit-qa-app" ||
  config.ios?.bundleIdentifier !== "com.renit.app" ||
  config.extra?.appEnv !== "QA"
) {
  process.exit(1);
}
NODE

grep -q '"EXPO_PUBLIC_QA_API_HOST": "qa-api.toratora.site"' eas.json || block "eas.json QA host drift detected"
grep -q 'PRODUCT_BUNDLE_IDENTIFIER = com.renit.app;' "$project_file" || block "iOS bundle identifier drift detected"
grep -q 'DEVELOPMENT_TEAM = 43Q57TAAAQ;' "$project_file" || block "iOS Apple team drift detected"
grep -q 'CODE_SIGN_IDENTITY = "Apple Distribution";' "$project_file" || block "Release Apple Distribution signing is not configured"
grep -q 'CODE_SIGN_STYLE = Manual;' "$project_file" || block "Release manual signing is not configured"
grep -q '<key>aps-environment</key>' "$entitlements" || block "Push entitlement is missing"

plist_bundle="$(plutil -extract CFBundleIdentifier raw "$info_plist")"
test "$plist_bundle" = '$(PRODUCT_BUNDLE_IDENTIFIER)' || block "Info.plist bundle identifier is not build-setting based"

marketing_version="$(plutil -extract CFBundleShortVersionString raw "$info_plist")"
build_number="$(plutil -extract CFBundleVersion raw "$info_plist")"
test -n "$marketing_version" && test -n "$build_number" || block "iOS version/build is missing"

if ! security find-identity -v -p codesigning | grep -q 'Apple Distribution: Renit Classifieds LLP'; then
  block "no valid Renit Apple Distribution identity is available in the login keychain"
fi

echo "READY: QA local TestFlight archive preflight passed"
echo "qa_host=$expected_host"
echo "bundle_id=$expected_bundle"
echo "apple_team=$expected_team"
echo "version=$marketing_version"
echo "build=$build_number"
