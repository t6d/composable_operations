require 'smart_properties'
require 'delegate'

module ActiveOperation
  class Error < RuntimeError; end
  class AlreadyCompletedError < Error; end
end

require_relative "active_operation/input"
require_relative "active_operation/base"
require_relative "active_operation/operation_error"
require_relative "active_operation/pipeline"
require_relative "active_operation/version"

