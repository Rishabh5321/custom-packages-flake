# ./seanime-home.nix
{ config, lib, pkgs, seanime, ... }:

let
  cfg = config.modules.home.services.seanime;
in
{
  options.modules.home.services.seanime = {
    enable = lib.mkEnableOption "seanime";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      seanime
      pkgs.mpv # Add mpv here
    ];

    systemd.user.services.seanime = {
      Unit = {
        Description = "Seanime WebServer";
        After = "network.service";
        X-SwitchMethod = "restart";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };

      Service = {
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 10"; # Add a 10-second delay
        ExecStart = "${seanime}/bin/seanime";
        Environment = "PATH=${pkgs.mpv}/bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin"; # Add mpv to PATH
      };
    };
  };
}
