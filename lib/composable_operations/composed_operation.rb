class ComposedOperation < Operation
  class << self

    def operations
      [] + Array((super if defined? super)) + Array(@operations)
    end

    def use(operation)
      (@operations ||= []) << operation
    end

    def compose(*operations, &block)
      raise ArgumentError, "Expects either an array of operations or a block with configuration instructions" unless block ^ !operations.empty?

      if block
        Class.new(self, &block)
      else
        Class.new(self) do
          operations.each do |operation|
            use operation
          end
        end
      end
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
          fail operation.message
        elsif operation.halted?
          halt operation.message, operation.result
        end

        operation.result
      end
    end

end
