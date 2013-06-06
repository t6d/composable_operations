require 'spec_helper'

describe "An operation with two before and two after filters =>" do

  Operation = ::ComposableOperations::Operation

  class TestOperation < Operation

    processes :flow_control

    attr_accessor :trace

    def initialize(input = [], options = {})
      super
      self.trace = [:initialize]
    end

    before do
      trace << :outer_before
      fail "Fail in outer before" if flow_control.include?(:fail_in_outer_before)
      halt "Halt in outer before" if flow_control.include?(:halt_in_outer_before)
    end

    before do
      trace << :inner_before
      fail "Fail in inner before" if flow_control.include?(:fail_in_inner_before)
      halt "Halt in inner before" if flow_control.include?(:halt_in_inner_before)
    end

    after do
      trace << :inner_after
      fail "Fail in inner after" if flow_control.include?(:fail_in_inner_after)
      halt "Halt in inner after" if flow_control.include?(:halt_in_inner_after)
    end

    after do
      trace << :outer_after
      fail "Fail in outer after" if flow_control.include?(:fail_in_outer_after)
      halt "Halt in outer after" if flow_control.include?(:halt_in_outer_after)
    end

    def execute
      trace << :execute_start
      fail "Fail in execute" if flow_control.include?(:fail_in_execute)
      halt "Halt in execute" if flow_control.include?(:halt_in_execute)
      trace << :execute_stop
      :final_result
    end
  end

  context "when run and everything works as expected =>" do
    subject       { TestOperation.new }
    before(:each) { subject.perform }

    it ("should run 'initialize' first")                    { subject.trace[0].should eq(:initialize)    }
    it ("should run 'outer before' after 'initialize'")     { subject.trace[1].should eq(:outer_before)  }
    it ("should run 'inner before' after 'outer before'")   { subject.trace[2].should eq(:inner_before)  }
    it ("should start 'execute' after 'inner before'")      { subject.trace[3].should eq(:execute_start) }
    it ("should stop 'execute' after it started 'execute'") { subject.trace[4].should eq(:execute_stop)  }
    it ("should run 'inner after' after 'execute'")         { subject.trace[5].should eq(:inner_after)   }
    it ("should run 'outer after' after 'inner after'")     { subject.trace[6].should eq(:outer_after)   }
    it ("should return :final_result as result")            { subject.result.should eq(:final_result) }
    it { should     be_succeeded }
    it { should_not be_failed    }
    it { should_not be_halted    }
  end


  # Now: TEST ALL! the possible code flows systematically

  test_vectors = [
    {
      :context => "no complications =>",
      :input   => [],
      :output  => :final_result,
      :trace   => [:initialize, :outer_before, :inner_before, :execute_start, :execute_stop, :inner_after, :outer_after],
      :state   => :succeeded
    }, {
      :context => "failing in outer_before filter =>",
      :input   => [:fail_in_outer_before],
      :output  => nil,
      :trace   => [:initialize, :outer_before, :inner_after, :outer_after],
      :state   => :failed
    }, {
      :context => "failing in inner_before filter =>",
      :input   => [:fail_in_inner_before],
      :output  => nil,
      :trace   => [:initialize, :outer_before, :inner_before, :inner_after, :outer_after],
      :state   => :failed
    }, {
      :context => "failing in execute =>",
      :input   => [:fail_in_execute],
      :output  => nil,
      :trace   => [:initialize, :outer_before, :inner_before, :execute_start, :inner_after, :outer_after],
      :state   => :failed
    }, {
      :context => "failing in inner_after filter =>",
      :input   => [:fail_in_inner_after],
      :output  => nil,
      :trace   => [:initialize, :outer_before, :inner_before, :execute_start, :execute_stop, :inner_after, :outer_after],
      :state   => :failed
    }, {
      :context => "failing in outer_after filter =>",
      :input   => [:fail_in_outer_after],
      :output  => nil,
      :trace   => [:initialize, :outer_before, :inner_before, :execute_start, :execute_stop, :inner_after, :outer_after],
      :state   => :failed
    }, {
      :context => "halting in outer_before filter =>",
      :input   => [:halt_in_outer_before],
      :output  => [:halt_in_outer_before],
      :trace   => [:initialize, :outer_before, :inner_after, :outer_after],
      :state   => :halted
    }, {
      :context => "halting in inner_before filter =>",
      :input   => [:halt_in_inner_before],
      :output  => [:halt_in_inner_before],
      :trace   => [:initialize, :outer_before, :inner_before, :inner_after, :outer_after],
      :state   => :halted
    }, {
      :context => "halting in execute =>",
      :input   => [:halt_in_execute],
      :output  => [:halt_in_execute],
      :trace   => [:initialize, :outer_before, :inner_before, :execute_start, :inner_after, :outer_after],
      :state   => :halted
    }, {
      :context => "halting in inner_after filter =>",
      :input   => [:halt_in_inner_after],
      :output  => [:halt_in_inner_after],
      :trace   => [:initialize, :outer_before, :inner_before, :execute_start, :execute_stop, :inner_after, :outer_after],
      :state   => :halted
    }, {
      :context => "halting in outer_after filter =>",
      :input   => [:halt_in_outer_after],
      :output  => [:halt_in_outer_after],
      :trace   => [:initialize, :outer_before, :inner_before, :execute_start, :execute_stop, :inner_after, :outer_after],
      :state   => :halted
    }
  ]

  context "when initialized with input that leads to =>" do
    subject { TestOperation.new(input) }
    before(:each) { subject.perform }

    test_vectors.each do |tv|
      context tv[:context] do
        let(:input) { tv[:input] }
        let(:trace) { subject.trace }

        it("then its trace should be #{tv[:trace].inspect}") { subject.trace.should eq(tv[:trace]) }
        it("then its result should be #{tv[:output].inspect}") { subject.result.should eq(tv[:output]) }
        it("then its succeeded? method should return #{(tv[:state] == :succeeded).inspect}") { subject.succeeded?.should eq(tv[:state] == :succeeded) }
        it("then its failed? method should return #{(tv[:state] == :failed).inspect}") { subject.failed?.should    eq(tv[:state] == :failed)    }
        it("then its halted? method should return #{(tv[:state] == :halted).inspect}") { subject.halted?.should    eq(tv[:state] == :halted)    }
      end
    end
  end

  context "when halt and fail are used together" do
    subject { TestOperation.new([:halt_in_execute, :fail_in_inner_after]) }
    it "should raise on calling operation.perform" do
      expect { subject.perform }.to raise_error
    end
  end

  context "when fail and halt are used together" do
    subject { TestOperation.new([:fail_in_execute, :halt_in_inner_after]) }
    it "should raise on calling operation.perform" do
      expect { subject.perform }.to raise_error
    end
  end

  context "when halt is used twice" do
    subject { TestOperation.new([:halt_in_execute, :halt_in_inner_after]) }
    it "should raise on calling operation.perform" do
      expect { subject.perform }.to raise_error
    end
  end

  context "when fail is used twice" do
    subject { TestOperation.new([:fail_in_execute, :fail_in_inner_after]) }
    it "should raise on calling operation.perform" do
      expect { subject.perform }.to raise_error
    end
  end

