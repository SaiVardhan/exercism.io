class AddCommitidToSubmission < ActiveRecord::Migration
  def change
  	#add_column :submissions, :commitid, :string
  	remove_column :submissions, :commitid
  end
end
