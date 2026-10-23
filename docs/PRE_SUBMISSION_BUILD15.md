# Version 1.0 build 15 preparation

2026년 10월 23일 기준입니다. 심사 회신 전송 및 재심사 신청은 하지 않습니다.

- 영어 외 한국어, 일본어, 중국어 간체, 스페인어, 프랑스어, 독일어, 이탈리아어, 브라질 포르투갈어, 러시아어, 네덜란드어를 지원합니다.
- 157개 문구를 각 언어로 제공하며, 수업 제목과 요약, 학습 해설, 정답·오답 피드백, 진행률과 개인정보 안내를 포함합니다.
- 영어 무전 대화와 응답 예문은 영어 학습 원문으로 유지합니다. 새로 내려받은 알 수 없는 원문은 영어로 표시하며, 현재 게시기의 공통 수업 형식은 현지화합니다.
- 소스 번역 완전성, 서식 인수와 아카이브 내 실제 10개 언어 리소스 검사가 통과했습니다.
- 기존 콘텐츠·화자 구분·73개 문항 및 각 선택지 피드백 검사가 통과했습니다.
- 서명된 Release 아카이브 생성, App Store Connect 업로드와 iPhone 설치가 성공했습니다.
- 실기기 다국어 화면 검증 및 촬영은 현재 아이폰 잠금 해제를 기다리고 있습니다. 완료된 검사로 기재하지 않습니다.
- 한국어 제품 페이지 설명은 저장했습니다. 나머지 언어는 APP_STORE_LOCALIZATIONS.json에 준비했으며 저장 작업이 진행 중입니다.

## Build evidence

Developer directory: `/Applications/Xcode-Internal.app/Contents/Developer`

Xcode 26.3, build 17C529. iPhoneOS SDK 26.2. `/Volumes/XcodeBuild` is mounted APFS backed by `/Volumes/Data/Xcode/XcodeBuild.sparsebundle`.

DerivedData: `/Volumes/XcodeBuild/DerivedData/MaydayATC`

```sh
DEVELOPER_DIR=/Applications/Xcode-Internal.app/Contents/Developer xcodebuild -project ios/MaydayATC.xcodeproj -scheme MaydayATC -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /Volumes/XcodeBuild/DerivedData/MaydayATC -archivePath outputs/build15/MaydayATC15-localized.xcarchive archive
```

Exit 0. `ARCHIVE SUCCEEDED`. Apple Development signing succeeded with the existing team configuration. Log: `outputs/build15/archive-localized.log`.

```sh
DEVELOPER_DIR=/Applications/Xcode-Internal.app/Contents/Developer xcodebuild -exportArchive -archivePath outputs/build15/MaydayATC15-localized.xcarchive -exportPath outputs/build15/upload15-localized -exportOptionsPlist outputs/build12/ExportOptions.plist
```

Exit 0. `Upload succeeded`, `EXPORT SUCCEEDED`. Log: `outputs/build15/upload.log`. This confirms upload; App Store processing and draft build selection are separate.

The existing iPhone app was updated with the same bundle ID. Installation exit 0. Log: `outputs/build15/install.log`. No TestFlight beta distribution was requested or performed.
