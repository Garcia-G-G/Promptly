require "test_helper"

class Api::V1::DatasetsControllerTest < ActionDispatch::IntegrationTest
  test "GET /datasets returns project list" do
    get api_v1_datasets_path, headers: api_headers
    assert_response :success
    assert_kind_of Array, response.parsed_body
  end

  test "POST /datasets creates dataset" do
    post api_v1_datasets_path,
      params: { name: "new-dataset", description: "Test" }.to_json,
      headers: api_headers
    assert_response :created
    assert_equal "new-dataset", response.parsed_body["name"]
  end

  test "GET /datasets/:id shows dataset with row count" do
    get api_v1_dataset_path(id: datasets(:summarizer_cases).id), headers: api_headers
    assert_response :success
    assert response.parsed_body["row_count"] >= 0
  end

  test "POST /datasets/:id/rows imports JSON rows" do
    ds = Dataset.create!(project: projects(:playground), name: "import-json-test")

    post rows_api_v1_dataset_path(id: ds.id),
      params: {
        rows: [
          { input_vars: { "lang" => "en" }, expected_output: "Hello" },
          { input_vars: { "lang" => "es" } }
        ]
      }.to_json,
      headers: api_headers
    assert_response :created
    assert_equal 2, response.parsed_body["imported"]
  end

  test "POST /datasets/:id/rows imports CSV" do
    ds = Dataset.create!(project: projects(:playground), name: "import-csv-test")

    csv_data = "language,length,_expected_output,_tags\nSpanish,3 bullets,A summary,core\nEnglish,1 paragraph,,edge\n"

    post rows_api_v1_dataset_path(id: ds.id),
      params: csv_data,
      headers: api_headers.merge("Content-Type" => "text/csv")
    assert_response :created
    assert_equal 2, response.parsed_body["imported"]
    assert_equal 2, ds.dataset_rows.count
  end

  test "DELETE /datasets/:id destroys dataset" do
    ds = Dataset.create!(project: projects(:playground), name: "delete-me")
    delete api_v1_dataset_path(id: ds.id), headers: api_headers
    assert_response :no_content
    assert_not Dataset.exists?(ds.id)
  end
end
