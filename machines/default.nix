{
  self,
  inputs,
}: let
  # Helper function to create NixOS system configurations
  # Type: Path -> NixOS Configuration
  mkMachine = configuration:
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit self inputs;
      };
      modules = [configuration];
    };
in {
  webdade = mkMachine ./webdade.nix;
}
