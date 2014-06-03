require 'spec_helper'

describe ComposableOperations::Operation do

  context "that always returns nil when executed" do

    subject(:nil_operation) do
      class << (operation = described_class.new(''))
        def execute
          nil
        end
      end
      operation
    end

    it { is_expected.to succeed_to_perform.and_return(nil) }

  end

  context "that always halts and returns its original input" do

    let(:halting_operation) do
      Class.new(described_class) do
        def execute
          halt "Full stop!", input.first
        end
      end
    end

    let(:halting_operation_instance) do
      halting_operation.new("Test")
    end

    it "should return the input value when executed using the class' method perform" do
      expect(halting_operation.perform("Test")).to be == "Test"
    end

    it "should return the input value when executed using the instance's peform method" do
      expect(halting_operation_instance.perform).to be == "Test"
    end

    it "should have halted after performing" do
      halting_operation_instance.perform
      expect(halting_operation_instance).to be_halted
    end

  end

  context "that always returns something when executed" do

    let(:simple_operation) do
      Class.new(described_class) do
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
      expect(simple_operation_instance.result).to be
    end

    it "should have succeeded" do
      expect(simple_operation_instance).to be_succeeded
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
        expect(logger).to receive(:info).ordered.with("preparing")
        expect(logger).to receive(:info).ordered.with("finalizing")
        simple_operation_with_preparator_and_finalizer.perform
      end

    end

    context "when extended with a finalizer that checks that the result is not an empty string" do

      subject(:simple_operation_with_sanity_check) do
        Class.new(simple_operation) do
          after { fail "the operational result is an empty string" if self.result == "" }
        end
      end

      it { is_expected.to fail_to_perform.because("the operational result is an empty string") }

    end

  end

  context "that can be parameterized" do

    subject(:string_multiplier) do
      Class.new(described_class) do
        processes :text
        property :multiplier, :default => 3

        def execute
          text.to_s * multiplier
        end
      end
    end

    it { is_expected.to succeed_to_perform.when_initialized_with("-").and_return("---") }
    it { is_expected.to succeed_to_perform.when_initialized_with("-", multiplier: 5).and_return("-----") }

  end

  context "that processes two values (a string and a multiplier)" do

    subject(:string_multiplier) do
      Class.new(described_class) do
        processes :string, :multiplier

        def execute
          string * multiplier
        end
      end
    end

    it { is_expected.to succeed_to_perform.when_initialized_with("-", 3).and_return("---") }

  end

end

