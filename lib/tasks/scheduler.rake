desc "This task is called by the Heroku scheduler add-on"
task :run_scheduled_posts => :environment do
  puts "run scheduled posts"
  Micropost.post_schedule
  puts "done"
end
