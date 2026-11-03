# macOS Workstation Deployment (`macbook-air-m4-15`)

[← Back to README](../../README.md)

The MacBook Air M4 runs macOS (`aarch64-darwin`) managed declaratively using [`nix-darwin`](https://github.com/LnL7/nix-darwin) and Home Manager. It shares user environments, dotfiles, editor settings, and client SSH profiles with `desktop-pc`:

- **Shared Capabilities**: Fish shell, Starship prompt, system & Git aliases, Neovim/LazyVim (`dotfiles/nvim`), VS Code extensions & settings, WezTerm & Ghostty terminal configurations, FiraCode Nerd Font, OpenCode v2 (with Nord theme, declarative AI skills from Matt Pocock & Addy Osmani, and `nodejs` / `uv` package runners), core CLI utilities (`eza`, `bat`, `yazi`, `btop`, `ripgrep`, `just`, `direnv`, etc.), and client SSH configuration targeting `homelab`.
- **Platform Separation**: Linux desktop compositors (Niri, Noctalia, Greetd, PipeWire, Nvidia) and homelab server daemons (Caddy, Jellyfin, AdGuard, etc.) remain strictly isolated to their native hosts.

---

## Initial Provisioning (First-Time Bootstrap on a Fresh Mac)

Follow these steps when setting up the MacBook Air M4 for the very first time:

### 1. Install Command Line Tools & Nix

Open Terminal and install the Apple Developer Command Line Tools if not already present:

```sh
xcode-select --install
```

Install Nix with Flakes enabled (recommended via the [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer)):

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### 2. Initialize `/etc/synthetic.conf` (Mandatory for `/run`)

On modern macOS, the root filesystem (`/`) is an APFS sealed system volume mounted in read-only mode. Apple provides `/etc/synthetic.conf` to declare synthetic virtual mount points and symlinks at root. `nix-darwin` requires `/run -> private/var/run` to host `/run/current-system`.

If `/etc/synthetic.conf` does not exist on a fresh Mac, `nix-darwin`'s activation script will fail with `stat: cannot stat '/etc/synthetic.conf': No such file or directory` and `chmod: cannot access '/etc/synthetic.conf'`. Create and initialize it beforehand:

**Bash**:

```bash
# Create /etc/synthetic.conf with the tab-separated /run mapping (the \t is required):
printf 'run\tprivate/var/run\n' | sudo tee /etc/synthetic.conf
sudo chmod 644 /etc/synthetic.conf
sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t
```

**Fish**:

```fish
# Create /etc/synthetic.conf with the tab-separated /run mapping (the \t is required):
printf 'run\tprivate/var/run\n' | sudo tee /etc/synthetic.conf
sudo chmod 644 /etc/synthetic.conf
sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t
```

*Verification*:

```sh
ls -la /run
# Expected output: lrwxr-xr-x ... /run -> private/var/run
```

*(Note: If `apfs.util -t` does not create the symlink immediately on your macOS version, restart your Mac once so APFS processes `/etc/synthetic.conf` during early boot).*

### 3. Initial `nix-darwin` Bootstrap & System Activation

Clone this repository, navigate into it, and perform the initial activation:

**Bash**:

```bash
git clone https://github.com/lvaylet/my-nixos-configurations.git
cd my-nixos-configurations
nix run nix-darwin -- switch --flake .#macbook-air-m4-15
```

**Fish**:

```fish
git clone https://github.com/lvaylet/my-nixos-configurations.git
cd my-nixos-configurations
nix run nix-darwin -- switch --flake .#macbook-air-m4-15
```

---

## Routine Maintenance & Daily Operations

For day-to-day configuration adjustments, testing, and system switches on macOS (when run on `macbook-air-m4-15`, `just` automatically selects `macbook-air-m4-15`):

- **`just build`**: Compiles the configuration closure in the Nix store without activating or touching the running system (validates syntax, types, and package builds).
- **`just test`**: Compiles and **activates** the configuration in the live session with `sudo` without recording a new profile generation in `/nix/var/nix/profiles/system` (direct equivalent of `nixos-rebuild test`).
- **`just switch`**: Compiles, commits a new profile generation in `/nix/var/nix/profiles/system`, and activates the live system with `sudo`.
- **Rollback**: In case an issue occurs after a switch, instantly revert to the previous generation with `sudo darwin-rebuild --rollback`.

**Bash**:

```bash
# 1. Compile only (no activation):
just build

# 2. Test and activate live without saving a new generation profile:
just test

# 3. Permanently switch and record a new generation:
just switch
# Or using nix-darwin directly:
sudo nix run nix-darwin -- switch --flake .#macbook-air-m4-15

# Rollback to the previous generation if needed:
sudo darwin-rebuild --rollback

# Update flake dependencies:
just up
```

**Fish**:

```fish
# 1. Compile only (no activation):
just build

# 2. Test and activate live without saving a new generation profile:
just test

# 3. Permanently switch and record a new generation:
just switch
# Or using nix-darwin directly:
sudo nix run nix-darwin -- switch --flake .#macbook-air-m4-15

# Rollback to the previous generation if needed:
sudo darwin-rebuild --rollback

# Update flake dependencies:
just up
```

---

## Client Access to Homelab Services

From the MacBook Air (or any device authenticated to the private tailnet), you can immediately access homelab infrastructure:

- **Tailscale SSH (Dynamic Keyless Access)**: Connect from any tailnet-authenticated machine via `tailscale ssh laurent@homelab` (or `ssh laurent@100.127.199.88`) using Tailscale identity and ACLs (`modules/services/tailscale.nix` with `extraSetFlags = ["--ssh"]`). No static SSH key generation, repository commit, or `homelab` rebuild is required when onboarding a new device.
- **Physical LAN SSH Shortcut (OpenSSH Fallback)**: Run `ssh homelab` on the local network to connect directly to `192.168.1.180` with your user account and static key (configured via shared `services.ssh`).
- **Tailscale Web Services**: When connected to Tailscale, access all internal applications directly in your browser (e.g. `https://ha.homelab.vaylet.fr`, `https://n8n.homelab.vaylet.fr`, `https://uptime.homelab.vaylet.fr`).

---

[← Back to README](../../README.md)
