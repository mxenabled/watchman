config_path = ::Rails.root.join("config", "gitlab.yml")
config_yaml = ::YAML.load_file(config_path)
config = config_yaml[::Rails.env]

::Gitlab.configure do |c|
  c.private_token = config["private_token"]
  c.endpoint = "https://gitlab.yourcompany.com/api/v4"
end
