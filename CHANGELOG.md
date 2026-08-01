# Changelog

All notable changes per release. Versions follow [semver](https://semver.org).

## v2.0.12 — 2026-08-01

CI plumbing only. No code in this repo changed — every commit in this release touches `.github/workflows/`.

- The pipeline was split: building and publishing stay in `pipeline.yml`, and everything that leaves the host now lives beside it in `mirror-and-archive.yml`.
- The repo is mirrored to Codeberg as well as GitLab.
- It is archived to the Wayback Machine, Software Heritage and archive.org.
- Issues opened on either mirror are copied back to GitHub every six hours, and closed here when the original closes.
- Pull requests are switched off on the mirrors — they are force-pushed from GitHub, so anything merged there would be destroyed by the next sync. Issues and forking stay enabled.

## v2.0.11 — 2026-07-27

Fix missing Codex install command in README.

- The README "Agent integrations" Codex subsection was missing the actual plugin install command after the marketplace-add step. Added `codex plugin add mediaproc@psyb0t`.
- Clarified the invocation prose: installed via the marketplace, the skill invokes as `$mediaproc:mediaproc`; picked up automatically (no install) from this repo's own `.agents/skills/` directory, it invokes as plain `$mediaproc`.

## v2.0.10 — 2026-07-27

Add agent integration manifests.

- Added `.agents/.claude-plugin/plugin.json` and `.agents/.codex-plugin/plugin.json` so the existing `.agents/skills/mediaproc` skill installs natively as a plugin in Claude Code and Codex.
- Added a README "Agent integrations" section with the install commands for Claude Code, Codex, and OpenClaw.

## v2.0.9 — 2026-07-27

- Added a GitHub Actions CI status badge to the README.

## v2.0.8 — 2026-07-27

Add README status badges.

- Added self-hosted version and license badges (rendered as SVGs on the `badges` branch by the `create-badges` CI job, no third-party render service) plus a Docker Hub pulls badge. Wired a badges job into pipeline.yml.
