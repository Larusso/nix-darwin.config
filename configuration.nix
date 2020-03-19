{ config, pkgs, ... }:

{
  imports = [ <home-manager/nix-darwin> ];
  home-manager.useUserPackages = true;
  home-manager.users.larusso = (import ../home.nix);
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ pkgs.zsh
      pkgs.vim
      pkgs.curl
      pkgs.git
      pkgs.gitAndTools.gh
      pkgs.git-crypt
      pkgs.fzf
      pkgs.shellcheck
      pkgs.openssl
      pkgs.coreutils
      # (import ./my-asdf.nix)
    ];

  system.defaults.NSGlobalDomain._HIHideMenuBar = true;
  system.defaults.dock.autohide = true;
  system.defaults.dock.mru-spaces = false;
  system.defaults.dock.orientation = "bottom";
  system.defaults.dock.showhidden = true;
  system.defaults.dock.show-process-indicators = true;
  system.defaults.dock.minimize-to-application = false;
  system.defaults.dock.tilesize = 34;
  system.defaults.dock.show-recents = true;
  system.defaults.dock.dashboard-in-overlay = true;

  system.defaults.finder.AppleShowAllExtensions = true;
  system.defaults.finder.QuitMenuItem = true;
  system.defaults.finder.FXEnableExtensionChangeWarning = false;

  system.defaults.trackpad.Clicking = true;
  system.defaults.trackpad.TrackpadThreeFingerDrag = true;
  
  security.sandbox.profiles.fetch-nixpkgs-updates.closure = [ pkgs.cacert pkgs.git ];
  security.sandbox.profiles.fetch-nixpkgs-updates.writablePaths = [ "/src/nixpkgs" ];
  security.sandbox.profiles.fetch-nixpkgs-updates.allowNetworking = true;

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  environment.darwinConfig = "$HOME/.config/nixpkgs/nix-darwin/configuration.nix";

  launchd.user.agents.fetch-nixpkgs-updates = {
    command = "/usr/bin/sandbox-exec -f ${config.security.sandbox.profiles.fetch-nixpkgs-updates.profile} ${pkgs.git}/bin/git -C /src/nixpkgs fetch origin master";
    environment.HOME = "";
    environment.NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    serviceConfig.KeepAlive = false;
    serviceConfig.ProcessType = "Background";
    serviceConfig.StartInterval = 360;
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  nix.binaryCachePublicKeys = [ "cache.daiderd.com-1:R8KOWZ8lDaLojqD+v9dzXAqGn29gEzPTTbr/GIpCTrI=" ];
  nix.trustedBinaryCaches = [ https://d3i7ezr9vxxsfy.cloudfront.net ];
  nix.trustedUsers = [ "@admin" ];

  nix.useSandbox = true;
  nix.sandboxPaths = [ "/System/Library/Frameworks" "/System/Library/PrivateFrameworks" "/usr/lib" "/private/tmp" "/private/var/tmp" "/usr/bin/env" ];

  programs.nix-index.enable = true;

  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;

  programs.tmux.enable = true;
  programs.tmux.enableSensible = true;
  programs.tmux.enableMouse = true;
  programs.tmux.enableFzf = true;
  programs.tmux.enableVim = true;

  programs.tmux.tmuxConfig = ''
    bind 0 set status
    bind S choose-session
    bind-key -r "<" swap-window -t -1
    bind-key -r ">" swap-window -t +1
    bind-key -n M-c run "tmux send-keys -t .+ C-\\\\ && tmux send-keys -t .+ C-a C-k C-l Up && tmux send-keys -t .+ Enter"
    bind-key -n M-r run "tmux send-keys -t .+ C-a C-k C-l Up && tmux send-keys -t .+ Enter"
    set -g pane-active-border-style fg=black
    set -g pane-border-style fg=black
    set -g status-bg black
    set -g status-fg white
    set -g status-right '#[fg=white]#(id -un)@#(hostname)   #(cat /run/current-system/darwin-version)'
  '';

  environment.etc."nix/user-sandbox.sb".text = ''
    (version 1)
    (allow default)
    (deny file-write*
          (subpath "/nix"))
    (allow file-write*
           (subpath "/nix/var/nix/gcroots/per-user")
           (subpath "/nix/var/nix/profiles/per-user"))
  '';

  programs.vim.package = pkgs.vim_configurable.customize {
    name = "vim";
    vimrcConfig.packages.darwin.start = with pkgs.vimPlugins; [
      vim-sensible vim-surround ReplaceWithRegister
      polyglot fzfWrapper YouCompleteMe ale
    ];
    vimrcConfig.packages.darwin.opt = with pkgs.vimPlugins; [
      colors-solarized
      splice-vim
    ];
    vimrcConfig.customRC = ''
      set completeopt=menuone
      set encoding=utf-8
      set hlsearch
      set list
      set number
      set showcmd
      set splitright
      nnoremap // :nohlsearch<CR>
      let mapleader = ' '
      " fzf
      nnoremap <Leader>p :FZF<CR>
      " vim-surround
      vmap s S
      " youcompleteme
      let g:ycm_seed_identifiers_with_syntax = 1
    '';
  };

  # Dotfiles.
  # programs.vim.package = mkForce pkgs.lnl.vim;
  programs.bash.enableCompletion = true;
  programs.zsh.enable = true;
  programs.zsh.enableBashCompletion = true;
  programs.zsh.enableFzfCompletion = true;
  programs.zsh.enableFzfGit = true;
  programs.zsh.enableFzfHistory = true;
  programs.zsh.enableSyntaxHighlighting = true;

  programs.zsh.variables.cfg = "$HOME/.config/nixpkgs/darwin/configuration.nix";
  programs.zsh.variables.darwin = "$HOME/.nix-defexpr/darwin";
  programs.zsh.variables.nixpkgs = "$HOME/.nix-defexpr/nixpkgs";

  programs.zsh.loginShellInit = ''
    :r() {
      gpg-connect-agent reloadagent /bye
    }
  '';

  environment.variables.LANG = "en_US.UTF-8";
  environment.variables.TERM = "xterm-256color";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # You should generally set this to the total number of logical cores in your system.
  # $ sysctl -n hw.ncpu
  nix.maxJobs = 4;
  nix.buildCores = 4;
}
