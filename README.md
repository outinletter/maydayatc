# Mayday ATC

Mayday ATC video archive with the original recording-card feed, category filter, search, PLAY links, and recording detail flow, implemented natively on iOS plus the original browser version. All lessons are fictional language exercises, not actual transcripts or flight instructions.

Open `ios/MaydayATC.xcodeproj`, select MaydayATC, select your development team and device, and run. iOS 17+. No package dependencies. Ten lessons are bundled for offline first launch.

## Shared content publishing
GitHub Actions `Publish shared content` runs every Sunday at 09:00 Asia/Seoul (00:00 UTC), or a repository administrator can choose Run workflow. It collects recent emergency-related videos from the three approved public YouTube channel feeds in `content/sources.json`, checks official oEmbed metadata, and composes an original fictional language exercise for each new video from reviewed templates. It does not extract speech, download captions/media, use an LLM, or claim to reconstruct actual events. No API keys or paid service are required.

Each run adds at most five videos, deduplicates IDs, keeps the latest 80 published entries plus their linked lessons, validates both catalogs, and publishes one shared JSON revision to main. Empty runs do not increase the revision. Any source/verification/validation failure leaves the published revision untouched. Runs are serialized. GitHub may delay scheduled jobs. Configure approved channels and limits in `content/sources.json`. See the Actions run log to monitor failures.

In the app, Settings → Update content or pull to refresh downloads the latest completed shared revision. The web Settings button does the same. Neither app checks on launch or triggers collection/generation. No GitHub credentials are shipped to users. All users receive the same catalog. Timeout, size/schema checks, rollback protection, and offline fallback remain in place. Native app code/features still ship through App Store/TestFlight.

Every reference may include `lessonId`, which points to its own scenario; older entries fall back to their category lesson. Keep the ten base category scenarios. Manual edits must increment `revision`, preserve schemaVersion 1, copy `content/catalog.json` into `ios/MaydayATC/catalog.json`, and pass `python3 scripts/validate-content.py` plus `python3 -m unittest discover -s tests -p 'test_*.py'`. Built-in browser fallback data is older bundled content; users get newer revisions using Update content.

## Build
```
xcodebuild -project ios/MaydayATC.xcodeproj -scheme MaydayATC -sdk iphonesimulator -configuration Release CODE_SIGNING_ALLOWED=NO build
```

See `docs/APP_STORE_REVIEW.md` for review notes and outstanding submission metadata. See `privacy.html` for privacy policy. Support: https://github.com/outinletter/maydayatc/issues

Original video archive: 26 distinct YouTube links were checked using YouTube oEmbed on 2026-10-15; titles/channel names come from that endpoint. Two duplicate catalog entries were consolidated. View counts and durations were removed because they were unverified. Links open externally; videos are not embedded or downloaded. Fictional lessons are explicitly separate from recordings. Availability can change. Confirm any third-party rights/service requirements before submission.
