require 'test_helper'

class ListsManagementTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
    @archer = users(:archer)
  end

  test "create lists" do
  	log_in_as(@archer)
  	get show_lists_path(:id => @archer.id)
  	assert_not @archer.admin

  	assert_difference 'List.count', 1 do
      post submit_list_path, params: { list: { name: "Test List" }, :user_id => @archer.id }
    end

    #can't create a list for somebody else
    assert_no_difference 'List.count' do
      post submit_list_path, params: { list: { name: "Test List" }, :user_id => @user.id }
    end

    #name too long
    assert_no_difference 'List.count' do
      post submit_list_path, params: { list: { name: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent eget volutpat." }, :user_id => @archer.id }
    end

  end

end