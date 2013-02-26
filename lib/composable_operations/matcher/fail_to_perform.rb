module FailToPerform
  class Matcher

    def matches?(operation)
      self.operation = operation
      failed? && correct_message?
    end

    def because(message)
      @message = message
      self
    end

    def description
      description = "fail to perform"
      description += " because #{message}" if message
      description
    end

    def failure_message
      return "did not fail" unless failed?
      "did not fail with the correct message:\n\texpected: #{message}\n\treceived: #{operation.message}"
    end

    def negative_failure_message
      return "failed with the given message" if failed? && message? && correct_message?
      "failed"
    end

    protected

      attr_reader :operation
      attr_reader :message

      def operation=(operation)
        operation.perform
        @operation = operation
      end

    private

      def failed?
        operation.failed?
      end

      def message?
        message.present?
      end

      def correct_message?
        return true unless message
        operation.message == message
      end

  end

  def fail_to_perform
    Matcher.new
  end

end

RSpec.configure do |config|
  config.include FailToPerform, :type => :operation
end
