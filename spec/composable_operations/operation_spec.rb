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

    let(:failing_operation) do
      Class.new(Operation) do
        def execute
          fail "Operation failed"
        end
      end
    end

    subject(:failing_operation_instance) do
      failing_operation.new
    end

    before(:each) do
      failing_operation_instance.perform
    end

    it "should have nil as result" do
      failing_operation_instance.result.should be_nil
    end

    it "should have failed" do
      failing_operation_instance.should be_failed
    end

    it "should have a message" do
      failing_operation_instance.message.should be_present
    end

    it "should raise an error when executed using the class method perform" do
      expect { failing_operation.perform }.to raise_error("Operation failed")
    end

    context "when extended with a finalizer" do

      let(:supervisor) { mock("Supervisor") }

      let(:failing_operation_instance_with_finalizer) do
        supervisor = supervisor()
        Class.new(failing_operation) do
          after { supervisor.notify }
        end
      end

      subject(:failing_operation_instance_with_finalizer_instance) do
        failing_operation_instance_with_finalizer.new
      end

      it "should execute the finalizers" do
        supervisor.should_receive(:notify)
        failing_operation_instance_with_finalizer_instance.perform
      end

    end

    context "when configured to raise a custome execption" do

      let(:custom_exception) { Class.new(RuntimeError) }

      subject(:failing_operation_with_custom_exception) do
        custom_exception = custom_exception()
        Class.new(failing_operation) do
          raises custom_exception
        end
      end

      it "should raise the custom exeception when executed using the class method perform" do
        expect { failing_operation_with_custom_exception.perform }.to raise_error(custom_exception, "Operation failed")
      end

    end

  end

  context "that always returns something when executed" do

    let(:simple_operation) do
      Class.new(Operation) do
        def execute
          ""
        end
      end
    end

    subject(:simple_operation_instance) do
      simple_operation.new
    end

    before(:each) do
      simple_operation_instance.perform
    end

    it "should have a result" do
      simple_operation_instance.result.should be
    end

    it "should have succeeded" do
      simple_operation_instance.should be_succeeded
    end

    context "when extended with a preparator and a finalizer" do

      let(:logger) { double("Logger") }

      subject(:simple_operation_with_preparator_and_finalizer) do
        logger = logger()
        Class.new(simple_operation) do
          before { logger.info("preparing") }
          after { logger.info("finalizing") }
        end
      end

      it "should execute the preparator and finalizer when performing" do
        logger.should_receive(:info).ordered.with("preparing")
        logger.should_receive(:info).ordered.with("finalizing")
        simple_operation_with_preparator_and_finalizer.perform
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

  context "that can be parameterized" do

    subject(:string_multiplier) do
      Class.new(Operation) do
        property :multiplier, :default => 3

        def execute
          input.to_s * multiplier
        end
      end
    end

    it "should operate according to the specified default value" do
      string_multiplier.perform("-").should be == "---"
    end

    it "should allow to overwrite default settings" do
      string_multiplier.perform("-", :multiplier => 5).should be == "-----"
    end

  end

end

