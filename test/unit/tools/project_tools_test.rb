require File.expand_path("../../../test_helper", __FILE__)

class ProjectToolsTest < ActiveSupport::TestCase
  fixtures :projects, :projects_trackers, :trackers, :users, :repositories, :changesets, :changes, :issues, :issue_statuses, :enumerations, :issue_categories, :trackers

  def setup
    @provider = RedmineAiHelper::Tools::ProjectTools.new
    enabled_module = EnabledModule.new
    enabled_module.project_id = 1
    enabled_module.name = "ai_helper"
    enabled_module.save!
    User.current = User.find(1)
  end

  def test_list_projects
    enabled_module = EnabledModule.new
    enabled_module.project_id = 2
    enabled_module.name = "ai_helper"
    enabled_module.save!

    response = @provider.list_projects()
    assert_equal 2, response.size
    project1 = Project.find(1)
    project2 = Project.find(2)
    [project1, project2].each_with_index do |project, index|
      value = response[index]
      assert_equal project.id, value[:id]
      assert_equal project.name, value[:name]
    end
  end

  def test_read_project_by_id
    project = Project.find(1)

    response = @provider.read_project(project_id: project.id)
    assert_equal project.id, response[:id]
    assert_equal project.name, response[:name]
  end

  def test_read_project_by_name
    project = Project.find(1)

    response = @provider.read_project(project_name: project.name)
    assert_equal project.id, response[:id]
    assert_equal project.name, response[:name]
  end

  def test_read_project_by_identifier
    project = Project.find(1)

    response = @provider.read_project(project_identifier: project.identifier)
    assert_equal project.id, response[:id]
    assert_equal project.name, response[:name]
  end

  def test_read_project_not_found
    assert_raises(RuntimeError, "Project not found") do
      @provider.read_project(project_id: 999)
    end
  end

  def test_read_project_no_args
    assert_raises(RuntimeError, "No id or name or Identifier specified.") do
      @provider.read_project
    end
  end

  def test_project_members
    project = Project.find(1)
    members = project.members

    response = @provider.project_members(project_ids: [project.id])
    assert_equal members.size, response[:projects][0][:members].size
    assert_equal members.first.user_id, response[:projects][0][:members].first[:user_id]
  end

  def test_project_enabled_modules
    project = Project.find(1)
    enabled_modules = project.enabled_modules

    response = @provider.project_enabled_modules(project_id: project.id)
    assert_equal enabled_modules.size, response[:enabled_modules].size
    assert_equal enabled_modules.first.name, response[:enabled_modules].first[:name]
  end

  def test_list_project_activities
    assert_nothing_raised do
      project = Project.find(1)
      @provider.list_project_activities(project_id: project.id)

      author = User.find(1)
      @provider.list_project_activities(project_id: project.id, author_id: author.id)
    end
  end

  def test_project_members_with_multiple_projects
    project1 = Project.find(1)
    project2 = Project.find(2)

    # Enable AI helper for project2
    enabled_module = EnabledModule.new
    enabled_module.project_id = project2.id
    enabled_module.name = "ai_helper"
    enabled_module.save!

    response = @provider.project_members(project_ids: [project1.id, project2.id])
    assert_equal 2, response[:projects].size
    assert response[:projects].all? { |p| p.key?(:members) }
  end

  def test_project_members_with_invalid_project_id
    response = @provider.project_members(project_ids: [999])
    assert_equal "error", response.status
  end

  def test_project_enabled_modules_with_invalid_project_id
    assert_raises(ActiveRecord::RecordNotFound) do
      @provider.project_enabled_modules(project_id: 999)
    end
  end

  def test_list_project_activities_with_date_range
    project = Project.find(1)

    response = @provider.list_project_activities(project_id: project.id)

    assert_equal "success", response.status
    assert response.value.key?(:activities)
  end

  def test_list_project_activities_with_invalid_project_id
    assert_raises(ActiveRecord::RecordNotFound) do
      @provider.list_project_activities(project_id: 999)
    end
  end

  def test_list_project_activities_with_invalid_author_id
    project = Project.find(1)

    assert_raises(ActiveRecord::RecordNotFound) do
      @provider.list_project_activities(project_id: project.id, author_id: 999)
    end
  end

  def test_list_projects_includes_required_fields
    response = @provider.list_projects()

    response.each do |project_data|
      assert project_data.key?(:id)
      assert project_data.key?(:name)
    end
  end

  def test_read_project_includes_detailed_information
    project = Project.find(1)

    response = @provider.read_project(project_id: project.id)

    assert_equal project.id, response[:id]
    assert_equal project.name, response[:name]
  end

  def test_project_members_includes_member_details
    project = Project.find(1)

    response = @provider.project_members(project_ids: [project.id])
    project_data = response[:projects].first

    assert project_data.key?(:members)
    assert project_data[:members].is_a?(Array)
  end

  def test_read_project_without_permission
    project = Project.find(1)
    User.current = User.find(6) # User without permission

    assert_raises(RuntimeError, "You don't have permission to view this project") do
      @provider.read_project(project_id: project.id)
    end
  end

  def test_read_project_with_subprojects
    project = Project.find(1)

    response = @provider.read_project(project_id: project.id)

    assert response.key?(:subprojects)
    assert response[:subprojects].is_a?(Array)
  end

  def test_project_members_permission_check
    project = Project.find(1)
    User.current = User.find(6) # User without permission

    response = @provider.project_members(project_ids: [project.id])
    # When user has no permission, accessible projects are filtered out, resulting in empty list
    assert_equal [], response[:projects]
  end

  def test_project_enabled_modules_permission_check
    project = Project.find(1)
    User.current = User.find(6) # User without permission

    result = @provider.project_enabled_modules(project_id: project.id)
    assert result.is_a?(RedmineAiHelper::ToolResponse)
    assert_equal "error", result.status
    assert_equal "You don't have permission to view this project", result.error
  end

  def test_list_project_activities_permission_check
    project = Project.find(1)
    User.current = User.find(6) # User without permission

    result = @provider.list_project_activities(project_id: project.id)
    assert result.is_a?(RedmineAiHelper::ToolResponse)
    assert_equal "error", result.status
    assert_equal "You don't have permission to view this project", result.error
  end

  def test_get_metrics
    project = Project.find(1)

    metrics = @provider.get_metrics(project_id: project.id)

    assert metrics.key?(:project_info)
    assert metrics.key?(:period)
    assert metrics.key?(:issue_statistics)
    assert metrics.key?(:timing_metrics)
    assert metrics.key?(:workload_metrics)
    assert metrics.key?(:quality_metrics)
    assert metrics.key?(:progress_metrics)
    assert metrics.key?(:member_metrics)

    # Test project_info structure
    project_info = metrics[:project_info]
    assert_equal project.id, project_info[:id]
    assert_equal project.name, project_info[:name]
    assert_equal project.identifier, project_info[:identifier]

    # Test issue_statistics structure
    issue_stats = metrics[:issue_statistics]
    assert issue_stats.key?(:total_issues)
    assert issue_stats.key?(:open_issues)
    assert issue_stats.key?(:closed_issues)
    assert issue_stats.key?(:by_priority)
    assert issue_stats.key?(:by_tracker)
    assert issue_stats.key?(:by_status)
    assert issue_stats.key?(:by_assigned_to)
    assert issue_stats.key?(:by_author)
  end

  def test_get_metrics_with_version_filter
    project = Project.find(1)
    version = project.versions.first

    metrics = @provider.get_metrics(project_id: project.id, version_id: version.id)

    assert_equal version.id, metrics[:period][:version_id]
  end

  def test_get_metrics_with_date_range
    project = Project.find(1)
    start_date = "2025-01-01"
    end_date = "2025-12-31"

    metrics = @provider.get_metrics(
      project_id: project.id,
      start_date: start_date,
      end_date: end_date,
    )

    assert_equal Date.parse(start_date), metrics[:period][:start_date]
    assert_equal Date.parse(end_date), metrics[:period][:end_date]
  end

  def test_get_metrics_invalid_project
    assert_raises(ActiveRecord::RecordNotFound) do
      @provider.get_metrics(project_id: 999)
    end
  end

  def test_get_metrics_without_permission
    project = Project.find(1)
    User.current = User.find(6) # User without permission

    assert_raises(RuntimeError, "You don't have permission to view this project") do
      @provider.get_metrics(project_id: project.id)
    end
  end

  def test_get_metrics_timing_metrics_structure
    project = Project.find(1)

    metrics = @provider.get_metrics(project_id: project.id)
    timing_metrics = metrics[:timing_metrics]

    assert timing_metrics.key?(:average_resolution_time_days)
    assert timing_metrics.key?(:median_resolution_time_days)
    assert timing_metrics.key?(:min_resolution_time_days)
    assert timing_metrics.key?(:max_resolution_time_days)
    assert timing_metrics.key?(:overdue_issues_count)
    assert timing_metrics.key?(:issues_with_due_date)
    assert timing_metrics.key?(:resolution_time_distribution)
  end

  def test_get_metrics_workload_metrics_structure
    project = Project.find(1)

    metrics = @provider.get_metrics(project_id: project.id)
    workload_metrics = metrics[:workload_metrics]

    assert workload_metrics.key?(:total_estimated_hours)
    assert workload_metrics.key?(:total_spent_hours)
    assert workload_metrics.key?(:estimation_accuracy)
    assert workload_metrics.key?(:issues_with_estimates)
    assert workload_metrics.key?(:issues_with_time_entries)
    assert workload_metrics.key?(:estimated_vs_actual_details)
    assert workload_metrics.key?(:average_estimation_variance)
  end

  def test_get_metrics_quality_metrics_structure
    project = Project.find(1)

    metrics = @provider.get_metrics(project_id: project.id)
    quality_metrics = metrics[:quality_metrics]

    assert quality_metrics.key?(:by_tracker)
    assert quality_metrics.key?(:tracker_ratios)
    assert quality_metrics.key?(:reopened_issues_count)
    assert quality_metrics.key?(:reopened_ratio)
  end

  def test_get_metrics_progress_metrics_structure
    project = Project.find(1)

    metrics = @provider.get_metrics(project_id: project.id)
    progress_metrics = metrics[:progress_metrics]

    assert progress_metrics.key?(:average_completion_percentage)
    assert progress_metrics.key?(:issues_with_progress)
    assert progress_metrics.key?(:completion_distribution)

    completion_dist = progress_metrics[:completion_distribution]
    assert completion_dist.key?(:not_started)
    assert completion_dist.key?(:in_progress)
    assert completion_dist.key?(:completed)
  end

  def test_get_metrics_member_metrics_structure
    project = Project.find(1)

    metrics = @provider.get_metrics(project_id: project.id)
    member_metrics = metrics[:member_metrics]

    assert member_metrics.key?(:members_workload)
    assert member_metrics.key?(:unassigned_issues)
    assert member_metrics.key?(:total_active_members)
    assert member_metrics.key?(:workload_balance)

    if member_metrics[:members_workload].any?
      workload = member_metrics[:members_workload].first
      assert workload.key?(:user_name)
      assert workload.key?(:user_id)
      assert workload.key?(:assigned_issues)
      assert workload.key?(:average_progress)
    end

    workload_balance = member_metrics[:workload_balance]
    if workload_balance.is_a?(Hash)
      assert workload_balance.key?(:average_issues_per_member)
      assert workload_balance.key?(:workload_variance)
      assert workload_balance.key?(:max_workload)
      assert workload_balance.key?(:min_workload)
    end
  end

  def test_get_metrics_error_handling_invalid_date
    project = Project.find(1)

    assert_raises(Date::Error) do
      @provider.get_metrics(project_id: project.id, start_date: "invalid-date")
    end
  end

  def test_list_projects_with_dummy_parameter
    response = @provider.list_projects(dummy: "test")
    assert response.is_a?(Array)
    assert response.size >= 1
  end

  def test_read_project_finds_by_name
    project = Project.find(1)

    response = @provider.read_project(project_name: project.name)
    assert_equal project.id, response[:id]
    assert_equal project.name, response[:name]
  end

  def test_read_project_finds_by_identifier
    project = Project.find(1)

    response = @provider.read_project(project_identifier: project.identifier)
    assert_equal project.id, response[:id]
    assert_equal project.identifier, response[:identifier]
  end

  def test_read_project_not_found_by_name
    assert_raises(RuntimeError, "Project not found") do
      @provider.read_project(project_name: "nonexistent_project")
    end
  end

  def test_read_project_not_found_by_identifier
    assert_raises(RuntimeError, "Project not found") do
      @provider.read_project(project_identifier: "nonexistent_identifier")
    end
  end

  def test_list_project_activities_with_author
    project = Project.find(1)
    author = User.find(1)

    response = @provider.list_project_activities(project_id: project.id, author_id: author.id)

    assert_equal "success", response.status
    assert response.value.key?(:activities)
  end

  def test_list_project_activities_with_limit
    project = Project.find(1)

    response = @provider.list_project_activities(project_id: project.id, limit: 5)

    assert_equal "success", response.status
    activities = response.value[:activities]
    assert activities.size <= 5
  end

  def test_project_enabled_modules_structure
    project = Project.find(1)

    response = @provider.project_enabled_modules(project_id: project.id)

    assert_equal project.id, response[:project_id]
    assert response[:enabled_modules].is_a?(Array)

    if response[:enabled_modules].any?
      module_info = response[:enabled_modules].first
      assert module_info.key?(:name)
    end
  end
end
