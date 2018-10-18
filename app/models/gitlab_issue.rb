class GitlabIssue

  attr_reader :push_event

  def initialize(push_event)
    @push_event = push_event
  end

  def create!
    project = ::Gitlab.client.project(issue_project)
    new_issue = ::Gitlab.client.create_issue(project.id, title, :description => description, :labels => Watchman::Configuration.gitlab_issue_labels)
    new_issue.web_url
  end

  private

  def description
    template = File.open(path_to_template).read
    ERB.new(template, nil, "-").result(binding)
  end

  def issue_project
    Watchman::Configuration.gitlab_issue_project
  end

  def path_to_template
    Rails.root.join("app", "views", "gitlab_webhooks", "push_event.md.erb")
  end

  def title
    Watchman::Configuration.gitlab_issue_description % push_event.to_h
  end
end
