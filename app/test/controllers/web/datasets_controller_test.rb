require "test_helper"

module Web
  class DatasetsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:owner)
      @workspace = workspaces(:demo)
      @project = projects(:playground)
      @dataset = datasets(:summarizer_cases)
      sign_in @user
    end

    test "index lists datasets" do
      get workspace_web_datasets_path(@workspace.slug)
      assert_response :success
      assert_match @dataset.name, response.body
    end

    test "index shows empty state when none visible" do
      Dataset.destroy_all
      get workspace_web_datasets_path(@workspace.slug)
      assert_response :success
      assert_match "No datasets yet", response.body
    end

    test "show renders rows" do
      get workspace_web_dataset_path(@workspace.slug, @dataset)
      assert_response :success
      assert_match @dataset.name, response.body
      assert_select ".data-table"
    end

    test "new renders form" do
      get new_workspace_web_dataset_path(@workspace.slug)
      assert_response :success
      assert_select "form"
      assert_match @project.name, response.body
    end

    test "create persists dataset" do
      assert_difference -> { Dataset.count } do
        post workspace_web_datasets_path(@workspace.slug), params: {
          dataset: {
            project_id: @project.id,
            name: "ticket-classification-#{SecureRandom.hex(3)}",
            description: "Tickets for classifier eval"
          }
        }
      end
      created = Dataset.order(:id).last
      assert_redirected_to workspace_web_dataset_path(@workspace.slug, created)
    end

    test "create with JSON rows imports them" do
      post workspace_web_datasets_path(@workspace.slug), params: {
        dataset: {
          project_id: @project.id,
          name: "json-import-#{SecureRandom.hex(3)}",
          description: "with rows",
          json_rows: '[{"input_vars": {"lang": "en"}, "expected_output": "hello"}]'
        }
      }
      created = Dataset.order(:id).last
      assert_equal 1, created.dataset_rows.count
      assert_equal "hello", created.dataset_rows.first.expected_output
    end

    test "destroy deletes dataset" do
      target = Datasets::Create.call(project: @project, name: "to-delete-#{SecureRandom.hex(3)}")
      assert_difference -> { Dataset.count }, -1 do
        delete workspace_web_dataset_path(@workspace.slug, target)
      end
      assert_redirected_to workspace_web_datasets_path(@workspace.slug)
    end

    test "import via JSON adds rows" do
      target = Datasets::Create.call(project: @project, name: "empty-#{SecureRandom.hex(3)}")
      assert_difference -> { target.dataset_rows.count }, 2 do
        post import_workspace_web_dataset_path(@workspace.slug, target), params: {
          json_rows: '[{"input_vars": {"a": "1"}}, {"input_vars": {"a": "2"}}]'
        }
      end
      assert_redirected_to workspace_web_dataset_path(@workspace.slug, target)
      follow_redirect!
      assert_match "2 rows imported", response.body
    end
  end
end
