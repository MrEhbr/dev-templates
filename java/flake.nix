{
  description = "A Nix-flake-based Java development environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs:
    let
      javaVersion = 25; # Change this value to update the whole stack
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      flake.overlays.default =
        final: prev:
        let
          jdk = prev."jdk${toString javaVersion}";
        in
        {
          inherit jdk;
          maven = prev.maven.override { jdk_headless = jdk; };
          gradle = prev.gradle.override { java = jdk; };
          lombok = prev.lombok.override { inherit jdk; };
        };

      perSystem =
        { system, pkgs, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.self.overlays.default ];
          };

          devShells.default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              gcc
              gradle
              jdk
              maven
              ncurses
              patchelf
              zlib
            ];

            shellHook =
              let
                loadLombok = "-javaagent:${pkgs.lombok}/share/java/lombok.jar";
                prev = "\${JAVA_TOOL_OPTIONS:+ $JAVA_TOOL_OPTIONS}";
              in
              ''
                export JAVA_TOOL_OPTIONS="${loadLombok}${prev}"
              '';
          };
        };
    };
}
