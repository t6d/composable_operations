class Operation

  include SmartProperties

  class << self

    def perform(*args)
      operation = new(*args)
      operation.perform
      raise exception, operation.message if operation.failed?
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

      def processes(name)
        alias_method name.to_sym, :input
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

      self.result = catch(:halt) do
        finalize
        self.result
      end
    end

    self.result
  end

  protected

    attr_accessor :state

    attr_writer :message
    attr_writer :result

    def execute
      raise NotImplementedError, "#{name}#execute not implemented"
    end

    def fail(message = nil, return_value = nil)
      self.message = message
      self.state = :failed
      throw :halt, return_value
    end

    def halt(message = nil, return_value = input)
      self.message = message
      self.state = :halted
      throw :halt, return_value
    end

    def prepare
      self.class.preparators.each { |preparator| instance_eval(&preparator) }
    end

    def finalize
      self.class.finalizers.each { |finalizer| instance_eval(&finalizer) }
    end

end
