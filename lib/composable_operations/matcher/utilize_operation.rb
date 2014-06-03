module ComposableOperations
  module Matcher
    module UtilizeOperation

      class DummyOperation
        def initialize(*args)
        end

        def failed?
          false
        end

        def halted?
          false
        end

        def succeeded?
          true
        end

        def result
          Object.new
        end

        def perform
          result
        end
      end

      class Matcher

        attr_reader :composite_operations
        attr_reader :tested_operation
        attr_reader :tested_instance

        def initialize(*composite_operations)
          @composite_operations = composite_operations.flatten
        end

        def matches?(class_or_instance)
          if class_or_instance.is_a?(Class)
            @tested_operation = class_or_instance
            @tested_instance = class_or_instance.new
          else
            @tested_operation = class_or_instance.class
            @tested_instance = class_or_instance
          end

          Operation.stub(:new => DummyOperation.new)
          composite_operations.each do |composite_operation|
            dummy_operation = DummyOperation.new
            dummy_operation.should_receive(:perform).and_call_original
            composite_operation.should_receive(:new).and_return(dummy_operation)
          end
          tested_instance.stub(:prepare => true, :finalize => true)
          tested_instance.perform

          tested_operation.operations == composite_operations
        end

        def description
          "utilize the following operations: #{composite_operations.map(&:to_s).join(', ')}"
        end

        def failure_message
          expected_but_not_used = composite_operations - tested_operation.operations
          used_but_not_exptected = tested_operation.operations - composite_operations
          message = ["Unexpected operation utilization:"]
          message << "Expected: #{expected_but_not_used.join(', ')}" unless expected_but_not_used.empty?
          message << "Not expected: #{used_but_not_exptected.join(', ')}" unless used_but_not_exptected.empty?
          message.join("\n\t")
        end

        def failure_message_when_negated
          "Unexpected operation utilization"
        end
        alias negative_failure_message failure_message_when_negated

      end

      def utilize_operation(*args)
        Matcher.new(*args)
      end
      alias utilize_operations utilize_operation

    end
  end
end

RSpec.configure do |config|
  config.include ComposableOperations::Matcher::UtilizeOperation
end

