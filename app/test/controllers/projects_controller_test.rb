require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    @workspace = workspaces(:demo)
    @project = projects(:playground)
    sign_in @user
  end

  test "show renders the project with its prompts" do
    get workspace_project_path(@workspace.slug, @project.slug)
    assert_response :success
    assert_select "h1", @project.name
    assert_select ".data-table"
  end

  test "create persists a new project" do
    assert_difference -> { @workspace.projects.count } do
      post workspace_projects_path(@workspace.slug), params: {
        project: { name: "New Project", slug: "new-project" }
      }
    end
    assert_redirected_to workspace_project_path(@workspace.slug, "new-project")
  end
end
