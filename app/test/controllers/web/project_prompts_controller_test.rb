require "test_helper"

module Web
  class ProjectPromptsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:owner)
      @workspace = workspaces(:demo)
      @project = projects(:playground)
      sign_in @user
    end

    test "new renders the prompt form" do
      get new_workspace_project_prompt_path(@workspace.slug, @project.slug)
      assert_response :success
      assert_select "form"
      assert_select "input[name='prompt[slug]']"
      assert_select "textarea[name='prompt[content]']"
    end

    test "create builds the prompt and v1" do
      assert_difference -> { @project.prompts.count } do
        assert_difference -> { PromptVersion.count } do
          post workspace_project_prompts_path(@workspace.slug, @project.slug), params: {
            prompt: {
              slug: "ticket-classifier",
              description: "Classifies support tickets",
              content: "Classify the following ticket into one of {categories}.",
              model_hint: "gpt-4o-mini"
            }
          }
        end
      end

      created = @project.prompts.find_by!(slug: "ticket-classifier")
      assert_redirected_to workspace_web_prompt_path(@workspace.slug, created.slug)

      v1 = created.prompt_versions.order(:version_number).first
      assert_equal 1, v1.version_number
      assert_equal "dev", v1.environment
      assert_equal "ui", v1.created_via
      assert_equal @user, v1.created_by
      assert_equal [ { "name" => "categories" } ], v1.variables
    end

    test "create re-renders the form on invalid slug" do
      post workspace_project_prompts_path(@workspace.slug, @project.slug), params: {
        prompt: { slug: "Bad Slug!", description: "x", content: "hi" }
      }
      assert_response :unprocessable_entity
      assert_match(/only allows lowercase/i, flash.now[:alert])
    end
  end
end
