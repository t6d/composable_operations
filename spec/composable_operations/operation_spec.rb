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

