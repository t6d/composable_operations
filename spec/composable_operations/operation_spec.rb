require 'spec_helper'

describe Operation do

  let(:operation) { described_class.new }

  subject { operation }

  it "should provide a convenience method for execution" do
    described_class.execute('').should be
  end

  context "when provided with an empty configuration block" do

    specify "the preparation should be successful" do
      operation.execute('').should be
    end

    context "when provided with an operational unit that always fails" do

      before do
        operation.use lambda { |data| false }
      end

      specify "the preparation should not be successful" do
        operation.execute('').should_not be
      end

      context "when instrumented with a simple logger" do

        let(:logger) do
          class << (logger = Object.new.extend(OperationTracking))
            attr_reader :result

            def on_did_execute(sender, data, success)
              @result = success ? "Preparation succeeded" : "Preparation failed"
            end
          end

          logger
        end

        before do
          operation.instrument(logger)
          operation.execute('')
        end

        specify "the logger should have stored the correct result" do
          logger.result.should be == "Preparation failed"
        end

      end

    end

    context "when using an operational unit that checks whether or not the given data contains the phrase 'chunky bacon'" do

      let(:operational_unit) do
        Class.new(OperationalUnit) do

          def self.name
            "ChunkyBaconChecker"
          end

          def execute(data)
            fail("the data does not contain the phrase 'chunky bacon'") unless !!(/chunky bacon/.match(data))
            succeed
          end

        end
      end

      let(:logger) do
        class << (logger = Object.new.extend(OperationTracking))

          def messages
            @messages ||= []
          end

          def on_did_execute_operational_unit(sender, operational_unit, data, success)
            messages << [operational_unit.description, (success ? 'succeeded' : "failed because #{operational_unit.reason}")].join(' ')
          end

        end

        logger
      end

      let(:last_message) { logger.messages.last }

      before do
        operation.instrument(logger)
        operation.use operational_unit
      end

      context "when the processed data does not contain the correct phrase" do

        let!(:result) { operation.execute('crispy bacon') }

        specify "the preparation should be not successful" do
          result.should_not be
        end

        specify "the last log message should state that something went wrong" do
          last_message.should be == "Chunky bacon checker failed because the data does not contain the phrase 'chunky bacon'"
        end

      end

      context "when the processed data contains the correct phrase" do

        let!(:result) { operation.execute('chunky bacon') }

        specify "the preparation should be successful" do
          result.should be == 'chunky bacon'
        end

        specify "the last log message should state that everything went well" do
          last_message.should be == 'Chunky bacon checker succeeded'
        end

      end

    end

    context "when the operation has a finalizer" do

      subject(:result) { operation.execute('chunky bacon') }

      before do
        operation.finalizer = lambda { |data| data.upcase }
      end

      specify "the result should be converted using the finalizer" do
        result.should be == 'CHUNKY BACON'
      end

      context "when the operation has an operational unit that always fails" do

        before do
          operation.use lambda { |*| false }
        end

        specify "the result shold be nil" do
          result.should be_nil
        end

      end

    end

    context "when a operation has a operational unit that expects the string 'CHUNKY BACON'" do

      subject(:result) { operation.execute('chunky bacon') }

      before do
        operation.use lambda { |data| data == 'CHUNKY BACON' }
      end

      it "should fail when provided with a string that contains lowercase characters" do
        result.should be_nil
      end

      context "when the operation has a preparator that upcases all data" do

        before do
          operation.preparator = lambda { |data| data.upcase }
        end

        it "should succeed when provided with the string 'chunky bacon'" do
          result.should be == 'CHUNKY BACON'
        end

      end

    end

  end

end