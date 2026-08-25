{
  description = "A Nix-flake-based development environment with Postgres and Redis";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
  };

  outputs =
    { self, ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f rec {
            pkgs = import inputs.nixpkgs { inherit system; };
            services = (import inputs.process-compose-flake.lib { inherit pkgs; }).evalModules {
              modules = [
                inputs.services-flake.processComposeModules.default
                {
                  services.postgres."pg".enable = true;
                  services.postgres."pg".initialDatabases = [ { name = "dev"; } ];
                  services.redis."redis".enable = true;
                }
              ];
            };
          }
        );
    in
    {
      # nix run .# starts every enabled service under process-compose
      packages = forEachSupportedSystem (
        { services, ... }:
        {
          default = services.config.outputs.package;
        }
      );

      devShells = forEachSupportedSystem (
        { pkgs, services }:
        {
          default = pkgs.mkShellNoCC {
            inputsFrom = [ services.config.services.outputs.devShell ];
          };
        }
      );
    };
}
