class Operation
  class Composer

    def self.compose(klass, &instructions)
      composer = new(klass)
      composer.instance_eval(&instructions)
      composer.compose
    end

    def initialize(klass)
      @_class = klass
    end

    def use(operation)
      (@_operations ||= []) << operation
    end

    def before(&callback)
      @_preparator = callback
    end

    def after(&callback)
      @_finalizer = callback
    end

    def compose
      operations = @_operations
      preparator = @_preparator
      finalizer = @_finalizer

      Class.new(@_class) do
        define_method :execute do
          operations.inject(input) do |data, operation|
            operation = operation.new(data)
            operation.perform
            if operation.failed?
              self.message = operation.message
              break
            end
            operation.result
          end
        end

        define_method :default_preparator do
          preparator
        end

        define_method :default_finalizer do
          finalizer
        end
      end
    end

  end

  class << self

    def compose(&instructions)
      Composer.compose(self, &instructions)
    end

    def perform(*args)
      new(*args).perform
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

  def initialize(input)
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
    self.class.name.titleize.humanize.gsub('/', ' ')
  end

  def before(&callback)
    self.preparator = callback
  end

  def after(&callback)
    self.finalizer = callback
  end

  def perform
    prepare
    result = catch(:halt) { execute }
    finalize

    self.result = result
  end

  protected

    attr_writer :message
    attr_writer :result

    attr_writer :preparator
    attr_writer :finalizer

    def execute
      raise NotImplementedError, "#{self.class.name}#perform not implemented"
    end

    def fail(message = nil)
      self.message = message
      throw :halt, nil
    end

    def default_preparator
    end

    def preparator
      @preparator || default_preparator
    end

    def default_finalizer
    end

    def finalizer
      @finalizer || default_finalizer
    end

    def finalize
      instance_eval(&finalizer) if finalizer
    end

    def prepare
      instance_eval(&preparator) if preparator
    end

end
