# Response to App Review 4.3 and 4.2.6

Prepared response for the existing review conversation. Not sent. The developer requested preparation only, stopping before submission. Ownership and cross-app statements were confirmed by the developer on October 22, 2026. The current candidate is build 16. Historical role/persistence verification was completed on build 14; build 16 passed the multilingual physical-iPhone UI test. Do not claim external beta testing, accreditation or market exclusivity.

Dear App Review team,

Thank you for the opportunity to clarify the purpose and origin of Mayday ATC. I am the developer and a pilot. I conceived this product for aviation English learning needed in my professional field. It was not commissioned by a client and was not made using a commercial app template or app generation service. I have implemented the changes described below in version 1.0 build 16. The rejected build has not been resubmitted.

Mayday ATC uses one explicit Bundle ID, `com.addvalue.maydayatc`; I have not created regional, client-specific, or duplicate Bundle IDs. It is a standalone product with one focused workflow: role-based aviation dialogue comprehension, two-choice response practice, source-based explanations, and local mistake review. The product is not a general video catalog, a social feed, or a copy of a popular video app.

1. What the app does and the problem it solves

Mayday ATC provides fictional aviation English dialogues for deliberate study between pilots and air traffic controllers. Its purpose is practicing how one message connects to the next response, beyond watching a video or reading vocabulary. In the revised implementation, learners choose Pilot or Controller in Settings, study both sides of a dialogue, and select one of two examples for the next message by their role. The app explains the answer using the source dialogue and retains mistakes for focused review. Learners can start another round or change roles. Preferences and role-specific question records stay on the device. A direct practice library works independently of the video archive. Source videos are optional external references. Fictional lessons are not video transcripts or operational instructions.

2. Intended audience

The intended users are pilots and air traffic controllers seeking supplementary English dialogue comprehension practice outside operational duties. Pilots practice responses to controller messages, while controllers practice responses to pilot messages. This is an independent language learning aid, not official flight training, a licensing examination or an accredited ICAO assessment.

3. Need addressed

The specific need is a repeatable role-specific aviation dialogue exercise connecting reading, response selection, source-based feedback and later review. A video reference alone does not provide that loop. The app combines the two speaker perspectives and retains individual mistakes locally. I do not claim that no competing product has similar capabilities or that the app is the first of its kind. Its intended contribution is this focused workflow designed by a pilot for pilots and controllers.

This distinction addresses the two spam concerns directly: there is no second app or location variant, and the app's primary utility is the integrated pilot/controller exercise and feedback loop rather than a generic media or language-content listing.

4. Testing before submission

The original submission was not tested through TestFlight. There was no external beta cohort. I cannot provide examples of external beta feedback because none was conducted. Development validation of the earlier build included a connected iPhone and XCTest screenshot capture. During development, I identified poor text readability, difficulty distinguishing pilot and controller messages, and insufficient visual progression between an original and revised phrase. The production build was changed to use stronger text contrast, separately labelled speaker bubbles, and a staged original phrase to revised phrase to explanation layout. A content update control was also made visibly tappable. These were developer observations and development feedback, not external beta feedback.

Content validation, five publisher tests, automated checks for all 73 questions across 15 lessons, and the signed Release device build passed. End-to-end UI testing was completed on a physical iPhone 16 Pro. The final build 14 role-practice test verified Pilot and Controller selection, correct and incorrect answer feedback, switching to the other example to compare explanations, preservation of the first answer after switching, role preference and mistake-record persistence after relaunch, and the mistake-only lesson filter. A separate build 13 test verified two reveal-and-hide cycles for each role; that feature is retained in build 14. Both final targeted UI runs passed with zero failures and zero skipped tests. Seven current original iPhone screenshots were captured, including both explanations, and the explanation screens were visually reviewed. Release build 14 was installed and launched successfully on the same iPhone. These are developer tests, not TestFlight or external beta testing. Automated content checks covered all 73 questions, while device UI testing used the Engine Failure lesson for both roles.

5. Standalone product or suite

Mayday ATC is a standalone aviation English learning product, not a themed variant in a suite. I confirm that it does not share proprietary code, images or learning materials with other apps on my developer account.

