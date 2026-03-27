# Deployment Readiness Checklist

Use this checklist before shipping to production and before App Store submission.

## 1) Environment and Secrets

- [ ] Move client API base URL to build-time config (`--dart-define`) for each environment.
- [ ] Remove localhost defaults from release paths.
- [ ] Configure backend production env vars in your host platform (never commit secrets).
- [ ] Rotate and validate Firebase service credentials for production.

## 2) Backend Production Hardening

- [ ] Restrict CORS to approved origins.
- [ ] Add rate limiting on auth, messaging, and write-heavy routes.
- [ ] Add security headers (`helmet`) and payload size limits.
- [ ] Add structured logging and request correlation IDs.
- [ ] Add `/health` and `/ready` checks for runtime and DB connectivity.

## 3) Database and Migrations

- [ ] Ensure all production migrations are committed and reversible where possible.
- [ ] Confirm backup strategy and restore drill before release.
- [ ] Run migration in staging first, then production.
- [ ] Verify seed/admin data scripts for launch requirements.

## 4) Auth, Privacy, and Policy Enforcement

- [ ] Enforce all critical auth/policy checks server-side (not only in client UI).
- [ ] Verify data retention and account deletion behavior.
- [ ] Validate logging does not include sensitive user data.
- [ ] Keep privacy and terms documents current with actual data handling.

## 5) Mobile Release Configuration

- [ ] iOS signing, bundle identifiers, and provisioning profiles configured.
- [ ] Android signing and release keystore configured.
- [ ] Versioning/build numbers updated in both platforms.
- [ ] Crash reporting enabled for release builds.

## 6) Apple Pre-Deployment Readiness

- [ ] Fill and validate `ios/Runner/PrivacyInfo.xcprivacy`.
- [ ] Complete App Privacy Nutrition Label in App Store Connect.
- [ ] Provide accessible Privacy Policy URL and Terms URL.
- [ ] Confirm export compliance answers in App Store Connect.
- [ ] Provide support URL and contact email.
- [ ] Confirm age rating and content declarations.

## 7) Testing and Quality Gates

- [ ] Run Flutter static checks and tests.
- [ ] Add backend API smoke/integration tests for core routes.
- [ ] Run staging end-to-end checks for auth, listings, chat, and profile.
- [ ] Validate rollback path and runbook.

## 8) Documentation and Operations

- [ ] Keep README feature status aligned with real code.
- [ ] Maintain release checklist and incident runbook.
- [ ] Document on-call/owner for production issues.
- [ ] Record known risks and post-release verification steps.
