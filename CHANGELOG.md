# Changelog

All notable changes per release. Versions follow [semver](https://semver.org).

## v2.0.10 — 2026-07-27

Add agent integration manifests.

- Added `.agents/.claude-plugin/plugin.json` and `.agents/.codex-plugin/plugin.json` so the existing `.agents/skills/mediaproc` skill installs natively as a plugin in Claude Code and Codex.
- Added a README "Agent integrations" section with the install commands for Claude Code, Codex, and OpenClaw.

## v2.0.9 — 2026-07-27

- Added a GitHub Actions CI status badge to the README.

## v2.0.8 — 2026-07-27

Add README status badges.

- Added self-hosted version and license badges (rendered as SVGs on the `badges` branch by the `create-badges` CI job, no third-party render service) plus a Docker Hub pulls badge. Wired a badges job into pipeline.yml.
