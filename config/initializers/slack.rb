config_path = ::Rails.root.join("config", "slack.yml")
config_yaml = ::YAML.load_file(config_path)
config = config_yaml[::Rails.env]

::SlackNotifier = Slack::Notifier.new config["slack_webhook"]
