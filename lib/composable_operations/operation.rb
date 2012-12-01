class Operation
  class << self

    def default_configuration
    end

    def execute(data, &configuration)
      new(&configuration).execute(data)
    end

    protected

      def event(name)
        mod = if const_defined?(:Events, false)
          const_get(:Events)
        else
          new_mod = Module.new do
            def self.to_s
              "Events(#{instance_methods(false).join(', ')})"
            end
          end
          const_set(:Events, new_mod)
        end

        mod.module_eval do
          define_method(name) do |*args|
            notify_instruments(name, *args)
          end
        end

        include mod
      end

  end

  attr_accessor :preparator
  attr_accessor :finalizer

  event :will_execute
  event :will_execute_operational_unit
  event :did_execute_operational_unit
  event :did_execute

  def initialize(&configuration)
    @operational_units = []
    @instruments = []

    configuration ||= self.class.default_configuration
    configuration.call(self) unless configuration.nil?
  end

  def instrument(instrument)
    @instruments << instantiate(instrument)
    nil
  end

  def use(operational_unit)
    operational_units.push(operational_unit)
  end

  def call(data)
    return if data.nil?
    data = prepare(data)
    return finalize(data) if operational_units.empty?
    result = execute_operational_units(data)
    finalize(result)
  end
  alias execute call

  protected

    attr_reader :operational_units

    def prepare(data)
      return if data.nil?
      preparator.nil? ? data : instantiate(preparator).call(data)
    end

    def execute_operational_units(data)
      will_execute(data)
      success = true
      operational_units.each do |operational_unit|
        data = execute_operational_unit(operational_unit, data)
        success = !!data
        break unless success
      end
      did_execute(data, success)
      data
    end

    def execute_operational_unit(operational_unit, data)
      operational_unit = instantiate(operational_unit)

      will_execute_operational_unit(operational_unit, data)
      data = operational_unit.call(data)
      success = !!data
      did_execute_operational_unit(operational_unit, data, success)

      data
    end

    def finalize(data)
      return if data.nil?
      finalizer.nil? ? data : instantiate(finalizer).call(data)
    end

    def instantiate(value)
      value.is_a?(Class) ? value.new : value
    end

    def notify_instruments(event, *args)
      (@instruments || []).each do |subscriber|
        subscriber.public_send("on_#{event}", self, *args)
      end
    end

end