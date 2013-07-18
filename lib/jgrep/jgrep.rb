# Given query string
#
# sum('foo.bar', 'bar.bar') = foo.bar and bar.bar
#
# This translates to :
#
# - call the sum function with params (foo.bar, bar.bar)
# - compare its result with value of bar.bar
# - lookup bar.bar
# - There is no comparison so return true if bar.bar exists, false if it doesn't
#
# Sample parse result
# {:lookups => ['foo.bar', 'bar.bar'],
#  :functions => [:sum, :mutiply, :etc],
#  :callstack => [ {:type => :function,
#                   :params => [{:type => :constant,
#                                :value => 10},
#                                {:type => :lookup,
#                                 :value => 'foo.bar'
#                                }],
#                   :name => :sum},
#                   {:type => :coperator,
#                    :value => '=='},
#                   {:type => :lookup,
#                    :value => 'bar.baz'},
#                   {:type => :loperator,
#                    :value => 'and'},
#                   {:type => 'lookup',
#                    :value => 'bar.bar'}
# }
module JGrep
  class JGrep
    attr_accessor :functions, :target

    def initialize(target, parser_output, type = :none, start_at = :root)
      @functions = {}
      @lookups = {}
      @target = translate_input(target, type) unless type == :none
      @target = lookup_value(@target, start_at) unless start_at == :root
      @parser_output = parser_output
    end

    def grep
      # Populate the lookup table
      @parser_output[:lookups].each do |lookup|
        @lookups[lookup] = lookup_value(@target, lookup)
      end

      # Load the functions
      load_functions(@parser_output[:functions])

      # Evaluate the call stack
      eval_stack = @parser_output[:callstack].map do |token|
        get_value(token)
      end

      if eval(eval_stack.join(' '))
        @target
      else
        []
      end
    end

    private

    # Translate the input string into a walkable data structure
    def translate_input(target, type)
      if type == :json
        JSON.parse(target)
      elsif type == :yaml
        YAML.load(target)
      end
    end

    # Get the correct value from the token
    def get_value(token)
      case token[:type]
        when :function
          return @functions[token[:name]].call(token[:params].map { |t| get_value(t)})
        when :coperator, :loperator, :constant
          return token[:value]
        when :lookup
          return @lookups[token[:value]]
        end
    end

    # Walk the data structure and looks for the value
    # defined in the struct as lvalue.
    def lookup_value(structure, node)
      node.split('.').each do |node|
        if structure.is_a? Array
          structure = structure.map { |s| lookup_value(s, node) }.reject { |x| x == nil }
          structure = structure.first if structure.size < 2
        elsif structure.is_a? Hash
          structure = structure[node]
        else
          structure = nil
          break
        end
      end

      structure
    end

    # args must be an array of hashes
    # Example : Single argument
    #           { :type => :constant,
    #             :value => 10}
    #
    # Example : Multi arguments in json data
    #           { :type => :lookup,
    #             :value => 'foo.bar' }
    def call_function(name, arguments)
      unless @functions.keys.include?(name)
        raise 'Cannot call function "%s". Function has not been defined' % name
      else
        args = arguments.map do |arg|
          if arg[:type] == :constant
            arg[:value]
          elsif arg[:type] == :lookup
            lookup_value(@target, 'foo.bar')
          end
        end

        puts "calling function"
        @functions[name].call(args)
      end
    end

    # Load functions required by the parse string from disk
    def load_functions(functions)
      functions.each do |function|
        function_file = File.join(File.dirname(__FILE__), 'functions', '%s.rb' % function)

        if File.exists?(function_file)
          instance_eval(File.read(function_file))
        else
          raise 'Cannot load function "%s". Function definition not found' % function
        end
      end
    end

    # Registers a function to be used during execution
    def function(name, &block)
      @functions[name] = block
    end
  end
end

parse = {:lookups => ['foo.bar', 'bar.bar', 'bar.baz'],
         :functions => [:sum],
         :callstack => [{:type => :function,
                         :params => [{:type => :constant,
                                      :value => 10},
                                     {:type => :lookup,
                                      :value => 'foo.bar'
                                     }],
                         :name => :sum},
                        {:type => :coperator,
                         :value => '=='},
                        {:type => :lookup,
                         :value => 'bar.baz'},
                        {:type => :loperator,
                         :value => 'and'},
                        {:type => :lookup,
                         :value => 'bar.bar'}]
 }
