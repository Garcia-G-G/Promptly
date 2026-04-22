require "test_helper"

module Web
  class ScorersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:owner)
      @workspace = workspaces(:demo)
      @project = projects(:playground)
      @scorer = scorers(:default_quality)
      sign_in @user
    end

    test "index lists scorers" do
      get workspace_web_scorers_path(@workspace.slug)
      assert_response :success
      assert_match @scorer.name, response.body
      assert_select ".type-badge"
    end

    test "index shows empty state when none" do
      Scorer.destroy_all
      get workspace_web_scorers_path(@workspace.slug)
      assert_response :success
      assert_match "No scorers configured", response.body
    end

    test "new renders the type selector" do
      get new_workspace_web_scorer_path(@workspace.slug)
      assert_response :success
      assert_select "input[type='radio'][name='scorer[scorer_type]']", minimum: 4
    end

    test "create persists exact_match scorer without content" do
      assert_difference -> { Scorer.count } do
        post workspace_web_scorers_path(@workspace.slug), params: {
          scorer: {
            project_id: @project.id,
            name: "exact-#{SecureRandom.hex(3)}",
            scorer_type: "exact_match"
          }
        }
      end
      created = Scorer.order(:id).last
      assert_equal "exact_match", created.scorer_type
      assert_redirected_to workspace_web_scorers_path(@workspace.slug)
    end

    test "create llm_judge with content" do
      post workspace_web_scorers_path(@workspace.slug), params: {
        scorer: {
          project_id: @project.id,
          name: "judge-#{SecureRandom.hex(3)}",
          scorer_type: "llm_judge",
          content: "Score the output."
        }
      }
      created = Scorer.order(:id).last
      assert_equal "llm_judge", created.scorer_type
      assert_equal "Score the output.", created.content
    end

    test "edit renders form" do
      get edit_workspace_web_scorer_path(@workspace.slug, @scorer)
      assert_response :success
      assert_match @scorer.name, response.body
    end

    test "update bumps version when content changes" do
      initial = @scorer.version_number
      patch workspace_web_scorer_path(@workspace.slug, @scorer), params: {
        scorer: { content: "Updated judge prompt" }
      }
      assert_equal initial + 1, @scorer.reload.version_number
      assert_equal "Updated judge prompt", @scorer.content
    end

    test "update without content change does not bump version" do
      initial = @scorer.version_number
      patch workspace_web_scorer_path(@workspace.slug, @scorer), params: {
        scorer: { name: @scorer.name }
      }
      assert_equal initial, @scorer.reload.version_number
    end

    test "deactivate scorer" do
      patch workspace_web_scorer_path(@workspace.slug, @scorer), params: {
        scorer: { active: "0" }
      }
      refute @scorer.reload.active?
    end
  end
end
