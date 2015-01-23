class AddCommitidToSubmission < ActiveRecord::Migration
  def change
  	add_column :submissions, :commitid, :string
  end
end