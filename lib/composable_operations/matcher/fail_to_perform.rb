module ComposableOperations
  module Matcher
    module FailToPerform
      class Matcher

        def matches?(operation)
          self.operation = operation
          failed? && result_as_expected? && message_as_expected?
        end

        def because(message)
          @message = message
          self
        end

        def and_return(result)
          @result = result
          self
        end

        def when_initialized_with(*input)
          @input = input
          self
        end

        def description
          description = "fail to perform"
          description += " because #{message}" if message
          description += " when initialized with custom input" if input
          description += " and return the expected result" if result
          description
        end

        def failure_message
          "the operation did not fail to perform for the following reason(s):\n#{failure_reasons}"
        end

        def negative_failure_message
          "the operation failed unexpectedly"
        end

        protected

          attr_reader :operation
          attr_reader :message
          attr_reader :result
          attr_reader :input

          def operation=(operation)
            operation = operation.new(*input) if operation.kind_of?(Class)
            operation.perform
            @operation = operation
          end

        private

          def failed?
            operation.failed?
          end

          def message_as_expected?
            return true unless message
            operation.message == message
          end

          def result_as_expected?
            return true unless result
            operation.result == result
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

      def fail_to_perform
        Matcher.new
      end

    end
  end
end

RSpec.configure do |config|
  config.include ComposableOperations::Matcher::FailToPerform
end
