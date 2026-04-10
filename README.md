# nixpkg-claude-agent-acp

Nix packaging for `@agentclientprotocol/claude-agent-acp` using Bun and `bun2nix`.

## Package

- Upstream package: `@agentclientprotocol/claude-agent-acp`
- Pinned version: `0.26.0`
- Installed binary: `claude-agent-acp`
- Upstream executable invoked by Bun: `claude-agent-acp`

## What This Repo Does

- Uses `bun.lock` and generated `bun.nix` as the dependency lock surface for Nix
- Builds the upstream package as an internal Bun application with `bun2nix`
- Exposes only the canonical binary name `claude-agent-acp`
- Provides a manifest sync script for updating the pinned npm metadata

## Files

- `flake.nix`: flake entrypoint
- `nix/package.nix`: Nix derivation
- `nix/package-manifest.json`: pinned package metadata and exposed binary name
- `scripts/sync-from-npm.ts`: updates pinned npm metadata without changing the canonical output binary

## Notes

- The default `out` output installs the canonical binary name `claude-agent-acp`.
