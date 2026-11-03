# orca-bin

Nix flake and derivation for **Orca IDE** ([getorca.dev](https://getorca.dev) / [onorca.dev](https://onorca.dev) / [stablyai/orca](https://github.com/stablyai/orca)), the AI orchestrator for running parallel coding agents (Claude Code, Codex, OpenCode, Grok, Gemini, Pi) isolated in dedicated git worktrees.

Packaged using `appimageTools.wrapType2` to provide a complete, sandboxed FHS runtime with all required Wayland, X11, OpenGL, and audio dependencies on NixOS.

---

## Quick Start

### 1. Run Directly with Flakes
```bash
# Run without installing
nix run github:kdx/orca-bin

# Or run from local clone
nix run .#
```

### 2. Build Locally
```bash
git clone https://github.com/kdx/orca-bin.git
cd orca-bin
nix build .#
./result/bin/orca-ide
```

---

## Integration on NixOS

### NixOS Configuration (`configuration.nix`)

#### Option A: Using Flakes
Add `orca-bin` to your system flake inputs:
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    orca-bin.url = "github:kdx/orca-bin";
  };

  outputs = { self, nixpkgs, orca-bin, ... }: {
    nixosConfigurations.myhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          environment.systemPackages = [
            orca-bin.packages.x86_64-linux.default
          ];
        }
      ];
    };
  };
}
```

#### Option B: Traditional Nix (`default.nix`)
```nix
environment.systemPackages = [
  (pkgs.callPackage /path/to/orca-bin/default.nix { })
];
```

### Home Manager
```nix
{ pkgs, ... }: {
  home.packages = [
    (pkgs.callPackage /path/to/orca-bin/default.nix { })
  ];
}
```

---

## How It Works

1. **Parallel Git Worktree Isolation**:
   Orca isolates every agent task inside its own `git worktree` so concurrent agents do not collide, overwrite uncommitted changes, or corrupt lockfiles.
2. **Process & PTY Supervision**:
   Child agent processes run under pseudo-terminals (`node-pty`) and render via `@xterm/xterm` (with WebGL acceleration).
3. **Agent Client Protocol (ACP)**:
   Orca communicates with structured agent protocols (Claude, OpenCode, OMP, Grok) via dialect adapters alongside raw terminal streams.
4. **Daemon Architecture (`orcad`)**:
   Includes a headless daemon for running agent workloads remotely over SSH or on beefy server boxes.

---

## Versions & Automated Updates

The version and upstream AppImage hash are tracked declaratively in `versions.json`:

```json
{
  "version": "1.4.247",
  "hash": "sha256-bX36EpK54vcehFlHRqpgvr4oFqcxRaTSAV8o0rkZW28="
}
```

### Updating to the Latest Release

You can check and update `versions.json` automatically using the update script or flake app:

```bash
# Using nix run
nix run .#update

# Or directly via the script
./update.sh

# Force re-download and re-hash even if version matches:
./update.sh --force
```

### CI / CD (GitHub Actions)

A GitHub Actions workflow (`.github/workflows/build.yml`) is configured to:
- **Build & verify** on every `push` and `pull_request` to the `main` branch.
- **Auto-check upstream releases every 3 days** via cron (`0 0 */3 * *`). When upstream publishes a new release, CI automatically fetches the latest binary, computes the SRI hash, updates `versions.json`, verifies the Nix build, and commits back to `main`.

---

## High-Performance Low-Level Alternatives

While Orca provides a feature-rich graphical environment (Monaco diff editor, embedded browsers, mobile companion), it is an Electron app with higher baseline resource usage (~1.5–3 GB RAM) and single-threaded IPC bottlenecks during massive terminal output.

If you prefer lightweight, low-level alternatives built in **Rust** or **C++**:

| Tool | Language | UI | Idle RAM | Key Highlights |
| :--- | :--- | :--- | :--- | :--- |
| **[orcatui](https://github.com/lhjnano/orcatui)** | **Rust** | Terminal UI (`ratatui`) | ~25 MB | **1:1 Rust TUI port of Orca GUI**. Runs 20 agents @ 60fps in split panes, direct PTY control via `portable-pty` + `vt100`, connects to `orcad` or runs standalone. |
| **[wtcc](https://github.com/isorensen/wtcc)** | **Rust** | Terminal UI (`ratatui`) | ~20 MB | WorkTree Command Center (Linux reimplementation of macOS Supacode) for running Claude Code and CLI agents across worktrees. |
| **[Zed](https://zed.dev)** | **Rust** | Native GPU GUI (`GPUI`) | ~90 MB | GPU-accelerated code editor with built-in Agent Client Protocol (ACP), terminal splits, and git worktree navigation. |
| **[Zellij](https://zellij.dev)** | **Rust** | Terminal Multiplexer | ~15 MB | Pure Rust terminal workspace multiplexer; can be paired with worktree shell scripts for lightweight session management. |

---

## License

MIT
