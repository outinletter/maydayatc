# Version 1.0 build 16 preparation

2026년 10월 23일 기준입니다. 심사 회신 전송 및 재심사 신청은 하지 않습니다.

- 영어 외 한국어, 일본어, 중국어 간체, 스페인어, 프랑스어, 독일어, 이탈리아어, 브라질 포르투갈어, 러시아어, 네덜란드어를 지원합니다.
- 157개 문구를 각 언어로 제공하며, 수업 제목과 요약, 학습 해설, 정답·오답 피드백, 진행률과 개인정보 안내를 포함합니다.
- 영어 무전 대화와 응답 예문은 영어 학습 원문으로 유지합니다. 새로 내려받은 알 수 없는 원문은 영어로 표시하며, 현재 게시기의 공통 수업 형식은 현지화합니다.
- 소스 번역 완전성, 서식 인수와 아카이브 내 실제 10개 언어 리소스 검사가 통과했습니다.
- 기존 콘텐츠·화자 구분·73개 문항 및 각 선택지 피드백 검사가 통과했습니다.
- 서명된 Release 아카이브 생성, App Store Connect 업로드와 iPhone 설치가 성공했습니다.
- 영어 및 비영어 10개 언어의 실기기 UI 검사가 통과했습니다. 각 언어에서 설정·조종사 선택, 대화, 문항, 오답 및 정답 전환을 확인했습니다. 첫 촬영 스크립트의 위치 선택 오류는 수정했습니다. 재생 창을 닫은 뒤 최종 재촬영 검사도 통과했습니다. 스토어용으로는 홈·설정·대화·문항 원본을 선택하고, 설명이 화면 밖으로 스크롤되거나 알림이 찍힌 사진은 제외했습니다.
- 10개 언어의 설명, 프로모션 문구, 키워드, 앱 이름과 부제를 App Store Connect에 저장했습니다. 영어 설명 및 심사 메모도 다국어 지원 내용으로 갱신했고 제출 초안은 처리된 빌드 16을 선택해 저장했습니다. 각 비영어 언어에 원본 iPhone 사진 4장을 업로드했습니다. 영어는 새 원본 4장과 기존 학습 기능 사진 4장, 미리보기 영상을 유지합니다.

## Build evidence

Developer directory: `/Applications/Xcode-Internal.app/Contents/Developer`

Xcode 26.3, build 17C529. iPhoneOS SDK 26.2. `/Volumes/XcodeBuild` is mounted APFS backed by `/Volumes/Data/Xcode/XcodeBuild.sparsebundle`.

DerivedData: `/Volumes/XcodeBuild/DerivedData/MaydayATC`

```sh
DEVELOPER_DIR=/Applications/Xcode-Internal.app/Contents/Developer xcodebuild -project ios/MaydayATC.xcodeproj -scheme MaydayATC -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /Volumes/XcodeBuild/DerivedData/MaydayATC -archivePath outputs/build16/MaydayATC16.xcarchive archive
```

Exit 0. `ARCHIVE SUCCEEDED`. Apple Development signing succeeded with the existing team configuration. Log: `outputs/build16/archive.log`.

```sh
DEVELOPER_DIR=/Applications/Xcode-Internal.app/Contents/Developer xcodebuild -exportArchive -archivePath outputs/build16/MaydayATC16.xcarchive -exportPath outputs/build16/upload -exportOptionsPlist outputs/build12/ExportOptions.plist
```

Exit 0. `Upload succeeded`, `EXPORT SUCCEEDED`. Log: `outputs/build16/upload.log`. App Store processing completed and the version 1.0 draft selects build 16.

The existing iPhone app was updated with the same bundle ID. Installation exit 0. Log: `outputs/build16/install.log`. No TestFlight beta distribution was requested or performed.

## Physical iPhone UI evidence

```sh
DEVELOPER_DIR=/Applications/Xcode-Internal.app/Contents/Developer xcodebuild -project ios/MaydayATC.xcodeproj -scheme ReviewCapture -configuration Release -destination 'platform=iOS,id=00008140-0006089C30E3C01C' -derivedDataPath /Volumes/XcodeBuild/DerivedData/MaydayATC -resultBundlePath outputs/build16/localized-clean.xcresult -only-testing:ReviewCaptureTests/ReviewCapture/testLocalizedScreenshots test
```

Exit 0. `TEST SUCCEEDED`. English plus ten additional language launches, localized settings and role selection, dialogue and question labels, and switching from incorrect to correct feedback passed. Log: `outputs/build16/device-ui-clean.log`. This is developer testing, not external beta testing. All 73 questions were covered by model checks; this device run used the Engine Failure pilot questions.

66 original screenshots were exported for QA. The store selection uses four per locale; the Spanish question image is the clean original from the earlier successful multilingual run, because a notification appeared in its later capture. No pixels were edited. English retains the four existing controller, explanation and mistake-review images because their interface remains current, together with the original preview video.

Only the capture-test runner was uninstalled after testing. The final app launched normally without a language override. Logs: `outputs/build16/runner-cleanup.log`, `outputs/build16/final-launch.log`.
