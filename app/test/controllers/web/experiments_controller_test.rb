require "test_helper"

module Web
  class ExperimentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:owner)
      @workspace = workspaces(:demo)
      @experiment = experiments(:tone_tweak)
      sign_in @user
    end

    test "index lists experiments" do
      get workspace_web_experiments_path(@workspace.slug)
      assert_response :success
      assert_select ".filter-tab", minimum: 4
    end

    test "index filters by status" do
      get workspace_web_experiments_path(@workspace.slug, status: "running")
      assert_response :success
    end

    test "show displays experiment detail" do
      get workspace_web_experiment_path(@workspace.slug, @experiment)
      assert_response :success
      assert_select "h1", @experiment.name
      assert_select ".variant-cards"
    end

    test "new renders the experiment form" do
      get new_workspace_web_experiment_path(@workspace.slug)
      assert_response :success
      assert_select "form"
      assert_select "select[name='experiment[prompt_id]']"
      assert_select "input[type=?][name='experiment[traffic_split]']", "range"
    end

    test "create creates a draft experiment" do
      prompt = prompts(:doc_summarizer)
      v_a = prompt_versions(:doc_summarizer_dev)
      v_b = prompt_versions(:doc_summarizer_production)

      assert_difference -> { Experiment.count } do
        post workspace_web_experiments_path(@workspace.slug), params: {
          experiment: {
            prompt_id: prompt.id,
            name: "dashboard-smoke-#{SecureRandom.hex(3)}",
            variant_a_version_id: v_a.id,
            variant_b_version_id: v_b.id,
            traffic_split: 50,
            environment: "dev"
          }
        }
      end

      created = Experiment.order(:id).last
      assert_redirected_to workspace_web_experiment_path(@workspace.slug, created)
      assert_equal "draft", created.status
    end

    test "start transitions draft to running" do
      post start_workspace_web_experiment_path(@workspace.slug, @experiment)
      assert_redirected_to workspace_web_experiment_path(@workspace.slug, @experiment)
      assert_equal "running", @experiment.reload.status
    end

    test "pause then resume round-trip" do
      Experiments::UpdateStatus.call(experiment: @experiment, status: :running)

      post pause_workspace_web_experiment_path(@workspace.slug, @experiment)
      assert_redirected_to workspace_web_experiment_path(@workspace.slug, @experiment)
      assert_equal "paused", @experiment.reload.status

      post resume_workspace_web_experiment_path(@workspace.slug, @experiment)
      assert_redirected_to workspace_web_experiment_path(@workspace.slug, @experiment)
      assert_equal "running", @experiment.reload.status
    end

    test "conclude concludes with a winner" do
      Experiments::UpdateStatus.call(experiment: @experiment, status: :running)
      post conclude_workspace_web_experiment_path(@workspace.slug, @experiment),
        params: { winner_version_id: @experiment.variant_a_version_id }

      assert_redirected_to workspace_web_experiment_path(@workspace.slug, @experiment)
      @experiment.reload
      assert_equal "concluded", @experiment.status
      assert_equal @experiment.variant_a_version_id, @experiment.winner_version_id
    end
  end
end
