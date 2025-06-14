{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, flake-utils, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
          overlays = [ inputs.rust-overlay.overlays.default ];
        };

        makeToolchain = pkgs.rust-bin.selectLatestNightlyWith;

        targets = [ "thumbv6m-none-eabi" ];

        config = {
          release = toolchain: toolchain.minimal.override {
            inherit targets;
          };
          dev = toolchain: toolchain.default.override {
            inherit targets;
            extensions = [ "rust-src" "rust-analyzer" ];
          };
        };

        toolchain = builtins.mapAttrs (n: v: makeToolchain v) config;

        naersk' = pkgs.callPackage inputs.naersk {
          cargo = toolchain.release;
          rustc = toolchain.release;
        };
      in
      {
        # For `nix build` & `nix run`:
        defaultPackage = naersk'.buildPackage {
          src = ./.;
        };

        # For `nix develop` (optional, can be skipped):
        devShell = pkgs.mkShell {
          nativeBuildInputs = [ toolchain.dev ];
        };
      }
    );
}
