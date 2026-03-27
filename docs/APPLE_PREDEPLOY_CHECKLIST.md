# Apple App Store Pre-Deployment Checklist

Use this checklist before submitting a build in App Store Connect.

## App Configuration

- [ ] Bundle ID and app name are final.
- [ ] Version and build number are incremented.
- [ ] Release signing/provisioning profile is valid.
- [ ] App icons and launch screens are complete.

## Privacy and Compliance

- [ ] `ios/Runner/PrivacyInfo.xcprivacy` is reviewed and accurate.
- [ ] App Privacy answers in App Store Connect match real data usage.
- [ ] Public Privacy Policy URL is available and matches `PRIVACY_POLICY.md`.
- [ ] Terms of Service URL is available and current.
- [ ] Tracking declarations are correct (ATT if applicable).
- [ ] Export compliance questionnaire is answered.

## Product Metadata

- [ ] Description, subtitle, and keywords are complete.
- [ ] Screenshots for required device classes are uploaded.
- [ ] Support URL and contact email are valid.
- [ ] Marketing URL (optional) is valid.
- [ ] Age rating questionnaire is completed accurately.

## Functionality Verification

- [ ] TestFlight smoke test passes on a physical iPhone.
- [ ] Auth flows work in release mode.
- [ ] Listing create/edit/image upload works in release mode.
- [ ] Messaging and exchanges flows work in release mode.
- [ ] Crash-free startup and no blocking errors in logs.

## Operational Readiness

- [ ] Backend production URL is configured for release builds.
- [ ] Production environment variables are set and validated.
- [ ] Monitoring and alerting are enabled for backend and app crashes.
- [ ] Rollback plan is documented.
