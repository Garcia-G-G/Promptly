require "test_helper"

module Web
  class PromptVersionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:owner)
      @workspace = workspaces(:demo)
      @prompt = prompts(:doc_summarizer)
      sign_in @user
    end

    test "new prefills the form with the latest version" do
      get new_workspace_web_prompt_version_path(@workspace.slug, @prompt.slug)
      assert_response :success
      latest = @prompt.prompt_versions.order(version_number: :desc).first
      assert_select "textarea[name='prompt_version[content]']", text: latest.content
    end

    test "create pushes a new dev version" do
      assert_difference -> { @prompt.prompt_versions.count } do
        post workspace_web_prompt_versions_path(@workspace.slug, @prompt.slug), params: {
          prompt_version: {
            content: "Updated content in {language} with {tone}.",
            model_hint: "claude-sonnet-4-6"
          }
        }
      end

      assert_redirected_to workspace_web_prompt_path(@workspace.slug, @prompt.slug)

      new_version = @prompt.prompt_versions.order(version_number: :desc).first
      assert_equal "dev", new_version.environment
      assert_equal "ui", new_version.created_via
      assert_equal @user, new_version.created_by
      assert_equal %w[language tone].sort, new_version.variables.map { |v| v["name"] }.sort
    end
  end
end
