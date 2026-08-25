{
  description = "A Nix-flake-based development environment with Postgres and Redis";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs
    flake-parts.url = "github:hercules-ci/flake-parts";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [ inputs.process-compose-flake.flakeModule ];

      perSystem =
        { config, pkgs, ... }:
        {
          # nix run .# starts every enabled service under process-compose
          process-compose."default" = {
            imports = [ inputs.services-flake.processComposeModules.default ];

            services.postgres."pg" = {
              enable = true;
              initialDatabases = [ { name = "dev"; } ];
            };

            services.redis."redis".enable = true;
          };

          devShells.default = pkgs.mkShellNoCC {
            inputsFrom = [ config.process-compose."default".services.outputs.devShell ];
          };
        };
    };
}
