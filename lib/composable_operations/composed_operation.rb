class ComposedOperation < Operation
  class << self

    def operations
      [] + Array(super if defined? super) + Array(@operations)
    end

    def use(operation)
      (@operations ||= []) << operation
    end

  end

  protected

    def execute
      self.class.operations.inject(input) do |data, operation|
        operation = operation.new(data)
        operation.perform
        if operation.failed?
          self.message = operation.message
          break
        end
        operation.result
      end
    end

end
