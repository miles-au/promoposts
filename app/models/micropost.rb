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
  validate :valid_url
  validate :digital_asset_has_picture
  has_many :events, dependent: :destroy
  has_many :comments, dependent: :destroy
  before_save
  after_create :create_event
  after_create :set_stats_to_zero

  #attr_accessor :external_url

  self.per_page = 10

  before_destroy :delete_notifications

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
              ['Twitter Cover Photo', 'twitter_cover_photo'],
              ['Twitter Post', 'twitter_post'],
              ['Twitter Linked Post', 'twitter_linked_post'],
              ['Pinterest Pin', 'pinterest_pin'],
              ['Pinterest Board Cover', 'pinterest_board_cover'],
              ['Email Banner', 'email_banner'],
              ['Meme', 'meme'],
              ['Infographic', 'infographic']]
  end

  def self.share_to_facebook(micropost, page, message, base_url, current_user)
    fb_page = Koala::Facebook::API.new(page.user.facebook.get_page_access_token(page.account_id))

    begin
        if micropost.picture?
          picture_url = base_url + micropost.picture.url
          if micropost.external_url?
            graph_post = fb_page.put_picture(picture_url, 'image' ,{:message => message, :link => micropost.external_url})
          else
            graph_post = fb_page.put_picture(picture_url, 'image' ,{:message => message})
          end
        else
          if micropost.external_url?
            graph_post = fb_page.put_connections(page_id, "feed", :message => message, :link => micropost.external_url)
          else
            graph_post = fb_page.put_connections(page_id, "feed", :message => message)
          end
        end
        return "success"
    rescue => e
        return "failed"
        puts e.message
    end

  end

  def self.share_to_linkedin(micropost, page, message, base_url, current_user)
    client = current_user.linkedin
    decrypted_token = User.get_token(current_user.linkedin_oauth_token)

    #create share
    if micropost.picture.url
      picture_url = base_url + micropost.picture.url

      if micropost.external_url
        #article with picture
        share = {
            "content": {
                "contentEntities": [
                    {
                        "entityLocation": micropost.external_url,
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
        #share = {:content => {:'title' => message, :'submitted-url' => micropost.picture.url}, :'submitted-url' => micropost.external_url}.to_json
      else
        #picture
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

        puts "SHARE: #{share}"
      end
    else
      #link without picture
      if micropost.external_url
        #share = {:content=>{ :'submitted-url' => micropost.external_url },comment: message, visibility: {code: "anyone"} }.to_json
        share = {
            "content": {
                "contentEntities": [
                    {
                        "entityLocation": micropost.external_url,
                    }
                ],
                "title": message,
                "shareMediaCategory": "ARTICLE"
            },
            "owner": "urn:li:person:#{page.account_id}",
        }.to_json
      else
        #share = {comment: message, visibility: {code: "anyone"} }.to_json
        share = {
            "owner": "urn:li:person:#{page.account_id}",
            "text": {
                "text": message
            }
        }.to_json
      end
    end

    decrypted_token = User.get_token(current_user.linkedin_oauth_token)

    #header = { "Content-Type" => "application/json", 'Host' => 'api.linkedin.com', 'Connection' => 'Keep-Alive', 'Authorization' => "Bearer #{token}" }
    #HTTParty.post("https://api.linkedin.com/v2/organizationalEntityAcls?q=roleAssignee&oauth2_access_token=#{decrypted_token}")

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

  def self.share_to_twitter(micropost, page, message, base_url, current_user)
    #get permissions

    client = current_user.twitter
    picture = base_url + micropost.picture.url
    response = client.update_with_media(message, open(picture))

    puts "RESPONSE: #{response}"
    puts "ID: #{response.id}"
    
    if response.id
      return "success"
    else
      return "failed"
    end
  end

  def self.share_to_buffer(micropost, page, message, base_url, current_user)
    #get permissions

    client = current_user.buffer

    if micropost.picture.url
      if micropost.external_url
        picture = base_url + micropost.picture.url
        response = client.create_update(:body => {:profile_ids => [page.account_id], :text => message, :now => true, :media => {:photo => picture, :link => micropost.external_url}})
      else
        picture = base_url + micropost.picture.url
        response = client.create_update(:body => {:profile_ids => [page.account_id], :text => message, :now => true, :media => {:photo => picture}})
      end
    else
      if micropost.external_url
        response = client.create_update(:body => {:profile_ids => [page.account_id], :text => message, :now => true, :media => {:link => micropost.external_url}} )
      else
        response = client.create_update(:body => {:profile_ids => [page.account_id], :text => message, :now => true} )
      end
    end

    puts "RESPONSE: #{response}"
    
    if response.success?
      return "success"
    else
      return "failed"
    end
  end

  def self.share_to_pinterest(micropost, page, message, base_url, current_user)
    #get permissions

    picture = base_url + micropost.picture.url
    response = current_user.pinterest.create_pin({
      board: page.account_id,
      note: message,
      image_url: picture
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

    def valid_url
=begin
      if !external_url || external_url.empty?
        self.update_attribute('external_url', nil)
        return
      else
        puts "EXTERNAL: #{external_url}"
        if test_link(external_url).present?
          valid_link = test_link(external_url)
        elsif test_link("http://www.#{external_url}")
          valid_link = test_link("http://www.#{external_url}")
        elsif test_link("https://www.#{external_url}")
          valid_link = test_link("https://www.#{external_url}")
        elsif test_link("http://#{external_url}")
          valid_link = test_link("http://#{external_url}")
        end

        if valid_link
          self.update_attribute('external_url', valid_link)
        else
          errors[:base] << "Please include a full valid link."
        end
      end
=end

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

    def delete_notifications
      Notification.where("notifications.category = 'comment' AND notifications.destination_id = ?", self.id).destroy_all
      Notification.where("notifications.category = 'share' AND notifications.destination_id = ?", self.id).destroy_all
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

    def create_event
      event = Event.new(user_id: user_id, micropost_id: id, contribution: 'create')
      event.save
    end

    def set_stats_to_zero
      self.update_attributes(:shares => 0, :downloads => 0)
    end
    
end