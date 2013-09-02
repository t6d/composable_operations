require 'spec_helper'

describe ComposableOperations::ComposedOperation, "input forwarding:" do

  describe "An operation pipeline that first constructs an enumerator, then passes it from operation to operation and finally returns it as the result" do

    let(:enum_generator) do
      Class.new(ComposableOperations::Operation) do
        def execute
          %w[just some text].enum_for(:each)
        end
      end
    end

    let(:null_operation) do
      Class.new(ComposableOperations::Operation) do
        processes :enumerator
        def execute
          enumerator
        end
      end
    end

    subject(:pipeline) do
      ComposableOperations::ComposedOperation.compose(enum_generator, null_operation)
    end

    it "should actually return an enumerator" do
      result = pipeline.perform
      result.should be_kind_of(Enumerator)
    end
  end

  describe "An operation pipeline that first constructs an object that responds #to_a, then passes it from operation to operation and finally returns it as the result" do

    let(:dummy) do
      Object.new.tap do |o|
        def o.to_a
          %w[just some text]
        end
      end
    end

    let(:object_representable_as_array_generator) do
      spec_context = self
      Class.new(ComposableOperations::Operation) do
        define_method(:execute) do
          spec_context.dummy
        end
      end
    end

    let(:null_operation) do
      Class.new(ComposableOperations::Operation) do
        processes :object_representable_as_array
        def execute
          object_representable_as_array
        end
      end
    end

    subject(:pipeline) do
      ComposableOperations::ComposedOperation.compose(object_representable_as_array_generator, null_operation)
    end

    it "should actually return this object" do
      result = pipeline.perform
      result.should == dummy
    end
  end

end
