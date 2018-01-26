require "rubygems"
require "sinatra"
require_relative "app"

Encoding.default_external = Encoding::UTF_8

use Rack::Session::Cookie, :key => 'audio.session',
                           :path => '/',
                           :secret => ENV['SESSION_SECRET'] || SecureRandom.hex

run Sinatra::Application
