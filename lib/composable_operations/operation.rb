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
            notify_subscribers(name, *args)
          end
        end

        include mod
      end

  end

  event :will_execute
  event :will_execute_operational_unit
  event :did_execute_operational_unit
  event :did_execute

  def initialize(&configuration)
    @operational_units = []

    configuration ||= self.class.default_configuration
    configuration.call(self) unless configuration.nil?
  end

  def subscribers
    @subscribers.dup
  end

  def subscribe(subscriber)
    (@subscribers ||= []) << subscriber
  end

  def unsubscribe(subscriber)
    (@subscribers || []).remove(subscriber)
  end

  def use(operational_unit)
    operational_units.push(operational_unit)
  end

  def call(data)
    return true if operational_units.empty?

    will_execute(data)

    success = true
    operational_units.each do |operational_unit|
      if !execute_operational_unit(operational_unit, data)
        success = false
        break
      end
    end

    did_execute(data, success)

    success ? data : nil
  end
  alias execute call

  protected

    attr_reader :operational_units

    def execute_operational_unit(operational_unit, data)
      operational_unit = instantiate(operational_unit)
      will_execute_operational_unit(operational_unit, data)
      success = !!operational_unit.call(data)
      did_execute_operational_unit(operational_unit, data, success)
      success
    end

    def instantiate(value)
      value.is_a?(Class) ? value.new : value
    end

    def notify_subscribers(event, *args)
      (@subscribers || []).each do |subscriber|
        subscriber.public_send("on_#{event}", self, *args)
      end
    end

end