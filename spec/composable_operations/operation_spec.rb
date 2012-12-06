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

    it "should have succeeded" do
      simple_operation.should be_succeeded
    end

  end

end
