{ config, lib, ... }: {
  age.secrets.factorio-server-settings = {
    file = ./factorio-server-settings.age;
    mode = "0444";
  };
}