end

describe ComposableOperations::Operation do

  Operation = ::ComposableOperations::Operation

  context "that always returns nil when executed" do

    subject(:nil_operation) do
      class << (operation = Operation.new(''))
        def execute
          nil
        end
      end
      operation
    end

    it { should succeed_to_perform.and_return(nil) }

  end

  context "that always halts" do

    let(:halting_operation) do
      Class.new(Operation) do
        def execute
          halt "Full stop!"
        end
      end
    end

    let(:halting_operation_instance) do
      halting_operation.new("Test")
    end

    it "should return the input value when executed using the class' method perform" do
      halting_operation.perform("Test").should be == "Test"
    end

    it "should return the input value when executed using the instance's peform method" do
      halting_operation_instance.perform.should be == "Test"
    end

    it "should have halted after performing" do
      halting_operation_instance.perform
      halting_operation_instance.should be_halted
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
      failing_operation_instance.message.should_not be_nil
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

    context "when configured to raise a custom exception" do

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

      context "that provides additional meta data", pending: true do

        let(:custom_exception_with_meta_data) { Class.new(custom_exception) { include Bugsnag::MetaData } }

        subject(:failing_operation_with_meta_data_enabled_exception) do
          custom_exception_with_meta_data = custom_exception_with_meta_data()
          Class.new(failing_operation) do
            raises custom_exception_with_meta_data do
              { severity: severity }
            end
            def severity
              :high
            end
          end
        end

        specify "this meta data should be accessible when examining the exception" do
          begin
            failing_operation_with_meta_data_enabled_exception.perform
          rescue custom_exception_with_meta_data => e
            e.bugsnag_meta_data.should be == { severity: :high }
          end
        end

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

    context "when extended with a finalizer that checks that the result is not an empty string" do

      let(:simple_operation_with_sanity_check) do
        Class.new(simple_operation) do
          after { fail "the operational result is an empty string" if self.result == "" }
        end
      end

      subject(:simple_operation_with_sanity_check_instance) do
        simple_operation_with_sanity_check.new
      end

      it { should fail_to_perform.because("the operational result is an empty string") }

    end

  end

  context "event handling:", pending: true do

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

  context "that processes two values (a string and a multiplier)" do

    subject(:string_multiplier) do
      Class.new(Operation) do
        processes :string, :multiplier

        def execute
          string * multiplier
        end
      end
    end

    it "should build a string that is multiplier-times long" do
      string_multiplier.perform(["-", 3]).should be == "---"
    end

  end

end

