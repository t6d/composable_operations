module ComposableOperations
  module Matcher
    module Execution

      class Base

        def and_return(result)
          @result = result
          self
        end

        def when_initialized_with(*input)
          @input = input
          self
        end

        protected

          attr_reader :operation
          attr_reader :result
          attr_reader :input

          def operation=(operation)
            operation = operation.new(*input) if operation.kind_of?(Class)
            operation.perform
            @operation = operation
          end

          def failed?
            operation.failed?
          end

          def succeeded?
            operation.succeeded?
          end

          def result_as_expected?
            return true unless result
            operation.result == result
          end

          def input_as_text
            humanize(*input)
          end

          def result_as_text
            humanize(result)
          end

        private

          def humanize(*args)
            args = args.map(&:inspect)
            last_element = args.pop
            args.length > 0 ? [args.join(", "), last_element].join(" and ") : last_element
          end

      end

      class SucceedToPerform < Base

        def matches?(operation)
          self.operation = operation
          succeeded? && result_as_expected?
        end

        def description
          description = "succeed to perform"
          description += " when initialized with custom input (#{input_as_text})" if input
          description += " and return the expected result (#{result_as_text})" if result
          description
        end

        def failure_message
          "the operation failed to perform for the following reason(s):\n#{failure_reasons}"
        end

        def failure_message_when_negated
          "the operation succeeded unexpectedly"
        end
        alias negative_failure_message failure_message_when_negated

        private

          def failure_reasons
            reasons = []
            reasons << "it did not succeed at all" unless succeeded?
            unless result_as_expected?
              reasons << [
                "it did not return the expected result",
                "Expected: #{result.inspect}",
                "Got: #{operation.result.inspect}"
              ].join("\n\t  ")
            end
            reasons.map { |r| "\t- #{r}" }.join("\n")
          end

      end

      class FailToPerform < Base

        def matches?(operation)
          self.operation = operation
          failed? && result_as_expected? && message_as_expected?
        end

        def because(message)
          @message = message
          self
        end

        def description
          description = "fail to perform"
          description += " because #{message}" if message
          description += " when initialized with custom input (#{input_as_text})" if input
          description += " and return the expected result (#{result_as_text})" if result
          description
        end

        def failure_message
          "the operation did not fail to perform for the following reason(s):\n#{failure_reasons}"
        end

        def failure_message_when_negated
          "the operation failed unexpectedly"
        end
        alias negative_failure_message failure_message_when_negated

        protected

          attr_reader :message

          def message_as_expected?
            return true unless message
            operation.message == message
          end

          def failure_reasons
            reasons = []
            reasons << "it did not fail at all" unless failed?
            reasons << "its message was not as expected" unless message_as_expected?
            unless result_as_expected?
              reasons << [
                "it did not return the expected result",
                "Expected: #{result.inspect}",
                "Got: #{operation.result.inspect}"
              ].join("\n\t  ")
            end
            reasons.map { |r| "\t- #{r}" }.join("\n")
          end

      end

      def succeed_to_perform
        SucceedToPerform.new
      end

      def fail_to_perform
        FailToPerform.new
      end

    end
  end
end

RSpec.configure do |config|
  config.include ComposableOperations::Matcher::Execution
end
