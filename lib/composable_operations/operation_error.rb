class OperationError < RuntimeError
  include Bugsnag::MetaData
end
