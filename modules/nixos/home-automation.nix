_: {
  services = {
    # Home Assistant
    home-assistant = {
      enable = true;
      extraComponents = [
        "default_config"
        "met"
        "esphome"
        "mqtt"
      ];
      config = {
        # Basic configuration
        homeassistant = {
          name = "Home";
          time_zone = "Europe/Paris";
          unit_system = "metric";
        };
        # Enable the frontend
        frontend = {};
      };
    };

    # MQTT Broker (Mosquitto)
    mosquitto = {
      enable = true;
      listeners = [
        {
          acl = [
            "pattern readwrite #"
          ];
          omitPasswordAuth = true; # For simplicity
          settings.allow_anonymous = true;
        }
      ];
    };

    # Zigbee2MQTT
    zigbee2mqtt = {
      enable = true;
      settings = {
        homeassistant = {
          enabled = true;
        };
        permit_join = false;
        mqtt = {
          base_topic = "zigbee2mqtt";
          server = "mqtt://localhost";
        };
        serial = {
          # port = "/dev/ttyUSB0"; # Adjust based on your Zigbee adapter
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    8123
    1883
  ];
}
