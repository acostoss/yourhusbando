require "yaml"
require "twitter"
require "ostruct"

keys = YAML.load_file File.expand_path(".", "config.yml")
husbando = YAML.load_file File.expand_path(".", "husbando.yml")

client = Twitter::REST::Client.new do |config|
  config.consumer_key = keys['consumer_key']
  config.consumer_secret = keys['consumer_secret']
  config.access_token = keys['access_token']
  config.access_token_secret = keys['access_token_secret']
end
 
streamer = Twitter::Streaming::Client.new do |config|
  config.consumer_key = keys['consumer_key']
  config.consumer_secret = keys['consumer_secret']
  config.access_token = keys['access_token']
  config.access_token_secret = keys['access_token_secret']
end

begin
  current_user = client.current_user
rescue Exception => e
  puts "Exception: #{e.message}"
  # best hack:
  current_user = OpenStruct.new
  current_user.id = config["access_token"].split("-")[0]
end

puts "yourhusbando - serving #{husbando.count} entries"
puts "-------------------------------"

loop do
  streamer.user do |object|
    if object.is_a? Twitter::Tweet
      unless current_user.id == object.user.id
        unless object.text.start_with? "RT @"
          chosen_one = husbando.sample
          puts "[#{Time.new.to_s}] #{object.user.screen_name}: #{chosen_one["name"]} - #{chosen_one["series"]}"
          begin
            begin
            client.update_with_media "@#{object.user.screen_name} Your husbando is #{chosen_one["name"]} (#{chosen_one["series"]})", File.new("img/#{chosen_one["series"]}/#{chosen_one["name"]}.png"), in_reply_to_status:object
            rescue Exception => m
              puts "\033[34;1m[#{Time.new.to_s}] #{m.message} Trying to post tweet without image!\033[0m"
              client.update "@#{object.user.screen_name} Your husbando is #{chosen_one["name"]} (#{chosen_one["series"]})", in_reply_to_status:object
            end
          rescue Exception => e
            puts "\033[31;1m[#{Time.new.to_s}] #{e.message}\033[0m"
          end
        end
      end
    end
  end
  sleep 1
end
