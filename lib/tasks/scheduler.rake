desc "This task is called by the Heroku scheduler add-on"

# heroku run rake run_scheduled_posts
task :run_scheduled_posts => :environment do
  puts "run scheduled posts"
  Micropost.post_schedule
  puts "done"
end

task :clean_up_overlayed_images => :environment do
  puts "run clean up of overlay images"
  #Micropost.post_schedule
  puts "done"
end