<!--
Sync Impact Report
- Version change: (none) → 1.0.0
- Modified principles: N/A (initial ratification)
- Added sections: Core Principles (I–V), Project Constraints, Development Workflow, Governance
- Removed sections: none
- Follow-up TODOs: none
-->
# Shoplancer Vendor Constitution

## Core Principles

### I. Feature-First Architecture
All application code MUST live under `lib/features/<feature>/` following the
existing layered layout (`domain/`, controllers, `screens/`, `widgets/`). Shared
UI and helpers belong in `lib/common/` or `lib/helper/` only when reused by
multiple features. New features MUST NOT invent alternate folder conventions.

**Rationale**: Consistency keeps GetX wiring, navigation, and onboarding
predictable across the multivendor codebase.

### II. GetX State and Dependency Patterns
Controllers, bindings, and services MUST follow existing GetX patterns already
used in the repo. Prefer extending current controllers/services over introducing
parallel state-management libraries. Route registration MUST go through
`lib/helper/route_helper.dart` (or the established equivalent).

**Rationale**: Mixing state approaches increases maintenance cost and regressions.

### III. Localization Completeness
User-facing strings MUST use the localization keys under `assets/language/`
(at minimum `en.json` and `ar.json`; keep other locale files in sync when
touched). Hard-coded UI copy in Dart widgets is forbidden for production UI.

**Rationale**: The vendor app ships multilingual markets; missing keys break UX.

### IV. Minimal, Safe Diffs
Changes MUST be scoped to the requested feature or fix. Do NOT modify generated
artifacts, `.dart_tool/`, build caches, or unrelated screens. Avoid drive-by
refactors, speculative abstractions, and unrelated dependency bumps.

**Rationale**: Large incidental diffs hide bugs and slow review on a mature app.

### V. Cross-Platform Verification
Behavior-affecting changes MUST be considered for both iOS and Android (and
desktop/web targets when the touched code path applies). Prefer shared Flutter
APIs; platform-specific code MUST be isolated and justified.

**Rationale**: Shoplancer Vendor is a multi-platform Flutter product.

## Project Constraints

- Stack: Flutter (SDK per `pubspec.yaml`), GetX, Firebase messaging/core, HTTP API client under `lib/api/`.
- Do NOT commit secrets (`.env`, Firebase service-account JSON, credentials).
- Prefer existing widgets (`lib/common/widgets/`) before creating new ones.
- API and networking changes MUST preserve logging/error handling conventions in `lib/api/`.
- Spec Kit artifacts (`.specify/`, `.cursor/skills/`, feature specs) are part of the repo and MUST stay consistent with this constitution.

## Development Workflow

1. Establish or amend principles here before large multi-feature work.
2. Specify intent with `/speckit-specify` (what/why, not stack minutiae).
3. Plan with `/speckit-plan` using Flutter/GetX/API constraints above.
4. Break work with `/speckit-tasks`, then implement with `/speckit-implement`.
5. Use `/speckit-clarify`, `/speckit-checklist`, and `/speckit-analyze` as quality gates for production features.
6. Finish with `/speckit-converge` until gaps are closed or explicitly deferred.

## Governance

This constitution supersedes conflicting ad-hoc practices for Spec-Driven work
in this repository. Amendments MUST update this file, bump `CONSTITUTION_VERSION`
semantically (MAJOR for removals/redefinitions, MINOR for new principles,
PATCH for clarifications), and set `Last Amended` to the change date. PRs that
change architecture, localization, or platform behavior MUST be reviewable
against these principles. Complexity beyond the existing patterns MUST be
justified in the feature plan.

**Version**: 1.0.0 | **Ratified**: 2026-08-10 | **Last Amended**: 2026-08-10
