require "application_system_test_case"

class ScheduledPostsTest < ApplicationSystemTestCase
  setup do
    @scheduled_post = scheduled_posts(:one)
  end

  test "visiting the index" do
    visit scheduled_posts_url
    assert_selector "h1", text: "Scheduled Posts"
  end

  test "creating a Scheduled post" do
    visit scheduled_posts_url
    click_on "New Scheduled Post"

    click_on "Create Scheduled post"

    assert_text "Scheduled post was successfully created"
    click_on "Back"
  end

  test "updating a Scheduled post" do
    visit scheduled_posts_url
    click_on "Edit", match: :first

    click_on "Update Scheduled post"

    assert_text "Scheduled post was successfully updated"
    click_on "Back"
  end

  test "destroying a Scheduled post" do
    visit scheduled_posts_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Scheduled post was successfully destroyed"
  end
end
