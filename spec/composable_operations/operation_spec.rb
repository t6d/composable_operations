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
      class << (operation = Operation.new(''))
        def execute
          fail "Operation failed"
        end
      end
      operation
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
      class << (operation = Operation.new(''))
        def execute
          ""
        end
      end
      operation
    end

    before(:each) do
      simple_operation.perform
    end

    it "should have a result" do
      simple_operation.result.should be
    end

    it "should have successful" do
      simple_operation.should be_successful
    end

    context "when provided with a preparator" do
      let(:logger) { stub('Logger') }

      before do
        logger = logger()
        simple_operation.before do
          logger.info("Preparing")
        end
      end

      it "should invoke the preparator" do
        logger.should_receive(:info)
        simple_operation.perform
      end
    end

    context "when provided with a finalizer" do
      let(:logger) { stub('Logger') }

      before do
        logger = logger()
        simple_operation.after do
          logger.info("Finalizing")
        end
      end

      it "should invoke the finalizer" do
        logger.should_receive(:info)
        simple_operation.perform
      end
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

      Operation.compose do
        use upcase_operation
        use scream_operation
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

    it "should have successful" do
      upcase_and_scream_operation_instance.should be_successful
    end

    context "when provided with a finalizer and a preparator" do

      let(:logger) { double('logger') }

      before do
        logger = logger()

        upcase_and_scream_operation_instance.before do
          logger.info("Starting operation")
        end

        upcase_and_scream_operation_instance.after do
          logger.info("Stopping operation")
        end
      end

      specify "the logger should have been called twice" do
        logger.should_receive(:info).twice
        upcase_and_scream_operation_instance.perform
      end

    end

  end
end

