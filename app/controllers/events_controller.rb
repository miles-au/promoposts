class EventsController < ApplicationController
	def destroy
		event = Event.find(params['id'])
		event.destroy
	    flash[:success] = "Activity deleted"
	    redirect_to root_url
	end
end
