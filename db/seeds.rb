unless User.find_by( email: "contact@promoposts.net" )
  User.create!(name:  "Miles Au",
               email: "contact@promoposts.net",
               password:              "foobar",
               password_confirmation: "foobar",
               admin: true,
               activated: true,
               activated_at: Time.zone.now,
               category: "none")
end

=begin
99.times do |n|
  num = 1
  10.times do |i|
    num = rand(1..3) 
  end
  if num == 1
    cat = "distributor"
  elsif num == 2
    cat = "vendor"
  else
    cat = "none"
  end
  name  = Faker::Name.name
  email = "example-#{n+1}@railstutorial.org"
  password = "password"
  unless User.find_by( email: email )
    User.create!(name:  name,
                email: email,
                password:              password,
                password_confirmation: password,
                activated: true,
                activated_at: Time.zone.now,
                category: cat)
  end
end
=end


#users = User.order(:created_at).take(6)

15.times do |n|
  num = rand(1..3) 
  if num == 1
    cat = "distributor"
  elsif num == 2
    cat = "vendor"
  else
    cat = "none"
  end
  name  = Faker::Name.name
  email = "example-#{n+1}@railstutorial.org"
  password = "password"
  unless User.find_by( email: email )
    User.create!(name:  name,
                email: email,
                password:              password,
                password_confirmation: password,
                activated: true,
                activated_at: Time.zone.now,
                category: cat)
  end
end

cat_array = [ 'facebook_cover_photo',
              'facebook_post',
              'facebook_linked_image',
              'linkedin_personal_cover_photo',
              'linkedin_business_cover_photo',
              'linkedin_post',
              'linkedin_linked_post',
              'instagram_post',
              'instagram_story',
              'twitter_cover_photo',
              'twitter_post',
              'twitter_linked_post',
              'pinterest_pin',
              'pinterest_board_cover',
              'email_banner',
              'meme',
              'infographic']

users = User.all

users.each do |user|
  5.times do
    content = Faker::Lorem.sentence(5)
    picture = File.open(Rails.root + "app/assets/images/travel/#{rand(60)}.jpg")
    category = cat_array.sample
    user.microposts.create!(content: content, picture: picture, category: category)
  end
end

campaign_users = User.order("RANDOM()").limit(5)

campaign_users.each do |user|
  rand(1..2).times do
    content = Faker::Lorem.sentence(5)
    campaign_name = Faker::Lorem.sentence(1)
    new_campaign = user.campaigns.create!(content: content, name: campaign_name )
    
    rand(3..8).times do
      category = cat_array.sample
      picture = File.open(Rails.root + "app/assets/images/travel/#{rand(60)}.jpg")
      user.microposts.create!(content: content, picture: picture, category: category, campaign_id: new_campaign.id)
    end
    
  end
end

=begin
# Following relationships
users = User.all
user  = users.first
following = users[2..50]
followers = users[3..40]
following.each { |followed| user.follow(followed) }
followers.each { |follower| follower.follow(user) }
=end
