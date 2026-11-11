{
  description = "Pimalaya packages hub";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            apt
            createrepo_c
            curl
            gh
            gnupg
            jq
            nfpm
            yq-go
          ];
        };
      });
    };
}
