require 'bundler/setup'
require 'rspec'

require 'composable_operations'
require 'composable_operations/matcher'

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
end

