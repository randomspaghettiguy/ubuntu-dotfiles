{ config, pkgs, lib, user, ... }:

let
  # Where the live config files are read from. bootstrap.sh / rebuild.sh create
  # ~/.dotfiles as a symlink to wherever you actually cloned the repo, so this
  # stays the same on every machine no matter your directory layout, e.g.
  #   ~/.dotfiles -> ~/github/randomspaghettiguy/dotfiles
  # Prefer no indirection? Put the real path here instead and delete the
  # `ln -sfn` line from both scripts:
  #   dotfiles = "${config.home.homeDirectory}/github/randomspaghettiguy/dotfiles";
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = user;
  home.homeDirectory = "/home/${user}"; # /Users on macOS, /home on Linux
  home.stateVersion = "26.05";

  # Lets home-manager manage itself, so `home-manager` stays on PATH.
  programs.home-manager.enable = true;

  # THE non-NixOS line. On Ubuntu this is what makes nix-installed fonts,
  # .desktop launchers, man pages and locales actually visible to the system.
  # nix-darwin had no equivalent because macOS needs none.
  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    # cli i use constantly (identical to the macOS config)
    ripgrep # fast search
    fd # fast find
    fzf # fuzzy finder
    jq # json on the command line
    lazygit
    neovim

    # the font everything renders in
    nerd-fonts.hack

    # ── Linux-only additions ───────────────────────────────────────────────
    # nvim sets clipboard=unnamedplus. macOS has pbcopy built in; Linux needs
    # a helper. Install both and nvim picks whichever session you're in.
    wl-clipboard # Wayland (Ubuntu 22.04+ default session)
    xclip # X11 / Xorg session

    # ── Were Homebrew casks/brews on macOS; nixpkgs has Linux builds ────────
    wezterm
    claude-code
    # "herdr" was a Homebrew formula with no nixpkgs Linux build - dropped.
    # If you want it, install it outside nix.
  ];

  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  # ── Shell ────────────────────────────────────────────────────────────────
  # The video uses zsh. You said bash, so this is the bash translation.
  # ble.sh gives bash the two things zsh had: ghost-text autosuggestions
  # from history, and syntax highlighting that greens valid commands.
  programs.bash = {
    enable = true;
    enableCompletion = true;

    # bashrcExtra runs EARLY in ~/.bashrc. ble.sh must be sourced before
    # anything else touches the prompt, hence not initExtra.
    bashrcExtra = ''
      [[ $- == *i* ]] && source ${pkgs.blesh}/share/blesh/ble.sh --noattach
    '';

    # initExtra runs LAST. ble.sh must attach after the prompt is set up.
    initExtra = ''
      [[ ''${BLE_VERSION-} ]] && ble-attach
    '';

    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      # Heads-up, these are the upstream author's high-agency shortcuts:
      # they skip permission prompts. Know what they do before using them.
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true; # Ctrl-R history search, Ctrl-T file picker
  };

  # Identical to the macOS config - starship is cross-platform.
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # ── Desktop settings: the replacement for configuration.nix ──────────────
  # The video's `system.defaults` block is nix-darwin's macOS-only feature.
  # On Ubuntu the same idea is dconf/gsettings, and home-manager can write it
  # declaratively. This is GNOME-specific (Ubuntu's default desktop); on KDE
  # or a headless box it just does nothing. Delete the block if you'd rather
  # keep using the Settings app.
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark"; # AppleInterfaceStyle = "Dark"
      show-battery-percentage = true;
    };
    "org/gnome/desktop/peripherals/keyboard" = {
      # KeyRepeat = 2 / InitialKeyRepeat = 15, in milliseconds
      repeat-interval = lib.hm.gvariant.mkUint32 20; # fast key repeat
      delay = lib.hm.gvariant.mkUint32 200; # short delay before repeat
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true; # trackpad.Clicking = true
    };
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-fixed = false; # dock.autohide = true
      autohide = true;
      intellihide = true;
    };
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view"; # finder.FXPreferredViewStyle = "Nlsv"
    };
    "org/gnome/shell/extensions/ding" = {
      show-home = false; # finder.CreateDesktop = false (clean desktop)
      show-trash = false;
    };
  };
  # Note: "AppleShowAllExtensions" has no Ubuntu equivalent - GNOME always
  # shows file extensions.

  # ── Edit-in-place symlinks ───────────────────────────────────────────────
  # The real files stay in this repo; ~/.config just points at them, so
  # editing home/.config/nvim/... takes effect immediately with no rebuild.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";

  # ── Deliberately NOT enabled ─────────────────────────────────────────────
  # home/AGENTS.md is the upstream author's personal agent policy. Cloning
  # his repo would silently give it to your Claude/Codex/opencode. Write your
  # own first, then uncomment:
  #
  # home.file.".claude/CLAUDE.md".source =
  #   config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  # home.file.".codex/AGENTS.md".source =
  #   config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  # home.file.".config/opencode/AGENTS.md".source =
  #   config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  #
  # The .pi/ and .config/herdr symlinks are macOS-tooling specific - skipped.
}
