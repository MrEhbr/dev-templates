{
  description = "Ready-made templates for easily creating flake-driven environments";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { config, pkgs, ... }:
        let
          getSystem = "SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')";
          forEachDir = exec: ''
            shopt -s nullglob

            for manifest in */flake.nix */*/flake.nix; do
              dir=$(dirname "''${manifest}")
              (
                cd "''${dir}"

                ${exec}
              )
            done
          '';

          script =
            name: runtimeInputs: text:
            pkgs.writeShellApplication {
              inherit name runtimeInputs text;
              bashOptions = [
                "errexit"
                "pipefail"
              ];
            };

          dvt = pkgs.writeShellApplication {
            name = "dvt";
            bashOptions = [
              "errexit"
              "pipefail"
            ];
            text = ''
              if [ -z "''${1}" ]; then
                echo "no template specified"
                exit 1
              fi

              TEMPLATE=$1

              nix \
                --experimental-features 'nix-command flakes' \
                flake init \
                --template \
                "github:MrEhbr/dev-templates#''${TEMPLATE}"
            '';
          };
        in
        {
          formatter = pkgs.nixfmt;

          packages = {
            inherit dvt;
            default = dvt;
          };

          devShells.default = pkgs.mkShellNoCC {
            packages =
              with pkgs;
              [
                (script "build" [ ] ''
                  ${getSystem}

                  ${forEachDir ''
                    echo "building ''${dir}"
                    nix build ".#devShells.''${SYSTEM}.default"
                  ''}
                '')
                (script "check" [ nixfmt ] (forEachDir ''
                  echo "checking ''${dir}"
                  nix flake check --all-systems --no-build
                ''))
                (script "format" [ nixfmt ] ''
                  git ls-files '*.nix' | xargs nix fmt
                '')
                (script "check-formatting" [ nixfmt ] ''
                  git ls-files '*.nix' | xargs nixfmt --check
                '')
              ]
              ++ [ config.formatter ];
          };
        };

      flake.templates = {
        go = {
          path = ./go;
          description = "Go (Golang) development environment";
        };

        java = {
          path = ./java;
          description = "Java development environment";
        };

        js = {
          path = ./js;
          description = "Javascript development environment";
        };

        php = {
          path = ./php;
          description = "PHP development environment";
        };

        python = {
          path = ./python;
          description = "Python development environment";
        };

        rust = {
          path = ./rust;
          description = "Rust development environment";
        };

        flutter = {
          path = ./flutter;
          description = "Flutter development environment";
        };

        zig = {
          path = ./zig;
          description = "Zig development environment";
        };

      };
    };
}
