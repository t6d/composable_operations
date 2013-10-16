require 'spec_helper'

describe ComposableOperations::Operation, "that always fails:" do
  let(:failing_operation) do
    Class.new(described_class) do
      def execute
        fail "Operation failed"
      end
    end
  end

  context "When no default exception has been specified" do
    it "should raise an error when executed" do
      expect { failing_operation.perform }.to raise_error(ComposableOperations::OperationError, "Operation failed")
    end

    context "when manually instantiated and executed" do
      subject(:failing_operation_instance) do
        operation = failing_operation.new
        operation.perform
        operation
      end

      it "should have nil as result" do
        failing_operation_instance.result.should be_nil
      end

      it "should have failed" do
        failing_operation_instance.should be_failed
      end

      it "should have a message" do
        failing_operation_instance.message.should_not be_nil
      end

      it "should have an exception of type OperationError whose message is 'Operation failed'" do
        failing_operation_instance.exception.should be_kind_of(ComposableOperations::OperationError)
        failing_operation_instance.exception.message.should be == 'Operation failed'
      end
    end

    context "when extended with a finalizer" do
      let(:supervisor) { mock("Supervisor") }

      let(:failing_operation_with_finalizer) do
        supervisor = supervisor()
        Class.new(failing_operation) do
          after { supervisor.notify }
        end
      end

      subject(:failing_operation_with_finalizer_instance) do
        failing_operation_with_finalizer.new
      end

      it "should execute the finalizers" do
        supervisor.should_receive(:notify)
        failing_operation_with_finalizer_instance.perform
      end
    end
  end

  context "When a default exception has been specified" do
    let(:custom_exception) { Class.new(RuntimeError) }

    subject(:failing_operation_with_custom_default_exception) do
      custom_exception = custom_exception()
      Class.new(failing_operation) do
        raises custom_exception
      end
    end

    it "should raise the custom exeception when executed" do
      expect { failing_operation_with_custom_default_exception.perform }.
        to raise_error(custom_exception, "Operation failed")
    end

    context "when manually instantiated and executed" do
      subject(:failing_operation_with_custom_default_exception_instance) do
        operation = failing_operation_with_custom_default_exception.new
        operation.perform
        operation
      end

      it "should have an exception of the custom exception type whose message is 'Operation failed'" do
        failing_operation_with_custom_default_exception_instance.exception.should be_kind_of(custom_exception)
        failing_operation_with_custom_default_exception_instance.exception.message.should be == 'Operation failed'
      end
    end

    context "when subclassed" do
      subject(:failing_operation_with_custom_default_exception_subclass) do
        Class.new(failing_operation_with_custom_default_exception)
      end

      it "should raise the custom exception when executed" do
        expect { failing_operation_with_custom_default_exception_subclass.perform }.
          to raise_error(custom_exception, "Operation failed")
      end
    end
  end

  context "When a custom exception has been specified" do
    let(:custom_exception) { Class.new(RuntimeError) }
    subject(:failing_operation_with_custom_exception) do
      custom_exception = self.custom_exception
      Class.new(described_class) do
        define_method(:execute) do
          fail custom_exception, "Operation failed"
        end
      end
    end

    it "should raise the custom exeception when executed" do
      expect { failing_operation_with_custom_exception.perform }.
        to raise_error(custom_exception, "Operation failed")
    end

    context "when manually instantiated and executed" do
      subject(:failing_operation_with_custom_exception_instance) do
        operation = failing_operation_with_custom_exception.new
        operation.perform
        operation
      end

      it "should have an exception of the custom exception type whose message is 'Operation failed'" do
        failing_operation_with_custom_exception_instance.exception.should be_kind_of(custom_exception)
        failing_operation_with_custom_exception_instance.exception.message.should be == 'Operation failed'
      end
    end

    context "when used in a composed operation" do
      let(:failing_composed_operation) do
        ComposableOperations::ComposedOperation.compose(failing_operation_with_custom_exception)
      end

      it "should raise the custom exception that is thrown by the inner operation when executed" do
        expect { failing_composed_operation.perform }.
          to raise_error(custom_exception, "Operation failed")
      end

      context "when this composed operation is manually instantiated and executed" do
        subject(:failing_composed_operation_instance) do
          operation = failing_composed_operation.new
          operation.perform
          operation
        end

        it "should have an exception of the custom exception type whose message is 'Operation failed'" do
          failing_composed_operation_instance.exception.should be_kind_of(custom_exception)
          failing_composed_operation_instance.exception.message.should be == 'Operation failed'
        end
      end
    end
  end
end

