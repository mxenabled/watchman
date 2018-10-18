Rails.application.routes.draw do
  post "/gitlab_webhooks", :to => "gitlab_webhooks#route"
end
