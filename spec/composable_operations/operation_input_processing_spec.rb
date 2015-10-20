require 'spec_helper'

describe ComposableOperations::Operation, "input processing:" do
  describe "An operation that takes a Hash as input" do
    let(:input) { {food: "chunky bacon" } }

    subject(:operation) do
      Class.new(described_class) do
        processes :some_hash
        def execute
          some_hash
        end
      end
    end

    it { is_expected.to succeed_to_perform.when_initialized_with(input).and_return(input) }
  end

  describe "An operation that takes a Hash as input and an Hash of additional options" do
    let(:input) { { food: nil } }

    subject(:operation) do
      Class.new(described_class) do
        processes :some_hash
        property :default_food, default: "chunky bacon"
        def execute
          some_hash[:food] ||= default_food
          some_hash
        end
      end
    end

    it { is_expected.to succeed_to_perform.when_initialized_with(input, default_food: "bananas").and_return(food: "bananas") }
    it { is_expected.to succeed_to_perform.when_initialized_with(input).and_return(food: "chunky bacon") }
  end

  describe "An operation that takes two named arguments as input and sums them up" do
    subject(:operation) do
      Class.new(described_class) do
        processes :first_operand, :second_operand
        def execute
          first_operand + second_operand
        end
      end
    end

    it { is_expected.to succeed_to_perform.when_initialized_with(1, 2).and_return(3) }
  end

  describe "An operation that takes two named arguments as input and simply returns all input arguments as output" do
    subject(:operation) do
      Class.new(described_class) do
        processes :first_operand, :second_operand
        def execute
          input
        end
      end
    end

    it { is_expected.to succeed_to_perform.when_initialized_with(1, 2).and_return([1, 2]) }
  end

  describe "An operation that takes multiple arguments as input where the last of these arguments is a Hash" do
    subject(:operation) do
      Class.new(described_class) do
        processes :first_operand, :second_operand
        property :operator, default: :+, converts: :to_sym, required: true
        def execute
          first_operand.public_send(operator, second_operand)
        end
      end
    end

    it { is_expected.to succeed_to_perform.when_initialized_with(1, 2).and_return(3) }
    it { is_expected.to succeed_to_perform.when_initialized_with(1, 2, operator: :*).and_return(2) }
  end

  describe "An operation that takes a named argument and uses the setter for the named argument" do
    subject(:operation) do
      Class.new(described_class) do
        processes :some_value
        def execute
          self.some_value = "changed"
          self.some_value
        end
      end
    end

    it { is_expected.to succeed_to_perform.when_initialized_with("unchanged").and_return("changed") }
  end

  describe "An operation that manually defines a property for its first input argument that upcases its assgined value" do
    subject(:operation) do
      Class.new(described_class) do
        property :text, converts: :upcase
        processes :text

        def execute
          text
        end
      end
    end

    it { is_expected.to succeed_to_perform.when_initialized_with("hello").and_return("HELLO") }
  end
end

describe ComposableOperations::ComposedOperation, "input processing:" do
  describe "A composed operation that consists of a producer and a consumer" do
    let(:producer) do
      Class.new(ComposableOperations::Operation) do
        def execute
          return 1, 2
        end
      end
    end

    let(:consumer) do
      Class.new(ComposableOperations::Operation) do
        processes :first_operand, :second_operand
        def execute
          first_operand + second_operand
        end
      end
    end

    subject(:operation) do
      producer = self.producer
      consumer = self.consumer

      Class.new(described_class) do
        use producer
        use consumer
      end
    end

    it { is_expected.to succeed_to_perform.and_return(3) }
  end
end

