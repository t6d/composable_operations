module ComposableOperations
  module Matcher
module SucceedToPerform
      class Matcher

        def matches?(operation)
          self.operation = operation
          succeeded? && result_as_expected?
        end

        def and_return(result)
          @result = result
          self
        end

        def description
          description = "succeed to perform"
          description += " and return the expected result" if result
          description
        end

        def failure_message
          "the operation failed to perform for the following reason(s):\n#{failure_reasons}"
        end

        def negative_failure_message
          "the operation succeeded unexpectedly"
        end

        protected

          attr_reader :operation
          attr_reader :result

          def operation=(operation)
            operation.perform
            @operation = operation
          end

        private

          def succeeded?
            operation.succeeded?
          end

          def result_as_expected?
            return true unless result
            operation.result == result
          end

          def failure_reasons
            reasons = []
            reasons << "it did not succeed at all" unless succeeded?
            reasons << "it did not return the expected result" unless result_as_expected?
            reasons.map { |r| "\t- #{r}" }.join("\n")
          end

      end

      def succeed_to_perform
        Matcher.new
      end
    end
  end
end

RSpec.configure do |config|
  config.include ComposableOperations::Matcher::SucceedToPerform
end

