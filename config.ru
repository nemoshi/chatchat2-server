require './config/initializer.rb'
require './app/api.rb'

run Rack::URLMap.new(
  '/'         => ChachatApp
)