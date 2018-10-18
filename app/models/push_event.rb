class PushEvent
  MAX_PUSH_EVENT_COMMITS = 20

  attr_reader :branch,
    :commits,
    :commit_count,
    :before,
    :after,
    :project_base_path,
    :project_id,
    :project_name,
    :project_namespace,
    :pusher_name

  def initialize(params)
    @branch = params[:ref].split("/").try(:last)
    @project_id = params[:project][:id]
    @project_name = params[:project][:name]
    @project_namespace = params[:project][:namespace]
    @project_base_path = params[:project][:web_url]
    @pusher_name = params[:user_name]
    @commits = params[:commits] || []
    @commit_count = params[:total_commits_count]
    @before = params[:before]
    @after = params[:after]
  end

  def to_h
    instance_variables.each_with_object({}) { |var, hash| hash[var.to_s.delete("@").to_sym] = instance_variable_get(var) }
  end

  def branch_url
    "#{project_base_path}/tree/#{branch}"
  end

  def passed_audit?
    ignore? || (unapproved_commits.empty? && !too_many_commits?)
  end

  def too_many_commits?
    commit_count > MAX_PUSH_EVENT_COMMITS
  end

  def unapproved_commits
    @unapproved_commits ||= commits
      .reject { |commit_data| Watchman::Configuration.skip_commit?(commit_data) }
      .map { |commit_data| Commit.new(project_id, commit_data["id"], commit_data["message"]) }
      .reject { |commit| commit_belongs_to_approved_mr?(commit) || commit_identical_to_any_approved_mr?(commit) }
  end

  private

  def ignore?
    !::Watchman::Configuration.should_audit?(self)
  end

  def get_commit_merge_request(commit)
    merge_request = commit_sha_merge_request_map[commit.sha]
  end

  def commit_belongs_to_approved_mr?(commit)
    merge_request = get_commit_merge_request(commit)
    Rails.logger.info "#{commit.sha} belongs to approved MR #{merge_request.id}" if merge_request.try(:is_approved?)

    merge_request.try(:is_approved?)
  end

  def commit_identical_to_any_approved_mr?(commit)
    commit_sha_merge_request_map.values.any? do |merge_request|
      Rails.logger.info "#{commit.sha} identical to approved MR #{merge_request.id}" if merge_request.is_approved? && merge_request.diff_identical?(commit.diff)
      merge_request.is_approved? && merge_request.diff_identical?(commit.diff)
    end
  end

  def commit_sha_merge_request_map
    @commit_sha_merge_request_map ||= begin
      commit_sha_merge_request_map = {}
      ::Gitlab.client.merge_requests(project_id, :state => "merged").each do |merge_request_data|
        merge_request = MergeRequest.from_api_data(project_id, merge_request_data)

        # Add the commit sha to the map
        commit_sha_merge_request_map[merge_request.merge_commit_sha] = merge_request

        # Add the original commits to the map
        commits = ::Gitlab.client.merge_request_commits(project_id, merge_request.id)
        commit_sha_merge_request_map.merge! Hash[commits.collect { |commit| [commit.id, merge_request] }]
      end

      commit_sha_merge_request_map
    end
  end
end
