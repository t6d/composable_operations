require 'spec_helper'

describe Operation do

  context "that always returns nil when executed" do

    subject(:nil_operation) do
      class << (operation = Operation.new(''))
        def execute
          nil
        end
      end
      operation
    end

    before(:each) do
      nil_operation.perform
    end

    it "should have nil as result" do
      nil_operation.result.should be_nil
    end

    it "should have failed" do
      nil_operation.should be_failed
    end

  end

  context "that always fails" do

    subject(:failing_operation) do
      Class.new(Operation) do
        def execute
          fail "Operation failed"
        end
      end.new("")
    end

    before(:each) do
      failing_operation.perform
    end

    it "should have nil as result" do
      failing_operation.result.should be_nil
    end

    it "should have failed" do
      failing_operation.should be_failed
    end

    it "should have a message" do
      failing_operation.message.should be_present
    end

  end
  context "that always returns something when executed" do

    subject(:simple_operation) do
      Class.new(Operation) do
        def execute
          ""
        end
      end.new("")
    end

    before(:each) do
      simple_operation.perform
    end

    it "should have a result" do
      simple_operation.result.should be
    end

    it "should have succeeded" do
      simple_operation.should be_succeeded
    end

  end

  context "that is composed of two operations" do

    let(:scream_operation) do
      Class.new(Operation) do
        def execute
          "#{input}!!!111"
        end
      end
    end

    let(:upcase_operation) do
      Class.new(Operation) do
        def execute
          input.upcase
        end
      end
    end

    let(:upcase_and_scream_operation) do
      upcase_operation = upcase_operation()
      scream_operation = scream_operation()

      Class.new(Operation) do
        compose do
          use upcase_operation
          use scream_operation
        end
      end
    end

    subject(:upcase_and_scream_operation_instance) do
      upcase_and_scream_operation.new('Don\'t do that')
    end

    before do
      upcase_and_scream_operation_instance.perform
    end

    it "should have the appropriate result" do
      upcase_and_scream_operation_instance.result.should be == 'DON\'T DO THAT!!!111'
    end

    it "should have succeeded" do
      upcase_and_scream_operation_instance.should be_succeeded
    end

    context "when provided with a finalizer and a preparator" do

      let(:logger) { double('logger') }

      before do
        logger = logger()

        upcase_and_scream_operation.instance_eval do
          before do
            logger.info("Starting operation")
          end
        end

        upcase_and_scream_operation.instance_eval do
          after do
            logger.info("Stopping operation")
          end
        end
      end

      specify "the logger should have been called twice" do
        logger.should_receive(:info).twice
        upcase_and_scream_operation_instance.perform
      end

      context "when now subclassed and extended with an additional preparator" do

        subject(:extended_upcase_and_scream_operation) do
          logger = logger()

          Class.new(upcase_and_scream_operation) do
            before do
              logger.info("Yet another log message ...")
            end
          end
        end

        specify "the logger should have been called three times" do
          logger.should_receive(:info).exactly(3)
          extended_upcase_and_scream_operation.perform("")
        end

      end

    end

    context "event handling:" do

      let(:logger) { double("Logger") }

      subject(:simple_operation) do
        Class.new(Operation) do
          def self.name; "SimpleOperation"; end
          def execute; ""; end
        end.new('')
      end

      before do
        ActiveSupport::Notifications.subscribe("simple_operation.operation") do |name, start, finish, id, payload|
          logger.info("Simple operation succeeded") if payload[:operation].succeeded?
        end
      end

      specify "an event should be sent when an operation was executed" do
        logger.should_receive(:info).with("Simple operation succeeded")
      end

      after do
        simple_operation.perform
      end

    end
  end
end

