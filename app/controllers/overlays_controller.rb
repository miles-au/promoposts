class OverlaysController < ApplicationController
	before_action :logged_in_user

	def show
		@overlays = current_user.overlays
	  @new_overlay = current_user.overlays.build
	  @overlay_locations = [ 	[ "Top Left" , "nw" ],
	  												[ "Top Right" , "ne" ],
	  												[ "Bottom Left" , "sw" ],
	  												[ "Bottom Right" , "se" ]
	  											]
	  @overlay_locations.unshift(["Select location" , nil])
	  @overlay_select = @overlays.pluck(:name, :id)
	  @overlay_select.unshift(["none" , nil])
	  if @overlays.pluck(:id).include?(current_user.setting.default_overlay_id)
	  	@default_select_overlay = current_user.setting.default_overlay_id
	  else
	  	@default_select_overlay = nil
	  end
	end

	def create
		@overlay = current_user.overlays.build(overlay_params)
		@overlay.permissions = "private"
    if @overlay.save
      flash[:success] = "Overlay created"
    else
    	flash[:danger] = "Unable to create overlay"
    end
	  redirect_to '/overlays'
	end

	def destroy
		@overlay = Overlay.find(params[:id])
		@overlay.destroy
	    flash[:success] = "Overlay deleted"
	    redirect_to overlays_path
	end

	def default_overlay
		current_user.setting.default_overlay_id = params[:id]
		current_user.setting.default_overlay_location = params[:location]
		if current_user.setting.save
			flash[:success] = "Default overlay updated"
		else
			flash[:danger] = "Unable to update default overlay"
		end

		redirect_to overlays_path
	end

	private
  	def overlay_params
      params.require(:overlay).permit(:picture, :category, :name, :location)
    end
end
