class ComposedOperation < Operation
  class << self

    def operations
      [] + Array((super if defined? super)) + Array(@operations)
    end

    def use(operation)
      (@operations ||= []) << operation
    end

  end

  def operations
    self.class.operations
  end

  protected

    def execute
      operations.inject(input) do |data, operation|
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
