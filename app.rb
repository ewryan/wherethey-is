require 'rubygems'
require 'json/pure'
require 'httparty'
require 'ap'

module FB

  class BaseClient
    include HTTParty
  end

  module Graph
    class Client < BaseClient
      base_uri "https://graph.facebook.com"
      def self.access_token= value
        default_params :access_token => value
      end
    end
  end

  module API
    class Client < BaseClient
      base_uri "https://api.facebook.com"
      def self.access_token= value
        default_params :token => value
      end
    end
  end

  def self.access_token= value
    API::Client.access_token= value
    Graph::Client.access_token= value
  end

end

class GoogleGeocoder
  include HTTParty
  
  #required params
  # address or latlng
  # sensor
  #optional
  # bounds
  # region
  # language
  #
  base_uri "http://maps.google.com/maps/api/geocode/json"

  def self.geocode address
    get '', :query => {:address => address, :sensor => false}
  end
end


access_token = "1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"


FB.access_token= access_token

result = FB::Graph::Client.get('/me/friends', :query => {:fields => ['location', 'name', 'hometown']})

friends = result.delete "data"

located_friends = friends.select{|f| f["location"] && f["location"]["name"]}
locationless_friends = friends.reject{|f| f["location"] && f["location"]["name"]}

hometown_friends = friends.select {|f| f["hometown"] && f["hometown"]["name"]}

friends_by_location = located_friends.inject({}) do |addresses,friend|
  address = friend["location"]["name"]              
  addresses[address] ||= {"current_people"=>[]}
  addresses[address]["current_people"] << friend
  addresses
end

hometown_friends.each do |friend|
  address = friend["hometown"]["name"]
  friends_by_location[address] ||= {}
  friends_by_location[address]["hometown_people"] ||= []
  
  friends_by_location[address]["hometown_people"] << friend
end

ap friends_by_location
exit

friends_by_location.each do |location,attrs|
  result = GoogleGeocoder.geocode location
  if result["status"] != "OK"
    next if result["status"] =="ZERO_RESULTS"
  end

  attrs["latlng"] = result["results"].first["geometry"]["location"]
end

File.open "output.json","w" do |f|
f.puts "awesome(#{
{:located => friends_by_location.map{|loc,attrs| attrs["name"]=loc;attrs},
:missing => locationless_friends}.to_json})"
end
