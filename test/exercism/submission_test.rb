require_relative '../integration_helper'
require "mocha/setup"

class SubmissionTest < Minitest::Test
  include DBCleaner

  def problem
    Problem.new('ruby', 'one')
  end

  def submission
    @submission ||= begin
      Submission.on(problem).tap do |submission|
        submission.user = User.create(username: 'charlie')
        submission.save
      end
    end
  end

  def create_submission
    Submission.create!(user: User.create!, slug: 'one')
  end

  def alice
    @alice ||= User.create(username: 'alice')
  end

  def fred
    @fred ||= User.create(username: 'fred')
  end

  def sai
   @sai ||= User.create(username: "SaiVardhan")
  end

  def teardown
    super
    @submission = nil
    @fred = nil
    @alice = nil
  end

  def test_random_submission_key
    submission = Submission.create(user: alice, slug: 'one')
    submission.reload
    refute_nil submission.key
  end

  def test_supersede_pending_submission
    assert_equal 'pending', submission.state
    submission.supersede!
    submission.reload
    assert_equal 'superseded', submission.state
  end

  def test_supersede_hibernating_submission
    submission.state = 'hibernating'
    submission.supersede!
    submission.reload
    assert_equal 'superseded', submission.state
  end

  def test_supersede_completed_submissions
    submission.state = 'done'
    submission.done_at = Time.now
    submission.save
    submission.supersede!
    assert_equal 'superseded', submission.state
    assert_nil   submission.done_at
  end

  def test_like_sets_is_liked
    submission = Submission.new(state: 'pending')
    submission.like!(alice)
    assert submission.is_liked = true
  end

  def test_like_sets_liked_by
    submission = Submission.create(state: 'pending', user: alice, slug: 'one')
    submission.like!(fred)
    assert_equal [fred], submission.liked_by
  end

  def test_like_calls_mute
    submission = Submission.create(state: 'pending', user: alice, slug: 'one')
    submission.expects(:mute).with(fred)
    submission.like!(fred)
  end

  def test_unlike_resets_is_liked_if_liked_by_is_empty
    submission = Submission.create(state: 'pending', user: alice, slug: 'one')
    Like.create(submission: submission, user: fred)
    submission.unlike!(fred)
    refute submission.is_liked
  end

  def test_unlike_does_not_reset_is_liked_if_liked_by_is_not_empty
    bob = User.create(username: 'bob')
    submission = Submission.create(state: 'pending', user: alice, slug: 'one')
    Like.create(submission: submission, user: bob)
    Like.create(submission: submission, user: fred)
    submission.unlike!(bob)
    assert submission.is_liked
  end

  def test_unlike_changes_liked_by
    submission = Submission.create(state: 'pending', user: alice, slug: 'one')
    Like.create(submission: submission, user: fred)
    submission.unlike!(fred)
    assert_equal [], submission.liked_by
  end

  def test_unlike_calls_unmute
    submission = Submission.create(state: 'pending', user: alice, slug: 'one')
    submission.expects(:unmute).with(fred)
    submission.unlike!(fred)
  end

  def test_liked_reflects_positive_is_liked
    submission = Submission.new(is_liked: true)
    assert submission.liked?
  end

  def test_liked_reflects_negative_is_liked
    submission = Submission.new(is_liked: false)
    refute submission.liked?
  end

  def test_muted_by_when_muted
    submission = Submission.create(user: fred, state: 'pending', slug: 'one')
    submission.mute! alice
    assert submission.muted_by?(alice)
  end

  def test_unmuted_for_when_muted
    submission.mute(submission.user)
    submission.save
    refute(Submission.unmuted_for(submission.user).include?(submission),
           "unmuted_for should only return submissions that have not been muted")
  end

  def test_muted_by_when_not_muted
    submission = Submission.new(state: 'pending')
    refute submission.muted_by?(alice)
  end

  def test_submissions_with_no_views
    assert_empty submission.viewers
    assert_equal 0, submission.view_count
  end

  def test_viewed_submission
    alice = User.create(username: 'alice')
    bob = User.create(username: 'bob')
    charlie = User.create(username: 'charlie')
    submission.viewed!(alice)
    submission.viewed!(bob)
    submission.viewed!(charlie)
    submission.viewed!(bob)
    submission.reload

    assert_equal %w(alice bob charlie), submission.viewers.map(&:username)
    assert_equal 3, submission.view_count
  end

  def test_viewing_submission_twice_is_fine
    alice = User.create(username: 'alice')
    submission.viewed!(alice)
    submission.viewed!(alice)
    assert_equal 1, submission.view_count
    assert_equal %w(alice), submission.viewers.map(&:username)
  end

  def test_viewing_with_increase_in_viewers
    alice = User.create(username: 'alice')
    bob = User.create(username: 'bob')
    submission.viewed!(alice)
    assert_equal 1, submission.view_count
    submission.viewed!(bob)
    assert_equal 2, submission.view_count
  end

  def test_comments_are_sorted
    submission.comments << Comment.new(body: 'second', created_at: Time.now, user: submission.user)
    submission.comments << Comment.new(body: 'first', created_at: Time.now - 1000, user: submission.user)
    submission.save

    one, two = submission.comments
    assert_equal 'first', one.body
    assert_equal 'second', two.body
  end

  def test_aging_submissions
    # not old
    s1 = Submission.create(user: alice, state: 'pending', created_at: 20.days.ago, nit_count: 1, slug: 'one')
    # no nits
    s2 = Submission.create(user: alice, state: 'pending', created_at: 22.days.ago, nit_count: 0, slug: 'one')
    # not pending
    s3 = Submission.create(user: alice, state: 'completed', created_at: 22.days.ago, nit_count: 1, slug: 'one')
    # Meets criteria: old, pending, and with nits
    s4 = Submission.create(user: alice, state: 'pending', created_at: 22.days.ago, nit_count: 1, slug: 'one')

    # Guard clause.
    # All the expected submissions got created
    assert_equal 4, Submission.count

    ids = Submission.aging.map(&:id)
    assert_equal [s4.id], ids
  end

  def test_not_commented_on_by
    user = User.create!
    commented_on_by_user = create_submission
    Comment.create!(submission: commented_on_by_user, user: user, body: 'test')

    commented_on_by_someone_else = create_submission
    Comment.create!(submission: commented_on_by_someone_else, user: User.create!, body: 'test')

    not_commented_on_at_all = create_submission

    expected = [commented_on_by_someone_else, not_commented_on_at_all].sort
    assert_equal expected, Submission.not_commented_on_by(user).sort
  end

  ### Test Cases by Pramati ###
  def test_blob_url
    skip
    submission = Submission.create(state: 'pending', user: sai)
    submission.slug = "gigasecond"
    submission.commitid = "1ae84bd64a63c4ddcdec0ad0bda74984eb7ca3fb"
    submission.save
    #binding.pry
    assert_equal(submission.get_blob_url,"https://api.github.com/repos/SaiVardhan/gigasecond/git/blobs/9d976df5b15d45e1cfed6dd680a99475e10a9b4c")
  end

  def test_blob_url_when_nil
    skip
    submission = Submission.create(state: 'pending', user: sai)
#    submission.slug = "gigasecond"
    submission.commitid = "1ae84bd64a63c4ddcdec0ad0bda74984eb7ca3fb"
    submission.save
    raises_exception = -> { raise ArgumentError.new }
    submission.stub :get_blob_url, raises_exception do
      assert_raises(ArgumentError) { submission.get_blob_url }
    end
  end
end
