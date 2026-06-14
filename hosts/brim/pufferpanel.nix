{
  pkgs,
  ...
}:
{
  services.pufferpanel = {
    enable = true;
    extraPackages = with pkgs; [
      javaWrappers.java8
      javaWrappers.java17
      javaWrappers.java21
      javaWrappers.java25
    ];

    environment = {
      PUFFER_WEB_HOST = ":8080";
      PUFFER_PANEL_REGISTRATIONENABLED = "false";
      PUFFER_DAEMON_SFTP_HOST = ":5657";
      PUFFER_DAEMON_CONSOLE_BUFFER = "1000";
    };
  };
}
