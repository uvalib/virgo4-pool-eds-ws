require 'rubygems'
require 'bundler'

# Auto require Gemfile
# Some gems need a different require name,
# generally specify it in the Gemfile instead of here
Bundler.require :default, ENV['RACK_ENV']

require_relative 'config/initializer'

# Require the app files
Dir[File.join(__dir__, 'app', '**', '*.rb')].each { |file| require file }

run Cuba

