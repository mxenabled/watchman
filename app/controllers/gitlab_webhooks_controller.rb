class GitlabWebhooksController < ApplicationController

  def route
    case params[:event_name]
    when "push" 
      push_event
    else 
      unhandled
    end
  end

  private

  def push_event
    @push_event = PushEvent.new(params)
    create_gitlab_issue(@push_event) unless @push_event.passed_audit?
    render :plain => "Event #{@push_event.passed_audit? ? "passed" : "failed"} audit"
  end

  def unhandled
    head :no_content
  end

  def create_gitlab_issue(event)
    issue = GitlabIssue.new(event)
    @issue_url = issue.create!
  end
end
