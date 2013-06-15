require "spec_helper"

describe ComposableOperations::ComposedOperation do

  let(:string_generator) do
    Class.new(ComposableOperations::Operation) do
      def self.name
        "StringGenerator"
      end

      def execute
        "chunky bacon"
      end
    end
  end

  let(:string_capitalizer) do
    Class.new(ComposableOperations::Operation) do
      def self.name
        "StringCapitalizer"
      end

      def execute
        input.upcase
      end
    end
  end

  let(:halting_operation) do
    Class.new(ComposableOperations::Operation) do
      def execute
        halt
      end
    end
  end

  context "when composed of one operation that generates a string no matter the input" do

    subject(:composed_operation) do
      operation = string_generator

      Class.new(described_class) do
        use operation
      end
    end

    it "should return this string as result" do
      composed_operation.perform(nil).should be == "chunky bacon"
    end

  end

  context "when composed of two operations using the factory method '#chain'" do
  context "when composed of two operations using the factory method '.compose'" do

    subject(:composed_operation) do
      described_class.compose(string_generator, string_capitalizer).new
    end

    it { should succeed_to_perform.and_return("CHUNKY BACON") }

    it { should utilize_operations(string_generator, string_capitalizer) }

  end

  context "when composed of two operations, one that generates a string and one that capitalizes strings, " do

    subject(:composed_operation) do
      operations = [string_generator, string_capitalizer]

      Class.new(described_class) do
        use operations.first
        use operations.last
      end
    end

    it "should return a capitalized version of the generated string" do
      composed_operation.perform(nil).should be == "CHUNKY BACON"
    end

    it { should utilize_operations(string_generator, string_capitalizer) }

  end

  context "when composed of three operations, one that generates a string, one that halts and one that capatalizes strings" do

    subject(:composed_operation) do
      described_class.compose(string_generator, halting_operation, string_capitalizer)
    end

    it "should return a capitalized version of the generated string" do
      composed_operation.perform.should be == nil
    end

    it "should only execute the first two operations" do
      string_generator.any_instance.should_receive(:perform).and_call_original
      halting_operation.any_instance.should_receive(:perform).and_call_original
      string_capitalizer.any_instance.should_not_receive(:perform)
      composed_operation.perform
    end

    it { should utilize_operations(string_generator, halting_operation, string_capitalizer) }
  end

end
