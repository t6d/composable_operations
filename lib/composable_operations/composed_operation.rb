module ComposableOperations
  class ComposedOperation < Operation

    class AutoConfiguringOperation < SimpleDelegator

      def initialize(operation_class, options = {})
        super(operation_class)
        @_options = options
      end

      def create(context, input = nil)
        new input, Hash[Hash(@_options).map do |key, value|
          [key, value.kind_of?(Proc) ? context.instance_exec(&value) : value]
        end]
      end

    end

    class << self

      def operations
        [] + Array((super if defined? super)) + Array(@operations)
      end

      def use(operation, options = {})
        (@operations ||= []) << AutoConfiguringOperation.new(operation, options)
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

    end

    protected

      def execute
        self.class.operations.inject(input) do |data, operation|
          operation = operation.create(self, data)
          operation.perform

          if operation.failed?
            fail operation.message, operation.result, operation.backtrace
          elsif operation.halted?
            halt operation.message, operation.result
          end

          operation.result
        end
      end

  end
end