6. Consolidation into another app

This workflow was conceived as a standalone product rather than a content pack for another app. In principle an existing learning app could be expanded, but this requires a two-speaker lesson model, pilot and controller perspectives, response selection, evidence-based feedback and role-specific mistake records, rather than simply adding videos or text. I chose a separate product for that focused professional audience. No proprietary code, images or learning materials are shared with my other apps.

7. Shared components with other apps on my account

No proprietary code, images or learning materials are shared with other apps on my developer account. The native implementation uses standard Apple frameworks such as SwiftUI and Foundation. The project does not include a third-party app generation SDK.

8. Shared components with third-party apps

I have not used a commercial app template, another third-party app codebase or a third-party content library to create this product. The implementation uses standard Apple frameworks. YouTube titles, channel names and external links identify third-party videos, which are not represented as my original videos. The app does not download or embed them. Fictional exercises are kept separate. Internal text patterns used to prepare fictional exercises are not a purchased app template or app generation service. New collected material is now prepared as an editorial candidate requiring developer review before publication to the shared feed.

9. Client, partner and content provider

No client, partner or commissioning third party supplied the concept or branding. I am the pilot who conceived and developed this app and I am submitting through my own developer account. External videos are credited references. I am responsible for the app and its independent fictional exercises; I am not a template vendor submitting on behalf of a customer.

The main functional changes are role selection, a direct lesson practice library, two-choice response exercises, source-linked answer feedback, persistent role-specific question records and mistake review. Build 13 also allows learners to reveal and hide each response repeatedly during rehearsal. A separate physical-device UI test exercised two reveal/hide cycles for each role. These changes make the learning flow accessible independently of the external video archive. Please let me know which specific app or component raised concerns about duplication or a commercial app generation service so I can address that concern directly.

Build 14 additionally lets learners switch freely between both examples after answering and read a separate explanation for each choice. Only the first answer in a round is recorded, so exploring another explanation does not inflate attempts or overwrite the original result. The physical-device role-practice test was rerun on build 14 and passed, including switching from an incorrect example to the correct example and verifying after relaunch that the initial mistake remained recorded. Seven current iPhone screenshots were captured, including both explanations. Automated checks also passed for the distinct explanations of all 73 questions.

Build 16 retains that workflow and adds localized interface text, lesson categories, lesson summaries, language-reflection explanations and choice-specific feedback in Korean, Japanese, Simplified Chinese, Spanish, French, German, Italian, Brazilian Portuguese, Russian and Dutch. Aviation dialogue and response examples remain in English. All 157 localized resource keys passed ten-language completeness and format checks, including verification inside the signed Release archive. Build 16 was uploaded to App Store Connect and installed on the connected iPhone. A physical-iPhone UI test passed in English and all ten additional languages, checking localized settings, Pilot selection, dialogue, the practice prompt, and switching between incorrect and correct feedback. Four original iPhone screenshots have been uploaded for each additional locale. The English set includes four new images and retains four existing learning-function screenshots and the preview video. These are developer tests, not external beta testing.

I respectfully ask that the team evaluate this submission as the single, independently developed Mayday ATC product described above. I have answered each question from the 4.3 and 4.2.6 notice directly and can provide additional ownership or implementation details if needed.

## Available evidence

- Version 1.0 build 16 is uploaded and selected in the submission draft. The final physical-iPhone test passed in English and all ten additional languages. The expanded role-practice and persistence test previously passed on build 14; the repeated reveal/hide test passed on build 13. These features are retained in build 16.
- Localized screenshot selection: outputs/build16/store-screenshots. Four new originals per locale, English plus ten additional languages. The English store also retains the controller, correct/incorrect explanation and mistake-review originals from outputs/app-store-screenshots/iphone-release14. The preview video is preserved.
- Review steps: Home, Role practice, select lesson, read dialogue, answer a question, inspect feedback, start a new round or filter mistakes. Change role through Settings.
- Source diff showing role selection, question construction, local records and the editorial publication gate.
- Do not call development observations external beta feedback or claim aviation authority approval.
