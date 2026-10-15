# App Store preparation

Native SwiftUI app, iOS 17+, iPhone only for the first release. No login, ads, payments, tracking, microphone, location, or third-party SDKs. Includes fifteen fictional English lessons offline, dialogue rehearsal, saved lessons, practice progress, Dynamic Type, system appearance, and native sharing.

## Review notes (paste into App Store Connect)
Mayday ATC preserves its original video archive experience: recording cards, category filter, search, PLAY links, and recording details. Select a card to view the recording title/channel and independent category language exercises, then use WATCH REAL ATC VIDEO to open YouTube. The practice examples are fictional and are not transcripts or analyses of the linked recording. No account or special access is needed. Save recordings, rehearse pilot responses in details, or mark a category practiced. Settings contains privacy policy, support, reset, content revision, and manual sync. Text lessons and video metadata work offline; YouTube playback requires internet. The Update content button downloads the latest validated shared JSON only; it does not start the scheduled/admin publishing workflow. New app functionality and binaries ship through the App Store.

## Metadata draft
Name: Mayday ATC
Subtitle: Aviation English Practice
Category: Education
Description: Practice aviation English with fictional communication situations. Study fifteen offline lessons, rehearse pilot responses, save favorites, track completed practice, and share reflection prompts. Independent language learning only: not real ATC transcripts, emergency instructions, operational guidance, or an accredited ICAO course.
Support URL: https://github.com/outinletter/maydayatc/blob/main/docs/SUPPORT.md
Privacy policy URL: https://github.com/outinletter/maydayatc/blob/main/docs/PRIVACY.md (public rendered Markdown; also bundled in app Settings).

## Required owner actions before submission
- Verify developer identity, app/content ownership, and support contact availability. Confirm Issues are enabled and support URL is reachable.
- Register the app using the final bundle ID; update DEVELOPMENT_TEAM if needed. Installed development builds are not App Store submissions.
- Verify the public privacy policy URL loads while logged out after pushing. The repository is public and Issues are enabled.
- Review App Privacy answers against the actual GitHub network request and GitHub's terms; no app-level user identifiers, bookmarks, or progress are transmitted. Privacy manifest declares local UserDefaults use CA92.1, no tracking, no SDK collection.
- Complete age-rating questionnaire honestly (fictional emergency situations; no graphic media), export compliance, territories, pricing, and copyright fields. Cryptography is limited to OS HTTPS; confirm export-compliance answers before upload.
- Capture screenshots from the actual release build on required device sizes; do not use the launcher icon as a screenshot.
- Test VoiceOver, largest accessibility text, landscape, offline first launch, reset, failed updates, and interrupted launches on devices.
- Archive a signed Release build, validate in Xcode Organizer, upload to App Store Connect, verify on the connected iPhone (the owner requested no separate TestFlight testing), and submit for review. Approval remains Apple's decision (especially guidelines 2.1, 2.5.2, 4.2, 5.1.1).

Source: https://developer.apple.com/app-store/review/guidelines/ (checked 2026-10-15).

Original video archive: catalog revision 4 contains 31 distinct YouTube links and 15 fictional lessons; metadata was checked using YouTube oEmbed on 2026-10-15; titles/channel names come from that endpoint. Two duplicate catalog entries were consolidated. View counts and durations were removed because they were unverified. Links open externally; videos are not embedded or downloaded. Fictional lessons are explicitly separate from recordings. Availability can change. Confirm any third-party rights/service requirements before submission.

## Submission status — 2026-10-15

App Store Connect app 6822957516, bundle com.addvalue.maydayatc. Release 1.0 (7) archive and upload succeeded; it is superseded by iPhone-only build 8. Five original 1206 × 2622 screenshots were captured on the connected iPhone after hiding its floating accessibility panel. The physical-device capture test passed. Education/Reference categories, 9+ rating, public policy/support URLs and review contact were entered.

The owner subsequently instructed submission with content rights held on 2026-10-15. App Store Connect necessary-rights attestation was saved based on that owner confirmation. Public links alone are not proof of all necessary permissions. Keep a documented permission or applicable license/terms basis for title/channel metadata and linked content, including attribution and refresh/deletion obligations. See Apple guideline 5.2 and https://www.youtube.com/t/terms . Check whether https://developers.google.com/youtube/terms/developer-policies applies to RSS/oEmbed before relying on its license.

The owner chose an iPhone-only first release on 2026-10-15. App and capture-test device families are iPhone only (1), build 8. iPad support is deferred to a later release. Existing physical-iPhone screenshots still show the current interface. The owner confirmed content rights for submission; the attestation was saved. Separate TestFlight distribution is omitted.

## Submission completed

On 2026-10-15 at approximately 10:15 KST, version 1.0 (8), iPhone only, was submitted to App Review. App Store Connect confirmed Waiting for Review (심사 대기 중) and one submitted item. Five physical-iPhone screenshots and one 20-second physical-device app preview were included. Preview: 886 × 1920 H.264, 30fps, stereo AAC; the original supplied recording is unchanged. Necessary content rights were declared based on the owner confirmation. Manual release remains selected; approval does not automatically publish the app. No separate TestFlight testing was performed.

## Updated first release candidate — 2026-10-15

The original 1.0 build 8 review item was canceled so the updated first release could replace it. Build 11 keeps the initial App Store version at 1.0 and uses bundle identifier com.addvalue.maydayatc. The archive was uploaded successfully and is awaiting App Store Connect processing. The earlier 1.0.1 build 10 upload is not selected for review.

Five current iPhone screenshots were captured on the connected iPhone 16 Pro and uploaded to the 6.3 inch iPhone screenshot set. They show the updated archive, learning detail, pilot and controller dialogue, language reflection progression, and pastel content update button. The existing device captured app preview was preserved. App Review contact and privacy declarations remain unchanged as requested. App Store promotional text and description were revised to match the current app and avoid the prohibited symbols.
