{
  description = "My HomeLab Infrastructure as Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    git-hooks.url = "github:cachix/git-hooks.nix";

    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;

      overlays = [
        # Unstable packages
        (_: _: {unstable = import nixpkgs-unstable {inherit system;};})
      ];
    };
  in {
    checks.${system} = {
      pre-commit-check = inputs.git-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          alejandra.enable = true;
          deadnix.enable = true;
          nil.enable = true;
          statix.enable = true;
        };
      };
    };

    nixosConfigurations = import ./machines {inherit self inputs;};

    devShells.${system}.default = pkgs.mkShell {
      inherit (self.checks.${system}.pre-commit-check) shellHook;

      buildInputs =
        self.checks.${system}.pre-commit-check.enabledPackages
        ++ [
          pkgs.nixos-rebuild
          pkgs.gitflow
        ];
    };

    formatter.${system} = pkgs.alejandra;
  };
}
