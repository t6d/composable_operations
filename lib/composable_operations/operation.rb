class Operation

  include SmartProperties

  class << self

    def perform(*args)
      operation = new(*args)
      operation.perform
      raise exception, operation.message, operation.backtrace if operation.failed?
      operation.result
    end

    def identifier
      name.to_s.underscore.split('/').reverse.join('.') + ".operation"
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
      @exception or defined?(super) ? super : RuntimeError
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
        when 1
          alias_method names[0].to_sym, :input
        else
          names.each_with_index do |name, index|
            define_method(name) { input[index] }
          end
        end
      end

      def raises(exception)
        @exception = exception
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

  def initialize(input = nil, options = {})
    super(options)
    @input = input
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
    ActiveSupport::Notifications.instrument(self.class.identifier, :operation => self) do
      self.result = catch(:halt) do
        prepare
        result = execute
        self.state = :succeeded
        result
      end

      finalize
    end

    self.result
  end

  protected

    attr_accessor :state

    attr_writer :message
    attr_writer :result
    attr_writer :backtrace

    def execute
      raise NotImplementedError, "#{name}#execute not implemented"
    end

    def fail(message = nil, return_value = nil, backtrace = caller)
      raise "Operation execution has already been aborted" if halted? or failed?

      self.state = :failed
      self.backtrace = backtrace
      self.message = message
      throw :halt, return_value
    end

    def halt(message = nil, return_value = input)
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
