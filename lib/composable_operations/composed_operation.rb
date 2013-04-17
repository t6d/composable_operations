class ComposedOperation < Operation
  class << self

    def operations
      [] + Array((super if defined? super)) + Array(@operations)
    end

    def use(operation)
      (@operations ||= []) << operation
    end

    def compose(*operations, &block)
      raise ArgumentError, "Expects either an array of operations or a block with configuration instructions" unless !!block ^ !operations.empty?

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

    def transitions
      transitions = []
      klass = self
      while klass != Operation
        klass = klass.superclass
        transitions += Array(klass.instance_variable_get(:@transitions))
      end
      transitions += Array(@transitions)
      transitions
    end


    protected

      def between(&callback)
        (@transitions ||= []) << callback
      end

  end

  def operations
    self.class.operations
  end

  protected

    def execute
      [nil, *operations, nil].each_cons(2).inject(input) do |data, operations|
        if operation = operations.last
          operation = operation.new(data)
          operation.perform

          if operation.failed?
            fail operation.message, operation.result, operation.backtrace
          elsif operation.halted?
            halt operation.message, operation.result
          end

          transition(*operations, data) if operations.first && operations.last
          operation.result
        else
          data
        end
      end
    end

    def transition(a, b, payload)
      self.class.transitions.each { |transition| instance_exec(a, b, payload, &transition) }
    end

end
