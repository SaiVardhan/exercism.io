require_relative '../../integration_helper'
require 'app/helpers/session'
require 'app/helpers/site_title_helper'

class SiteTitleHelperTest < Minitest::Test

  def helper
    return @helper if @helper
    @helper = Object.new
    @helper.extend(Sinatra::SiteTitleHelper)
    @helper.extend(ExercismWeb::Helpers::Session)
  end

  def test_default_title
    assert_equal "exercism.io", helper.title
  end

  def test_title
    helper.stub(:title, "word-count") do
      assert_equal "word-count", helper.title
    end
  end
  
  # def test_source_types
  #   assert_equal %w(DB GITHUB),helper.source_types
  # end

 
  def test_account_source_options
    helper.stub(:current_user,User.new) do
    expected = "<option selected value='DB'>DB</option><option value='GITHUB'>GITHUB</option>"
    assert_equal expected,helper.account_source_options
  end

  end

  def test_account_source_options_with_github
    helper.stub(:current_user,User.new(:source_type => "GITHUB")) do
    expected = "<option value='DB'>DB</option><option selected value='GITHUB'>GITHUB</option>"
    assert_equal expected,helper.account_source_options
  end
end

end
