class Overlay < ApplicationRecord
	belongs_to :user
	mount_uploader :picture, PictureUploader

	def self.get_specs(overlay_location, overlay_picture_url, bg_picture_url)
		overlay_image = MiniMagick::Image.open(overlay_picture_url)
		bg_image = MiniMagick::Image.open(bg_picture_url)

		overlay_ratio = overlay_image[:width]/overlay_image[:height]
		max_overlay_width = bg_image[:width]/5
		max_overlay_height = bg_image[:height]/5

		if overlay_ratio >= 1
			# overlay is wider than tall
			width = max_overlay_width
			height = width / overlay_ratio
		else
			#overlay is taller than wide
			height = max_overlay_height
			width = height * overlay_ratio
		end

		case overlay_location
			when "nw"
				left = 0
				top = 0
			when "ne"
				left = bg_image[:width] - width
				top = 0
			when "sw"
				left = 0
				top = bg_image[:height] - height
			when "se"
				left = bg_image[:width] - width
				top = bg_image[:height] - height
			else
				left = 0
				top = 0
		end

		return [ left, top, width, height]
	end

	def self.location_array
		arr = [ 	[ "Top Left" , "nw" ],
							[ "Top Right" , "ne" ],
							[ "Bottom Left" , "sw" ],
							[ "Bottom Right" , "se" ]
			] 
	end

	def self.location_to_text(location)
		case location
			when "nw"
				return "top left"
			when "ne"
				return "top right"
			when "sw"
				return "bottom left"
			when "se"
				return "bottom right"
			else
				return "top left"
		end
	end

end
