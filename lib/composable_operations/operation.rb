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

    def compose
      operations = @_operations

      Class.new(@_class) do
        define_method :execute do
          operations.inject(input) do |data, operation|
            operation = operation.new(data)
            operation.perform
            self.message = operation.message if operation.failed?
            operation.result
          end
        end
      end
    end

  end

  class << self

    def compose(&instructions)
      Composer.compose(self, &instructions)
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

  def name
    self.class.name.titleize.humanize.gsub('/', ' ')
  end

  def message?
    message.present?
  end

  def failed?
    !result
  end

  def succeeded?
    !!result
  end

  def call
    self.result = catch(:halt) { execute }
  end
  alias_method :perform, :call

  def execute
    raise NotImplementedError, "#{self.class.name}#perform not implemented"
  end

  protected

    attr_writer :message
    attr_writer :result

    def fail(message = nil)
      self.message = message
      throw :halt, nil
    end

end