# ComposableOperations

Composable Operations is a tool set for creating operations and assembling
multiple of these operations in operation pipelines.  An operation is, at its
core, an implementation of the [strategy
pattern](http://en.wikipedia.org/wiki/Strategy_pattern) and in this sense an
encapsulation of an algorithm. An operation pipeline is an assembly of multiple
operations and useful for implementing complex algorithms. Pipelines themselves
can be part of other pipelines.

## Installation

Add this line to your application's Gemfile:

    gem 'composable_operations'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install composable_operations

## Usage

Operations can be defined by subclassing `ComposableOperations::Operation` and
operation pipelines by subclassing `ComposableOperations::ComposedOperation`.

### Defining an Operation

To define an operation, two steps are necessary:

1. create a new subclass of `ComposableOperations::Operation`, and
2. implement the `#execute` method.

The listing below shows an operation that extracts a timestamp in the format
`yyyy-mm-dd` from a string.

```ruby
class DateExtractor < ComposableOperations::Operation

  processes :text

  def execute
    text.scan(/(\d{4})-(\d{2})-(\d{2})/)
  end

end
```

The macro method `.processes` followed by a single argument denotes that the
operation expects a single object as input and results in the definition of a
getter method named as specified by this argument. The macro method can also be
called with multiple arguments resulting in the creation of multiple getter
methods. The latter is useful if the operation requires more than one object as
input to operate. Calling the macro method is entirely optional. An operation's
input can always be accessed by calling the getter method `#input`. This method
returns either a single object or an array of objects.

There are two ways to execute this operation:

1. create a new instance of this operation and call `#perform`, or
2. directly call `.perform` on the operation class.

The major difference between these two approaches is that in case of a failure
the latter raises an exception while the former returns `nil` and sets the
operation's state to `failed`. For more information on canceling the execution
of an operation, see below. Please note that directly calling the `#execute`
method is prohibited. To enforce this constraint, the method is automatically
marked as protected upon definition.

The listing below demonstrates how to execute the operation defined above.

```ruby
text = "This gem was first published on 2013-06-10."

extractor = DateExtractor.new(text)
extractor.perform # => [["2013", "06", "10"]]

DateExtractor.perform(text) # => [["2013", "06", "10"]]
```

### Defining an Operation Pipeline

Assume that we are provided an operation that converts these arrays of strings
into actual `Time` objects. The following listing provides a potential
implementation of such an operation.

```ruby
class DateArrayToTimeObjectConverter < ComposableOperations::Operation

  processes :collection_of_date_arrays

  def execute
    collection_of_date_arrays.map do |date_array|
      Time.new(*(date_array.map(&:to_i)))
    end
  end

end
```

Using these two operations, it is possible to create a composed operation that
extracts dates from a string and directly converts them into `Time` objects. To
define a composed operation, two steps are necessary:

1. create a subclass of `ComposableOperations::ComposedOperation`, and
2. use the macro method `use` to assemble the operation.

The listing below shows how to assemble the two operations, `DateExtractor` and
`DateArrayToTimeObjectConverter`, into a composed operation named `DateParser`.

```ruby
class DateParser < ComposableOperations::ComposedOperation

  use DateExtractor
  use DateArrayToTimeObjectConverter

end
```

Composed operations provide the same interface as normal operations. Hence,
they can be invoked the same way. For the sake of completeness, the listing
below shows how to use the `DateParser` operation.

```ruby
text = "This gem was first published on 2013-06-10."

parser = DateParser.new(text)
parser.perform # => 2013-06-07 00:00:00 +0200

DateParser.perform(text) # => 2013-06-07 00:00:00 +0200
```

### Control Flow

An operation can be *halted* or *aborted* if a successful execution is not
possible. Aborting an operation will result in an exception if the operation
was invoked using the class method `.perform`. If the operation was invoked
using the instance method `#perform`, the operation's state will be updated
accordingly, but no exception will be raised. The listing below provides, among
other things, examples on how to access an operation's state.

```ruby
class StrictDateParser < DateParser

  def execute
    result = super
    fail "no timestamp found" if result.empty?
    result
  end

end

class LessStrictDateParser < DateParser

  def execute
    result = super
    halt "no timestamp found" if result.empty?
    result
  end

end

parser = StrictDateParser.new("")
parser.message # => "no timestamp found"
parser.perform # => nil
parser.succeeded? # => false
parser.halted? # => false
parser.failed? # => true

StrictDateParser.perform("") # => ComposableOperations::OperationError: no timestamp found

parser = LessStricDateParser.new("")
parser.message # => "no timestamp found"
parser.perform # => nil
parser.succeeded? # => false
parser.halted? # => true
parser.failed? # => false

StrictDateParser.perform("") # => nil
```

Instead of cluttering the `#execute` method with sentinel code or in general
with code that is not part of an operation's algorithmic core, we can move this
code into `before` or `after` callbacks. The listing below provides an alternative
implementation of the `StrictDateParser` operation.


```ruby
class StrictDateParser < DateParser

  after do
    fail "no timestamp found" if result.empty?
  end

end

parser = StrictDateParser.new("")
parser.message # => "no timestamp found"
parser.perform # => nil
parser.failed? # => true

StrictDateParser.perform("") # => ComposableOperations::OperationError: no timestamp found
```

### Configuring Operations

Operations and composed operations support
[SmartProperties](http://github.com/t6d/smart_properties) to conveniently
provide additional settings upon initialization of an operation. In the
example below, an operation is defined that indents a given string. The indent
is set to 2 by default but can easily be changed by supplying an options hash
to the initializer.

```ruby
class Indention < ComposableOperations::Operation

  processes :text

  property :indent, default: 2,
                    converts: lambda { |value| value.to_s.to_i },
                    accepts: lambda { |value| value >= 0 },
                    required: true

  def execute
    text.split("\n").map { |line| " " * indent + line }.join("\n")
  end

end

Indention.perform("Hello World", indent: 4) # => "    Hello World"
```

Operations that are part of an composed operation can be configured by calling
the `.use` method with a hash of options as the second argument. See the
listing below for an example.

```ruby
class SomeComposedOperation < ComposableOperations::ComposedOperation

  # ...
  use Indention, indent: 4
  # ...

 end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
