module ComposableOperations
  class Operation

    include SmartProperties

    class << self
      def arguments
        []
      end

      def arity
        arguments.count
      end

      def perform(*args)
        operation = new(*args)
        operation.perform

        raise operation.exception if operation.failed?

        operation.result
      end

      def preparators
        preparators = []
        klass = self
        while klass != Operation
          klass = klass.superclass
          preparators += Array(klass.instance_variable_get(:@preparators))
        end
        preparators += Array(@preparators)
        preparators
      end

      def finalizers
        finalizers = []
        klass = self
        while klass != Operation
          klass = klass.superclass
          finalizers += Array(klass.instance_variable_get(:@finalizers))
        end
        finalizers += Array(@finalizers)
        finalizers
      end

      def exception
        OperationError
      end

      protected

        def before(&callback)
          (@preparators ||= []) << callback
        end

        def after(&callback)
          (@finalizers ||= []) << callback
        end

        def processes(*names)
          case names.length
          when 0
            raise ArgumentError, "#{self}.#{__callee__} expects at least one argument"
          else
            names.each { |name| property(name, required: true) unless properties.key?(name) }
            define_singleton_method(:arguments) { names }
          end
        end

        def raises(exception)
          define_singleton_method(:exception) { exception }
        end

      private

        def method_added(method)
          super
          protected method if method == :execute
        end

    end

    attr_reader :input
    attr_reader :result
    attr_reader :message
    attr_reader :backtrace
    attr_reader :exception

    def initialize(*args)
      arity = self.class.arity
      arguments = args.shift(arity)
      attributes = args.last.kind_of?(Hash) ? args.pop : {}

      raise ArgumentError, "wrong number of arguments #{arguments.length + args.length} for #{arity}" unless args.empty?

      self.class.arguments.each_with_index do |name, index|
        attributes[name] = arguments[index]
      end

      super(attributes)
    end

    def input
      self.class.arguments.map { |name| self[name] }
    end

    def failed?
      state == :failed
    end

    def halted?
      state == :halted
    end

    def succeeded?
      state == :succeeded
    end

    def message?
      message.present?
    end

    def name
      self.class.name
    end

    def perform
      self.result = catch(:halt) do
        prepare
        result = execute
        self.state = :succeeded
        result
      end

      finalize

      self.result
    end

    protected

      attr_accessor :state

      attr_writer :message
      attr_writer :result
      attr_writer :backtrace
      attr_writer :exception

      def execute
        raise NotImplementedError, "#{name}#execute not implemented"
      end

      def fail(*args)
        raise "Operation execution has already been aborted" if halted? or failed?
        exception, message, backtrace = nil, nil, nil

        case args.length
        when 1
          value = args[0]
          if Exception === value
            exception = value
          elsif Class === value && Exception > value
            exception = value
            message = value.message
            backtrace = value.backtrace
          else
            message = value
          end
        when 2, 3
          exception, message, backtrace = args[0], args[1], args[2]
        end

        backtrace ||= caller
        exception ||= self.class.exception
        exception = Class === exception ? exception.new(message) : exception
        exception.set_backtrace(backtrace)

        self.state = :failed
        self.backtrace = backtrace
        self.message = message
        self.exception = exception
        throw :halt, nil
      end

      def halt(message = nil, return_value = nil)
        raise "Operation execution has already been aborted" if halted? or failed?

        self.state = :halted
        self.message = message
        throw :halt, return_value
      end

      def prepare
        self.class.preparators.each { |preparator| instance_eval(&preparator) }
      end

      def finalize
        self.class.finalizers.each do |finalizer|
          self.result = catch(:halt) do
            instance_eval(&finalizer)
            self.result
          end
        end
      end

  end
end
