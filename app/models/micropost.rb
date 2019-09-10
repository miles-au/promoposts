class Micropost < ActiveRecord::Base
  belongs_to :user
  belongs_to :campaign, optional: true
  default_scope -> { order(created_at: :desc) }
  mount_uploader :picture, PictureUploader
  validates :user_id, presence: true
  validates :category, presence: true
  validates :content, length: { maximum: 400 }, presence: true
  validates :external_url, length: {maximum: 500}
  validates :picture, presence: true
  validate  :picture_size
  validate :content_exists
  validate :digital_asset_has_picture
  has_many :comments, dependent: :destroy
  has_many :scheduled_posts
  before_save
  after_create :set_stats_to_zero

  #attr_accessor :external_url

  self.per_page = 30

  def self.category_array
    array = [ ['Facebook Cover Photo','facebook_cover_photo'],
              ['Facebook Post', 'facebook_post'],
              ['Facebook Linked Image', 'facebook_linked_image'],
              ['LinkedIn Personal Cover Photo', 'linkedin_personal_cover_photo'],
              ['LinkedIn Business Cover Photo', 'linkedin_business_cover_photo'],
              ['LinkedIn Post', 'linkedin_post'],
              ['LinkedIn Linked Post', 'linkedin_linked_post'],
              ['Instagram Post', 'instagram_post'],
              ['Instagram Story', 'instagram_story'],
              ['Instagram Story Cover', 'instagram_story_cover'],
              ['Twitter Cover Photo', 'twitter_cover_photo'],
              ['Twitter Post', 'twitter_post'],
              ['Twitter Linked Post', 'twitter_linked_post'],
              ['Pinterest Pin', 'pinterest_pin'],
              ['Pinterest Board Cover', 'pinterest_board_cover'],
              ['Email Banner', 'email_banner'],
              ['Meme', 'meme'],
              ['Infographic', 'infographic'],
              ['Other', 'other']]
  end

  def self.share_to_facebook(external_url, page, message, picture_url, current_user)
    fb_page = Koala::Facebook::API.new(page.user.facebook.get_page_access_token(page.account_id))

    begin
        if external_url
          graph_post = fb_page.put_picture(picture_url, 'image' ,{:message => message, :link => external_url})
        else
          graph_post = fb_page.put_picture(picture_url, 'image' ,{:message => message})
        end
        puts "GRAPH POST #{graph_post}"
        return "success"
    rescue => e
        puts e.message
        return "failed"
    end

  end

  def self.share_to_linkedin(external_url, page, message, picture_url, current_user)
    client = current_user.linkedin
    decrypted_token = User.get_token(current_user.linkedin_oauth_token)

    #create share
    if external_url
      #article with picture
      share = {
          "content": {
              "contentEntities": [
                  {
                      "entityLocation": external_url,
                      "thumbnails": [
                          { 
                              "imageSpecificContent": {},
                              "resolvedUrl": picture_url
                          }
                      ]
                  }
              ],
              "title": message,
              "shareMediaCategory": "ARTICLE"
          },
          "owner": "urn:li:person:#{page.account_id}",
      }.to_json
    else
=begin AWAITING APPROVAL FOR RICH MEDIA SHARES
      if Rails.env.production?
        pic_upload = RestClient.post('https://api.linkedin.com/media/upload', 
          :fileupload => File.new(micropost.picture.url),
          Authorization: "Bearer #{decrypted_token}")
      else
        RestClient.post('https://api.linkedin.com/media/upload', 
          pic_upload = :fileupload => File.new(open("#{request.protocol}#{request.subdomain}.#{request.domain}#{micropost.picture.url}"),
          { Authorization: "Bearer #{decrypted_token}" }))
      end
      puts "PIC_UPLOAD: #{pic_upload}"
=end
      share = {
          "content": {
              "contentEntities": [
                  {
                      "entityLocation": picture_url,
                      "thumbnails": [
                          {
                              "imageSpecificContent": {},
                              "resolvedUrl": picture_url
                          }
                      ]
                  }
              ],
              "title": message
          },
          "owner": "urn:li:person:#{page.account_id}",
      }.to_json
    end

    puts "SHARE: #{share}"

    decrypted_token = User.get_token(current_user.linkedin_oauth_token)

    header = { "Content-Type" => "application/json", 'Host' => 'api.linkedin.com', 'Connection' => 'Keep-Alive', 'Authorization' => "Bearer #{decrypted_token}" }
    update = HTTParty.post("https://api.linkedin.com/v2/shares", 
    :body => share,
    :headers => header )

    puts "UPDATE: #{update}"
    puts "UPDATE: #{update['created']}"
    puts "UPDATE: #{update['status']}"

