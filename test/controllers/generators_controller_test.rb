require 'test_helper'

class GeneratorsControllerTest < ActionDispatch::IntegrationTest
  test "should get pdf" do
    get generators_pdf_url
    assert_response :success
  end

end
