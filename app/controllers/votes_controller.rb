class VotesController < ApplicationController
	before_action :logged_in_user
	protect_from_forgery with: :exception
	
	def submit_vote
		@comment_id = params['comment_id']
		@comment = Comment.find(@comment_id)

		#has the user voted already?
		voted = Vote.find_by(:comment_id => @comment_id, :user_id => params['user_id'])
		if voted
			if voted.points.to_i == params['points'].to_i
				voted.destroy
			else
				voted.points = params['points']
				voted.save
			end
		else
			#if not submit vote
			@vote = Vote.new(:comment_id => @comment_id, :user_id => params['user_id'], :points => params['points'])
			@vote.save!
		end

		respond_to do |format|
	      format.html
	      format.js
	    end
	end
end