=begin AWAITING LINKEDIN APPROVAL FOR COMPANY PAGES
    client = @user.linkedin
    accounts = client.company(is_admin: 'true').all.pluck(:id)

    #is this a profile or company page?
    if accounts.include?(page_id.to_i)
      uri = URI("https://api.linkedin.com/v1/companies/#{page_id}/shares?format=json")
    else
      uri = URI("https://api.linkedin.com/v1/people/~/shares?format=json")
    end

    token = User.get_token(current_user.linkedin_oauth_token).token

    if micropost.picture.url
      if micropost.external_url
        share = {:content => {:'title' => message, :'submitted-url' => micropost.picture.url}, :'submitted-url' => micropost.external_url, visibility: {code: "anyone"} }.to_json
      else
        share = {:content => {:'title' => message, :'submitted-url' => micropost.picture.url}, visibility: {code: "anyone"} }.to_json
      end
    else
      if micropost.external_url
        share = {:content=>{ :'submitted-url' => micropost.external_url },comment: message, visibility: {code: "anyone"} }.to_json
      else
        share = {comment: message, visibility: {code: "anyone"} }.to_json
      end
    end

    header = { "Content-Type" => "application/json", 'Host' => 'api.linkedin.com', 'Connection' => 'Keep-Alive', 'Authorization' => "Bearer #{token}" }
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    #req = Net::HTTP::Post.new(uri.path, :initheader => { Host: 'api.linkedin.com', Connection: 'Keep-Alive', Authorization: "Bearer #{token}"})
    req = Net::HTTP::Post.new(uri.path, header)
    req.body = share
    res = http.request(req)
    update = res.body['update']
    
