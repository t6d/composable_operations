module SucceedToPerform
  class Matcher

    def matches?(operation)
      self.operation = operation
      succeeded? && correct_result?
    end

    def and_return(result)
      @expected_result = result
      self
    end

    def description
      description = "succeed to perform"
      description += " and return the specified result" if expected_result
      description
    end

    def failure_message
      return "succeeded but did not return the specified result" if succeeded?
      return "failed" unless operation.message
      "failed because #{operation.message}"
    end

    def negative_failure_message
      "succeeded"
    end

    protected

      attr_reader :operation
      attr_reader :expected_result

      def operation=(operation)
        operation.perform
        @operation = operation
      end

    private

      def succeeded?
        operation.succeeded?
      end

      def correct_result?
        return true unless expected_result
        expected_result == operation.result
      end

  end

  def succeed_to_perform
    Matcher.new
  end
end

RSpec.configure do |config|
  config.include SucceedToPerform, type: :operation
end
