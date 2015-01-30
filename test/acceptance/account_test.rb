require_relative '../acceptance_helper'

class AccountTest < AcceptanceTestCase
  def setup
    super
    @user = create_user
  end

  def test_account_page_exists
    with_login(@user) do
      click_on 'Account'
     # binding.pry  
      assert_css 'h1', text: 'Account'
      assert_content 'Exercises'
    end
  end

  def test_changing_email
    with_login(@user) do
      click_on 'Account'

      fill_in 'email', with: 'some@email.com'
      
      click_on 'Update'
      
      assert_content 'Updated email address.'
      assert_equal 'some@email.com', find('[name=email]').value
    end
  end

  def test_creating_a_team
    create_user(username: 'one_username', github_id: 12345,source_type: "DB")
    create_user(username: 'two_username', github_id: 4567,source_type: "GIT")

    with_login(@user) do
      click_on 'Account'
      require 'pry'
     #  binding.pry
      click_on 'new team'
      
      fill_in 'Slug', with: 'gocowboys'
      fill_in 'Name', with: 'Go Cowboys'
      fill_in 'Usernames', with: 'one_username, two_username'

      click_on 'Save'

      assert_equal '/teams/gocowboys', current_path
      assert_content 'Team Go Cowboys'
      assert_content 'one_username'
      assert_content 'two_username'
    end
  end
end
