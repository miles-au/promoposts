class AddFollowAndQuestionEmailNotificationsToSettings < ActiveRecord::Migration[5.2]
  def change
  	add_column :settings, :email_when_followed, :boolean, default: true
  	add_column :settings, :email_when_new_question, :boolean, default: false

  	reversible do |dir|
	    dir.up { Setting.update_all('email_when_followed = true') }
	    dir.up { Setting.update_all('email_when_new_question = false') }
	  end
  end
end
