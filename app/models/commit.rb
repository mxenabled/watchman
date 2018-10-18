class Commit
  attr_reader :project_id, :sha, :message

  def initialize(project_id, sha, message)
    @project_id = project_id
    @sha = sha
    @message = message
  end

  def diff
    @diff ||= ::Gitlab.client.commit_diff(project_id, sha).auto_paginate
  end
end
