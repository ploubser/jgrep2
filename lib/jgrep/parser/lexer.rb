module JGrep
  module Parser
    class Lexer

      GROUP1 = [:lookup, :constant, :function, :paren, :uoperator]
      GROUP2 = [:loperator, :coperator, :paren]
      GROUP3 = [:function, :constant, :lookup]

      attr_reader :tokens

      def initialize(tokens)
        @tokens = tokens
        @lookups = []
        @functions = []
        @token_index = 0
        @marked = []
      end

      def parse
        while @token_index <= (@tokens.size-1)
          case @tokens[@token_index][:type]
          when :uoperator
            uoperator
          when :loperator
            loperator
          when :coperator
            coperator
          when :constant
            constant
          when :function
            function
          when :lookup
            lookup
          when :paren
            paren
          end

          @token_index += 1
        end

        parser_ouput = {:callstack => @tokens,
                       :functions => @functions,
                       :lookups => @lookups}
      end

      # Unary operators can be followed by
      # - lookup
      # - constant
      # - function
      # - paren
      def uoperator
        should_have_next
        token_check GROUP1
      end

      # Logical operators can be followed by
      # - lookup
      # - constant
      # - function
      # - paren
      def loperator
        should_have_next
        token_check GROUP1
      end

      # Comparison operators can be followed by
      # - lookup
      # - constant
      # - function
      # - paren
      def coperator
        should_have_next
        token_check GROUP1
      end

      # Constants can be followed by
      # - logical operator
      # - comparison operator
      def constant
        token_check GROUP2
      end

      # Functions can be followed by
      # -
      #
      # Note that function paremeters also need to be parsed
      def function(f = nil)
        f = f || @tokens[@token_index]
        token_check GROUP2
        valid_params = [:constant, :function, :lookup]

        f[:params].each do |param|
          unless valid_params.include? param[:type]
            raise "Function parameters can only be of type ''" % valid_params.join(', ')
          end

          if param[:type] == :function
            function(param)
          elsif param[:type] == :lookup
            @lookups << param[:value]
          end
        end

        @functions << f[:name]
      end

      # Lookups can be followed by
      # - logical operator
      # - comparison operator
      def lookup
        token_check GROUP2
        @lookups << @tokens[@token_index][:value].to_sym
      end

      # Parenthesis can be followed by
      # (
      # - function
      # - constant
      # - lookup
      #
      # )
      # - logical operator
      # - comparison operator
      #
      # Note that a paren token needs to walk the token structure
      # and find its matching token
      def paren
        token = @tokens[@token_index]
        if token[:value] == '('
          lparen
          mark
        elsif token[:value] == ')'
          rparen
          marked?
        end
      end

      def mark
        paren_count = 1
        i = @token_index + 1

        while i < @tokens.size
          paren_count += 1 if @tokens[i][:value] == '('
          paren_count -= 1 if @tokens[i][:value] == ')'
          break if paren_count == 0
          i += 1
        end

        if paren_count == 0
          @marked << i
        else
          raise BadTokenException, "Found '(' without a matching ')'"
        end
      end

      def marked?
        unless @marked.include?(@token_index)
          raise BadTokenException, "Found ')' without a matching '('"
        end
      end

      def lparen
        token_check GROUP3
      end

      def rparen
        token_check GROUP2
      end

      def should_have_next
        unless @tokens[@token_index+1]
          raise BadTokenException, "Bad token '%s' found. Line cannot end with an operator" % @tokens[@token_index][:value]
        end
      end

      def token_check(valid)
        if @tokens[@token_index+1]
          unless valid.include?(@tokens[@token_index+1][:type])
            raise BadTokenException, "Bad %s token found. Expected one of '%s'" % [ @tokens[@token_index+1][:type], valid.join(',') ]
          end
        end
      end
    end
  end
end
