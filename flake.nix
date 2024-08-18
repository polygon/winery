{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {

      packages.${system} = {
        winery = pkgs.callPackage ./winery.nix { username = "jan"; };
        mount_prefix = pkgs.callPackage ./mount_prefix.nix {
          wineprefix = self.packages.${system}.winery;
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = [ pkgs.fuse-overlayfs pkgs.xorg.xorgserver ];
      };

      hmmodule = import ./hmmodule.nix { inherit self; };

      nixosConfigurations.test = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          home-manager.nixosModules.home-manager
          {
            users.users.audio = {
              isNormalUser = true;
              initialPassword = "1234";
              extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
              linger = true;
            };
            users.users.root.initialPassword = "1234";
            i18n.defaultLocale = "en_US.UTF-8";
            console.keyMap = "de";
            security.sudo.wheelNeedsPassword = false;
          }
          {
            home-manager.users.audio = ({ config, lib, ... }: {
              home.stateVersion = "24.05";
              home.username = lib.mkForce "audio";
              home.homeDirectory = "/home/audio";
              systemd.user.tmpfiles.rules =
                [ "d ${config.home.homeDirectory}/winery - - - - -" ];
              systemd.user.services.winery = {
                Unit = {
                  Description = "Mount winery";
                  After = [ "basic.target" ];
                };
                Install = { WantedBy = [ "default.target" ]; };
                Service = {
                  RuntimeDirectory = "winery";
                  ExecStart = "${
                      self.packages.${system}.mount_prefix
                    }/bin/mount_prefix ${config.home.homeDirectory}/winery";
                  RemainAfterExit = "yes";
                };
              };

            });
          }
        ];
      };

    };
}