=end

    if update['created']
      return "success"
    else
      return "failed"
    end

  end

  def self.share_to_twitter(external_url, page, message, picture_url, current_user)
    #get permissions

    client = current_user.twitter
    response = client.update_with_media(message, open(picture_url))

    puts "RESPONSE: #{response}"
    puts "ID: #{response.id}"
    
    if response.id
      return "success"
    else
      return "failed"
    end
  end

  def self.share_to_buffer(external_url, page, message, picture_url, current_user)
    #get permissions

    client = current_user.buffer

    if external_url
      response = client.create_update(:body => {:profile_ids => [page.account_id], :text => message, :now => true, :media => {:photo => picture_url, :link => external_url}})
    else
      response = client.create_update(:body => {:profile_ids => [page.account_id], :text => message, :now => true, :media => {:photo => picture_url}})
    end

    puts "RESPONSE: #{response}"
    
    if response.success?
      return "success"
    else
      return "failed"
    end
  end

  def self.share_to_pinterest(external_url, page, message, picture_url, current_user)
    #get permissions

    response = current_user.pinterest.create_pin({
      board: page.account_id,
      note: message,
      image_url: picture_url
    })

    puts "RESPONSE: #{response}"
    success = response.data.id rescue nil
    puts "ID: #{success}"

    if success
      return "success"
    else
      return "failed"
    end
  end

  def self.create_overlay_picture(bg_url, overlay, left, top, width, height, delete_by_date)
    #create overlay
    if Rails.env.production?
      filter = MiniMagick::Image.open(overlay.picture_url)
      img = MiniMagick::Image.open(bg_url)
    else
      filter = MiniMagick::Image.open("public#{overlay.picture_url}")
      img = MiniMagick::Image.open("public#{bg_url}")
    end

    #create overlayed image
    filter.resize "#{width}x#{height}"
    result = img.composite(filter) do |c|
      c.compose "Over"
      c.geometry "+#{left}+#{top}"
    end

    #save picture
    pipeline_directory = "uploads/overlayed"
    local_directory = "public/#{pipeline_directory}"
    Dir.mkdir_p local_directory unless File.exists?(local_directory)
    file_name = "#{delete_by_date}_#{Time.now.to_i}_#{rand(1000..9999)}.jpg"
    path = "#{local_directory}/#{file_name}"
    result.write(path)
    final_url = "#{pipeline_directory}/#{file_name}"
    
    if Rails.env.production?
      connection = Fog::Storage.new({
        :provider                         => 'Google',
        :google_storage_access_key_id     => ENV["google_storage_access_key_id"],
        :google_storage_secret_access_key => ENV["google_storage_secret_access_key"]
      })
      directory = connection.directories.get("promoposts")
      file = directory.files.create(
        :key    => "#{pipeline_directory}/#{file_name}",
        :body   => File.open(path),
        :public => true
      )

      puts "FILE: #{file}"

      if file
        File.delete(path) if File.exist?(path)
        final_url = file.public_url
      end

    end

    return final_url
    
  end

  def self.post_schedule
    #get posts from a minute ago to next 10 minutes
    scheduled_posts = ScheduledPost.where("post_time >= ? AND post_time < ?", (DateTime.now.in_time_zone("UTC") - 1.minute), (DateTime.now.in_time_zone("UTC") + 10.minutes))
    scheduled_posts.each do |scheduled_post|
      if scheduled_post.status != "posted"
        post_scheduled_post(scheduled_post)
      end
    end
  end

  def self.post_scheduled_post(scheduled_post)
    #check to see if this post has a topic. If it has a topic, it should be posted to all accounts who's users are subscribed to that topic

    page = scheduled_post.account
    
    puts "Picture URL: #{scheduled_post.picture_url}"
    case page.provider
      when "facebook"
        resp = Micropost.share_to_facebook( nil, scheduled_post.account, scheduled_post.caption, scheduled_post.picture_url, scheduled_post.user)
      when "linkedin"
        resp = Micropost.share_to_linkedin( nil, scheduled_post.account, scheduled_post.caption, scheduled_post.picture_url, scheduled_post.user)
      when "twitter"
        resp = Micropost.share_to_twitter( nil, scheduled_post.account, scheduled_post.caption, scheduled_post.picture_url, scheduled_post.user)
      when "buffer"
        post_to_buffer = true
        resp = Micropost.share_to_buffer( nil, scheduled_post.account, scheduled_post.caption, scheduled_post.picture_url, scheduled_post.user)
      when "pinterest"
        resp = Micropost.share_to_pinterest( nil, scheduled_post.account, scheduled_post.caption, scheduled_post.picture_url, scheduled_post.user)
      else
    end
    if resp == "success"
      micropost = scheduled_post.micropost rescue nil
      if micropost
        if scheduled_post.user != micropost.user_id
          if micropost.shares
            micropost.shares += 1
          else 
            micropost.shares = 1
          end
          micropost.save
          track = Track.new(user_id: current_user.id, category: micropost.category, asset_num: micropost.id, act: "share")
          track.save
        end
      end
      scheduled_post.status = "posted"
      puts "POSTED"
    else
      scheduled_post.status = "failed";
      puts "FAILED"
    end
    scheduled_post.save
    puts "response: #{resp}"
  end

  private

    # Validates the size of an uploaded picture.
    def picture_size
      if picture.size > 10.megabytes
        errors.add(:picture, "should be less than 10MB")
      end
    end

    def content_exists
        if campaign_id.blank? && picture.blank? && content.blank?
          errors[:base] << "Must include a photo or text."
        end
    end

    def test_link(link)
      http_errors = [
        Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError,
        Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, SocketError
      ]

      begin
        resp = Net::HTTP.get_response(URI.parse(link))
        puts resp
      rescue *http_errors
        puts "Net:HTTP Error"
      rescue StandardError => e
        puts "Net:HTTP Exception"
      end

      if resp.is_a?(Net::HTTPSuccess)
        return link
      else
        return nil
      end

    end

    def digital_asset_has_picture
      if campaign_id.blank?
        if category == "cover_photo" || category == "email_banner" || category == "infographic" || category == "meme"
          if picture.blank?
            #cover photo must have a picture
            errors[:base] << "Must include a picture with your #{category.tr("_", " ")}."
          else
            return
          end
        end
      end
    end

    def set_stats_to_zero
      self.update_attributes(:shares => 0, :downloads => 0)
    end
    
end