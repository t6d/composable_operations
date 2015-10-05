module ComposableOperations
  class ComposedOperation < Operation

    class OperationFactory < SimpleDelegator

      def initialize(operation_class, options = {})
        super(operation_class)
        @_options = options
      end

      def new(context, *input)
        input = input.shift(arity)
        __getobj__.new *input, Hash[Array(@_options).map do |key, value|
          [key, value.kind_of?(Proc) ? context.instance_exec(&value) : value]
        end]
      end

    end

    class << self

      def operations
        [] + Array((super if defined? super)) + Array(@operations)
      end

      def use(operation, options = {})
        if operations.empty?
          arguments = operation.arguments
          processes(*arguments) unless arguments.empty?
        end

        (@operations ||= []) << OperationFactory.new(operation, options)
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
          operation = if data.respond_to?(:to_ary)
                        operation.new(self, *data)
                      else
                        operation.new(self, data)
                      end
          operation.perform

          if operation.failed?
            fail operation.exception
          elsif operation.halted?
            halt operation.message, operation.result
          end

          operation.result
        end
      end

  end
end
