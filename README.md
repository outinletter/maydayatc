# Mayday ATC

Mayday ATC video archive with the original recording-card feed, category filter, search, PLAY links, and recording detail flow, implemented natively on iOS plus the original browser version. All lessons are fictional language exercises, not actual transcripts or flight instructions.

Open `ios/MaydayATC.xcodeproj`, select MaydayATC, select your development team and device, and run. iOS 17+. No package dependencies. Fifteen lessons are bundled for offline first launch.

## Role practice

Settings lets pilots and controllers choose their learning role. The home practice entry opens the lesson library without requiring a source video. Read a fictional exchange, choose the next response from two examples, see source-based feedback, and revisit mistakes. The current catalog produces 73 questions across both roles. Question identities include the source messages so changed content does not inherit obsolete results. Records and role preferences stay on the device and are removed by Delete local data. This is dialogue comprehension, not an operational proficiency assessment.

## Shared content publishing
GitHub Actions `Prepare content for editorial review` runs every Sunday at 09:00 Asia/Seoul (00:00 UTC), or an administrator can choose Run workflow. It collects video metadata from the approved channel feeds, checks YouTube oEmbed metadata, and prepares fictional language exercises using internal text patterns. It does not extract speech, download captions/media, use an LLM, or claim to reconstruct actual events. No API keys or paid service are required.

Each run prepares at most five new videos, deduplicates IDs, caps the candidate catalog, validates both copies, and stores a review artifact for 30 days. It does not write to main. The developer must review and commit approved material before app users receive it. See `docs/CONTENT_REVIEW.md`. Configure approved channels and limits in `content/sources.json`.

In the app, Settings → Update content or pull to refresh downloads the latest published shared revision. The web Settings button does the same. Neither app checks on launch or triggers collection/generation. No GitHub credentials are shipped to users. All users receive the same catalog. Timeout, size/schema checks, rollback protection, and offline fallback remain in place. Native features ship through the App Store. Separate TestFlight distribution is not used.

Every reference may include `lessonId`, which points to its own scenario; older entries fall back to their category lesson. Keep the ten base category scenarios. Manual edits must increment `revision`, preserve schemaVersion 1, copy `content/catalog.json` into `ios/MaydayATC/catalog.json`, and pass `python3 scripts/validate-content.py` plus `python3 -m unittest discover -s tests -p 'test_*.py'`. Built-in browser fallback data is older bundled content; users get newer revisions using Update content.

## Build
```
xcodebuild -project ios/MaydayATC.xcodeproj -scheme MaydayATC -sdk iphonesimulator -configuration Release CODE_SIGNING_ALLOWED=NO build
```

See `docs/APP_STORE_REVIEW.md` for review notes and outstanding submission metadata. See `privacy.html` for privacy policy. Support: https://github.com/outinletter/maydayatc/issues

Original video archive: 26 distinct YouTube links were checked using YouTube oEmbed on 2026-10-15; titles/channel names come from that endpoint. Two duplicate catalog entries were consolidated. View counts and durations were removed because they were unverified. Links open externally; videos are not embedded or downloaded. Fictional lessons are explicitly separate from recordings. Availability can change. Confirm any third-party rights/service requirements before submission.
