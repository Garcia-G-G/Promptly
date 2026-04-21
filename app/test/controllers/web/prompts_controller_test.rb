require "test_helper"

module Web
  class PromptsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:owner)
      @workspace = workspaces(:demo)
      @prompt = prompts(:doc_summarizer)
      sign_in @user
    end

    test "index lists prompts" do
      get workspace_web_prompts_path(@workspace.slug)
      assert_response :success
      assert_select ".page-header h1", "Prompts"
    end

    test "show displays prompt detail with version history" do
      get workspace_web_prompt_path(@workspace.slug, @prompt.slug)
      assert_response :success
      assert_select "h1", @prompt.slug
      assert_select ".env-grid"
      assert_select ".data-table"
    end

    test "promote promotes a version to the target environment" do
      version = prompt_versions(:doc_summarizer_dev)
      post promote_workspace_web_prompt_path(@workspace.slug, @prompt.slug),
        params: { version_id: version.id, to_environment: "staging" }

      assert_redirected_to workspace_web_prompt_path(@workspace.slug, @prompt.slug)
      assert_match(/promoted to staging/i, flash[:notice])
      assert @prompt.prompt_versions.exists?(environment: "staging")
    end
  end
end
