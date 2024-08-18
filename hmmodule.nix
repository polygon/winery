{ self }:
({ config, lib, pkgs, ... }:

  with lib;

  let
    cfg = config.winery;
    opt = options.winery;
  in {
    opt.enable = mkEnableOption "Winery";

    config = mkIf cfg.enable {
      # Config here
    };
  })
