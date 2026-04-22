require "test_helper"

module Web
  class EvalRunsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:owner)
      @workspace = workspaces(:demo)
      @project = projects(:playground)
      @version = prompt_versions(:doc_summarizer_production)
      @dataset = datasets(:summarizer_cases)
      @scorer = scorers(:default_quality)
      sign_in @user
    end

    test "index shows empty state when none" do
      EvalRun.destroy_all
      get workspace_web_eval_runs_path(@workspace.slug)
      assert_response :success
      assert_match "No eval runs yet", response.body
    end

    test "index lists eval runs" do
      run = create_eval_run(status: :done, aggregate_score: 0.85, pass_rate: 1.0)
      get workspace_web_eval_runs_path(@workspace.slug)
      assert_response :success
      assert_match "##{run.id}", response.body
      assert_match "0.85", response.body
    ensure
      run&.destroy
    end

    test "index filters by status" do
      create_eval_run(status: :done)
      create_eval_run(status: :queued)
      get workspace_web_eval_runs_path(@workspace.slug, status: "done")
      assert_response :success
    end

    test "show renders detail for completed run" do
      run = create_eval_run(
        status: :done, aggregate_score: 0.75, pass_rate: 1.0,
        started_at: 5.minutes.ago, finished_at: Time.current,
        total_rows: @dataset.dataset_rows.count, scored_rows: @dataset.dataset_rows.count
      )
      @dataset.dataset_rows.each do |row|
        EvalRunResult.create!(
          eval_run: run, dataset_row: row,
          output: "sample output", score: 0.8, score_rationale: "ok", latency_ms: 42
        )
      end

      get workspace_web_eval_run_path(@workspace.slug, run)
      assert_response :success
      assert_match "Eval Run ##{run.id}", response.body
      assert_match "0.750", response.body
    ensure
      run&.destroy
    end

    test "show injects meta refresh while running" do
      run = create_eval_run(status: :running, total_rows: 2, started_at: Time.current)
      get workspace_web_eval_run_path(@workspace.slug, run)
      assert_response :success
      assert_match 'http-equiv="refresh"', response.body
    ensure
      run&.destroy
    end

    test "new renders form with selectors" do
      get new_workspace_web_eval_run_path(@workspace.slug)
      assert_response :success
      assert_select "select[name='eval_run[prompt_version_id]']"
      assert_select "select[name='eval_run[dataset_id]']"
      assert_select "select[name='eval_run[scorer_id]']"
      assert_select "input[type='range'][name='eval_run[pass_threshold]']"
    end

    test "create enqueues eval run" do
      assert_difference -> { EvalRun.count } do
        post workspace_web_eval_runs_path(@workspace.slug), params: {
          eval_run: {
            prompt_version_id: @version.id,
            dataset_id: @dataset.id,
            scorer_id: @scorer.id,
            pass_threshold: 0.7
          }
        }
      end
      created = EvalRun.order(:id).last
      assert_in_delta 0.7, created.pass_threshold.to_f, 0.0001
      assert_redirected_to workspace_web_eval_run_path(@workspace.slug, created)
    end

    private

    def create_eval_run(attrs)
      EvalRun.create!({
        prompt_version: @version,
        dataset: @dataset,
        scorer: @scorer,
        pass_threshold: 0.6,
        total_rows: 0,
        scored_rows: 0
      }.merge(attrs))
    end
  end
end
