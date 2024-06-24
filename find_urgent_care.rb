require 'google_maps_service'
require 'dotenv/load'

# Load the API key from the .env file
API_KEY = ENV['GOOGLE_MAPS_API_KEY']

# Initialize the client
gmaps = GoogleMapsService::Client.new(key: API_KEY)

# Prompt user for their current address
puts 'Please enter your current address:'
current_address = gets.chomp

# Geocode the address to get latitude and longitude
geocode_result = gmaps.geocode(current_address)
if geocode_result.empty?
  puts 'Unable to geocode the provided address.'
  exit
end

latitude = geocode_result[0][:geometry][:location][:lat]
longitude = geocode_result[0][:geometry][:location][:lng]

# Search for nearby urgent care facilities
results = gmaps.places_nearby(location: [latitude, longitude], radius: 5000, type: 'hospital')

if results[:results].empty?
  puts 'No urgent care facilities found nearby.'
else
  # Calculate the distance from current location to each facility
  facilities = results[:results].map do |place|
    place_location = place[:geometry][:location]
    distance_result = gmaps.distance_matrix(origins: [[latitude, longitude]], destinations: [[place_location[:lat], place_location[:lng]]])
    distance_in_km = distance_result[:rows][0][:elements][0][:distance][:value] / 1000.0
    { name: place[:name], vicinity: place[:vicinity], distance: distance_in_km }
  end

  # Sort facilities by distance
  sorted_facilities = facilities.sort_by { |facility| facility[:distance] }

  # Limit to the 10 nearest facilities
  nearest_facilities = sorted_facilities.take(10)

  # Display the sorted facilities with distance
  puts 'Nearest urgent care facilities:'
  nearest_facilities.each do |facility|
    puts "#{facility[:name]} - #{facility[:vicinity]} (#{'%.2f' % facility[:distance]} km)"
  end
end
