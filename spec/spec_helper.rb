require 'bundler/setup'
require 'rspec'
require 'pry'

require 'active_operation'
require 'active_operation/matcher'

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
end

