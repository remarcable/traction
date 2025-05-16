ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require 'dotenv'
env_file = case ENV['RAILS_ENV'] || ENV['RACK_ENV']
            when 'production'
                '.env.production'
            else
                '.env'
            end

Dotenv.load(env_file) if File.exist?(env_file)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
