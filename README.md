Nix Darwin
==========

This repository contains darwin system configuration deployed using the helpful tool [nix-darwin].
The containing `configuration.nix` file must be deployed to `~/.config/nixpkgs/nix-darwin`. The default location is actually `~/.nixpkgs/darwin-configuration.nix`, this means that the initial invocation of `darwin-rebuild` needs the path to the configuration.

```
darwin-rebuild switch -I "darwin-config=$HOME/.config/nixpkgs/nix-darwin/configuration.nix"
```

[nix-darwin]:                 https://github.com/LnL7/nix-darwin