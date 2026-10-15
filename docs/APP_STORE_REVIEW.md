# App Store preparation

Native SwiftUI app, iOS 17+, iPhone and iPad. No login, ads, payments, tracking, microphone, location, or third-party SDKs. Includes ten fictional English lessons offline, dialogue rehearsal, saved lessons, practice progress, Dynamic Type, system appearance, and native sharing.

## Review notes (paste into App Store Connect)
Mayday ATC preserves its original video archive experience: recording cards, category filter, search, PLAY links, and recording details. Select a card to view the recording title/channel and independent category language exercises, then use WATCH REAL ATC VIDEO to open YouTube. The practice examples are fictional and are not transcripts or analyses of the linked recording. No account or special access is needed. Save recordings, rehearse pilot responses in details, or mark a category practiced. Settings contains privacy policy, support, reset, content revision, and manual sync. Text lessons and video metadata work offline; YouTube playback requires internet. The Update content button downloads the latest validated shared JSON only; it does not start the scheduled/admin publishing workflow. New app functionality and binaries ship through the App Store.

## Metadata draft
Name: Mayday ATC
Subtitle: Aviation English Practice
Category: Education
Description: Practice aviation English with fictional communication situations. Study ten offline lessons, rehearse pilot responses, save favorites, track completed practice, and share reflection prompts. Independent language learning only: not real ATC transcripts, emergency instructions, operational guidance, or an accredited ICAO course.
Support URL: https://github.com/outinletter/maydayatc/issues
Privacy policy URL: https://github.com/outinletter/maydayatc/blob/main/docs/PRIVACY.md (public rendered Markdown; also bundled in app Settings).

## Required owner actions before submission
- Verify developer identity, app/content ownership, and support contact availability. Confirm Issues are enabled and support URL is reachable.
- Register the app using the final bundle ID; update DEVELOPMENT_TEAM if needed. Installed development builds are not App Store submissions.
- Verify the public privacy policy URL loads while logged out after pushing. The repository is public and Issues are enabled.
- Review App Privacy answers against the actual GitHub network request and GitHub's terms; no app-level user identifiers, bookmarks, or progress are transmitted. Privacy manifest declares local UserDefaults use CA92.1, no tracking, no SDK collection.
- Complete age-rating questionnaire honestly (fictional emergency situations; no graphic media), export compliance, territories, pricing, and copyright fields. Cryptography is limited to OS HTTPS; confirm export-compliance answers before upload.
- Capture screenshots from the actual release build on required device sizes; do not use the launcher icon as a screenshot.
- Test VoiceOver, largest accessibility text, iPad split view, landscape, offline first launch, reset, failed updates, and interrupted launches on devices.
- Archive a signed Release build, validate in Xcode Organizer, upload to App Store Connect, test through TestFlight, and submit for review. Approval remains Apple's decision (especially guidelines 2.1, 2.5.2, 4.2, 5.1.1).

Source: https://developer.apple.com/app-store/review/guidelines/ (checked 2026-10-15).

Original video archive: 26 distinct YouTube links were checked using YouTube oEmbed on 2026-10-15; titles/channel names come from that endpoint. Two duplicate catalog entries were consolidated. View counts and durations were removed because they were unverified. Links open externally; videos are not embedded or downloaded. Fictional lessons are explicitly separate from recordings. Availability can change. Confirm any third-party rights/service requirements before submission.
