# Mayday ATC

Mayday ATC video archive with the original recording-card feed, category filter, search, PLAY links, and recording detail flow, implemented natively on iOS plus the original browser version. All lessons are fictional language exercises, not actual transcripts or flight instructions.

Open `ios/MaydayATC.xcodeproj`, select MaydayATC, select your development team and device, and run. iOS 17+. No package dependencies. Ten lessons are bundled for offline first launch.

## GitHub lesson updates
Both apps check `https://raw.githubusercontent.com/outinletter/maydayatc/main/content/catalog.json` at launch. iOS Settings can disable automatic checks. Pull to refresh or use Settings for manual checks. Checks have a 15-second timeout, schema validation, size limit, and rollback protection. Failed updates retain existing lessons. iOS caches validated JSON atomically in Application Support. No app code is downloaded. Native app versions/features must ship through App Store/TestFlight.

To publish lessons: edit `content/catalog.json`, increment `revision`, keep `schemaVersion: 1`, copy to `ios/MaydayATC/catalog.json`, run `python3 scripts/validate-content.py`, review all text, then push to main. Keep the ten existing category IDs for compatibility with the web app. Changes to the bundled browser lessons also require updating its built-in dataset; runtime JSON content is loaded when revision increases. Never add scripts, HTML, real-world operational advice, or unverified transcript claims to content.

## Build
```
xcodebuild -project ios/MaydayATC.xcodeproj -scheme MaydayATC -sdk iphonesimulator -configuration Release CODE_SIGNING_ALLOWED=NO build
```

See `docs/APP_STORE_REVIEW.md` for review notes and outstanding submission metadata. See `privacy.html` for privacy policy. Support: https://github.com/outinletter/maydayatc/issues

Original video archive: 26 distinct YouTube links were checked using YouTube oEmbed on 2026-10-15; titles/channel names come from that endpoint. Two duplicate catalog entries were consolidated. View counts and durations were removed because they were unverified. Links open externally; videos are not embedded or downloaded. Fictional lessons are explicitly separate from recordings. Availability can change. Confirm any third-party rights/service requirements before submission.
