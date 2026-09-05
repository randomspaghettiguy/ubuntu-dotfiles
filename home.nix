{ config, pkgs, lib, user, ... }:

let
  # bootstrap.sh / rebuild.sh symlink ~/.dotfiles to wherever you cloned the
  # repo, so this stays the same regardless of your directory layout.
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "26.05";

  # NOTE: no `targets.genericLinux.enable` here. That option exists to make
  # home-manager work on NON-NixOS distros (Ubuntu, Fedora). On NixOS it is
  # wrong and can cause double-set environment variables.

  home.packages = with pkgs; [
    # cli i use constantly (same list as the video)
    ripgrep # fast search
    fd # fast find
    fzf # fuzzy finder
    jq # json on the command line
    lazygit
    neovim

    claude-code

    # WSLg exposes the Windows clipboard through Wayland, which is what makes
    # nvim's `clipboard=unnamedplus` copy to Windows. If it misbehaves, the
    # classic fallback is win32yank.
    wl-clipboard
  ];

  # No wezterm and no nerd font here, deliberately: WezTerm runs on Windows
  # and renders with Windows-installed fonts. A Linux wezterm inside WSL would
  # need WSLg and would be slower and blurrier for no benefit.

  home.sessionVariables.EDITOR = "nvim";

  # ─── Shell ───────────────────────────────────────────────────────────────
  # The video uses zsh; this is the bash translation. ble.sh gives bash the two
  # zsh features shown: history autosuggestions and syntax highlighting.
  programs.bash = {
    enable = true;
    enableCompletion = true;

    # bashrcExtra runs EARLY in ~/.bashrc - ble.sh must load before anything
    # else touches the prompt.
    bashrcExtra = ''
      [[ $- == *i* ]] && source ${pkgs.blesh}/share/blesh/ble.sh --noattach
    '';

    # initExtra runs LAST - ble.sh attaches after the prompt is set up.
    initExtra = ''
      [[ ''${BLE_VERSION-} ]] && ble-attach
    '';

    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      # Rebuild shortcuts - the NixOS equivalents of the video's darwin-rebuild.
      rebuild = "sudo nixos-rebuild switch --flake ${dotfiles}#${config.home.username}";
      # Heads-up: these two skip permission prompts. Know what they do.
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true; # Ctrl-R history, Ctrl-T files
  };

  # Identical to the video's config - starship is cross-platform.
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

  # ─── Edit-in-place symlinks ──────────────────────────────────────────────
  # The real files stay in the repo; ~/.config points at them, so editing
  # home/.config/nvim/... takes effect immediately with no rebuild.
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";

  # The wezterm config is NOT linked here - WezTerm runs on Windows and reads
  # C:\Users\thinh\.wezterm.lua. Keep that file in the repo under windows/
  # and copy it across; see README.

  # ─── Deliberately NOT enabled ────────────────────────────────────────────
  # home/AGENTS.md is the upstream author's personal agent policy. Write your
  # own before uncommenting these.
  #
  # home.file.".claude/CLAUDE.md".source =
  #   config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  # home.file.".codex/AGENTS.md".source =
  #   config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
