config_path = ::Rails.root.join("config", "watchman.yml")
config_yaml = ::YAML.load_file(config_path)
config = config_yaml[::Rails.env]

::Watchman::Configuration.configure do |watchman|
  watchman.namespaces = config["namespaces"]
  watchman.projects   = config["projects"]
  watchman.rules      = config["rules"]
  watchman.alerts     = config["alerts"]
end
