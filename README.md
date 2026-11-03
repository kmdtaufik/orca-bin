# orca-bin

Nix flake and derivation for **Orca IDE** ([getorca.dev](https://getorca.dev) / [onorca.dev](https://onorca.dev) / [stablyai/orca](https://github.com/stablyai/orca)), the AI orchestrator for running parallel coding agents (Claude Code, Codex, OpenCode, Grok, Gemini, Pi) isolated in dedicated git worktrees.

Supports **`x86_64-linux`** and **`aarch64-linux`** using `appimageTools.wrapType2` to provide a complete, sandboxed FHS runtime with all required Wayland, X11, OpenGL, and audio dependencies on NixOS.

---

## Quick Start

### 1. Run Directly with Flakes
```bash
# Launch desktop GUI directly
nix run github:kdx/orca-bin

# Or run the CLI orchestrator directly
nix run github:kdx/orca-bin#cli -- --help

# From a local checkout:
nix run .#        # Desktop GUI
nix run .#cli     # CLI orchestrator
```

### 2. Build Locally
```bash
git clone https://github.com/kdx/orca-bin.git
cd orca-bin
nix build .#

# Dual entry points:
./result/bin/orca-ide-desktop   # Launches desktop GUI
./result/bin/orca-ide --help    # Runs CLI commands (worktrees, agents, terminals)
```

---

## Integration on NixOS

### Option A: Declarative NixOS Module (Recommended)

Add `orca-bin` to your flake inputs and import the module:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    orca-bin.url = "github:kdx/orca-bin";
    orca-bin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, orca-bin, ... }: {
    nixosConfigurations.myhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # or "aarch64-linux"
      modules = [
        orca-bin.nixosModules.default
        {
          programs.orca-ide = {
            enable = true;
            # Appends fallback git, openssh, and ripgrep via --suffix so user-installed tools win
            addDefaultDeps = true;
            # Optional: append additional packages to Orca's environment
            extraPackages = [ ];
          };
        }
      ];
    };
  };
}
```

### Option B: Home Manager Module

```nix
{
  imports = [ orca-bin.homeManagerModules.default ];

  programs.orca-ide = {
    enable = true;
    addDefaultDeps = true;
    extraPackages = with pkgs; [ nodejs ];
  };
}
```

### Option C: Package List / Traditional Nix

```nix
# Via flake package output:
environment.systemPackages = [
  orca-bin.packages.${pkgs.stdenv.hostPlatform.system}.default
];

# Or via traditional default.nix callPackage:
environment.systemPackages = [
  (pkgs.callPackage /path/to/orca-bin/default.nix {
    addDefaultDeps = true;
  })
];
```

---

## Agent Runtime Tooling & Zero Duplication

Orca relies on command-line utilities (`git`, `ssh`, `ripgrep`) to manage git worktrees and search code for AI agents.

- **Zero duplication by default (`addDefaultDeps = false`)**: Orca inherits your existing host/user `$PATH` without downloading extra copies.
- **Fallback injection (`addDefaultDeps = true`)**: Wraps Orca's launcher with `makeWrapper --suffix PATH : <deps>`. Using `--suffix` (not `--prefix`) guarantees that any tools in your existing `$PATH` always take precedence, while ensuring the runtime tools are reliably present.
- **Custom packages (`extraPackages = [ ... ]`)**: Supply any additional language runtimes or CLIs (e.g. `nodejs`, `python3`) directly into Orca's path.

---

## Architecture & Entry Points

| Entry Point | Target | Description |
| :--- | :--- | :--- |
| `orca-ide-desktop` | GUI App | Primary launcher for desktop environments, bound to `orca-ide.desktop`. |
| `orca-ide` | CLI Tool | Direct CLI interface for managing worktrees, agent sessions, and terminals. |

1. **Parallel Git Worktree Isolation**:
   Orca isolates every agent task inside its own `git worktree` so concurrent agents do not collide, overwrite uncommitted changes, or corrupt lockfiles.
2. **Process & PTY Supervision**:
   Child agent processes run under pseudo-terminals (`node-pty`) and render via `@xterm/xterm` (with WebGL acceleration).
3. **Agent Client Protocol (ACP)**:
   Orca communicates with structured agent protocols (Claude, OpenCode, OMP, Grok) via dialect adapters alongside raw terminal streams.
4. **Daemon Architecture (`orcad`)**:
   Includes a headless daemon for running agent workloads remotely over SSH or on beefy server boxes.

---

## Repository Structure

```
orca-bin/
├── pkgs/
│   └── orca-ide/              # Orca AppImage wrapper & derivation
│       ├── default.nix
│       └── versions.json      # Declarative multi-arch hashes
├── modules/
│   ├── nixos.nix              # NixOS module (programs.orca-ide)
│   └── home-manager.nix       # Home Manager module (programs.orca-ide)
├── checks/
│   └── smoke.nix              # Headless CLI & desktop verification
├── scripts/
│   └── update.sh              # Multi-arch prefetch & update automation
├── default.nix                # Root compatibility entrypoint
├── flake.nix                  # Flake entrypoint & module exports
└── README.md
```

---

## Versions & Automated Updates

Version and upstream AppImage hashes for all supported architectures are tracked declaratively in `pkgs/orca-ide/versions.json`:

```json
{
  "version": "1.4.247",
  "x86_64-linux": "sha256-bX36EpK54vcehFlHRqpgvr4oFqcxRaTSAV8o0rkZW28=",
  "aarch64-linux": "sha256-8HIUAbtQleK3j9BezSG2NVbCFu+gjSTb+SL2PIdGAag="
}
```

### Updating to the Latest Release

You can check and update `pkgs/orca-ide/versions.json` automatically using the update script or flake app:

```bash
# Using nix run
nix run .#update

# Or directly via the script
./scripts/update.sh

# Force re-download and re-hash even if version matches:
./scripts/update.sh --force
```

### CI / CD (GitHub Actions)

A GitHub Actions workflow (`.github/workflows/build.yml`) is configured to:
- **Build, check, & smoke test** on every `push` and `pull_request` to `main`:
  - Validates flake evaluation and checks (`nix flake check`).
  - Builds package output (`nix build .#default`).
  - Verifies executability of `orca-ide` and `orca-ide-desktop`.
  - Validates `orca-ide.desktop` standard compliance.
- **Auto-check upstream releases every 3 days** via cron (`0 0 */3 * *`). When upstream publishes a new release, CI automatically fetches both `x86_64-linux` and `aarch64-linux` binaries, computes SRI hashes, updates `pkgs/orca-ide/versions.json`, verifies the Nix build, and commits back to `main`.
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
