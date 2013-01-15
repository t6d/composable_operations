class Operation

  include SmartProperties

  class << self

    def perform(*args)
      new(*args).perform
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
    !result
  end

  def succeeded?
    !!result
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
        execute
      end
      finalize
    end

    self.result
  end

  protected

    attr_writer :message
    attr_writer :result

    def execute
      raise NotImplementedError, "#{name}#execute not implemented"
    end

    def fail(message = nil)
      self.message = message
      throw :halt, nil
    end

    def prepare
      self.class.preparators.each { |preparator| instance_eval(&preparator) }
    end

    def finalize
      self.class.finalizers.each { |finalizer| instance_eval(&finalizer) }
    end

end
