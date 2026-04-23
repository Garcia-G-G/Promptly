require "test_helper"

module Web
  class LogsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:owner)
      @workspace = workspaces(:demo)
      @prompt = prompts(:doc_summarizer)
      @prompt_version = prompt_versions(:doc_summarizer_production)
      @project = projects(:playground)
      sign_in @user
    end

    test "index renders with stats row even when empty" do
      get workspace_web_logs_path(@workspace.slug)
      assert_response :success
      assert_select ".stat-grid"
      assert_select ".filter-bar"
    end

    test "index renders logs when present" do
      log = build_log!
      get workspace_web_logs_path(@workspace.slug)
      assert_response :success
      assert_select ".data-table"
      assert_select "code", text: @prompt.slug
    ensure
      log&.destroy
    end

    test "index applies prompt filter" do
      get workspace_web_logs_path(@workspace.slug, prompt_id: @prompt.id)
      assert_response :success
    end

    test "index applies date range filter" do
      get workspace_web_logs_path(@workspace.slug, from: 7.days.ago.to_date.to_s, to: Date.today.to_s)
      assert_response :success
    end

    test "index applies score filter" do
      get workspace_web_logs_path(@workspace.slug, min_score: "0.5", max_score: "1.0")
      assert_response :success
    end

    test "index applies has_experiment filter" do
      get workspace_web_logs_path(@workspace.slug, has_experiment: "1")
      assert_response :success
    end

    test "index supports pagination" do
      get workspace_web_logs_path(@workspace.slug, page: 2)
      assert_response :success
    end

    test "show displays log detail" do
      log = build_log!(input_vars: { "language" => "es" })
      get workspace_web_log_path(@workspace.slug, log)
      assert_response :success
      assert_select "h1", text: log.request_id
    ensure
      log&.destroy
    end

    private

    def build_log!(overrides = {})
      Log.create!({
        project: @project,
        prompt: @prompt,
        prompt_version: @prompt_version,
        request_id: SecureRandom.uuid,
        output: "Sample response text for the log detail test.",
        input_vars: {},
        latency_ms: 42,
        score: 0.75,
        model_version: "gpt-4o"
      }.merge(overrides))
    end
  end
end
