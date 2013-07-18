module JGrep
  module Parser
    class Tokenizer
      attr_reader :tokens

      def initialize(query)
        @tokens = []
        # Forced to do this because earlier versions
        # of ruby suck at array indexing strings.
        @query = query.split('')
        @numeric = /\d/
      end

      def tokenize(query = nil, tokens = nil)
        # If tokenize is called internally, the current
        # set of globals get pushed and replaced. They
        # are popped in the end when we're done tokenizing.
        if query && tokens
          pushed_i = @i
          pushed_query = @query
          pushed_tokens = @tokens
          @query = query
          @tokens = tokens
        end

        @i = 0

        while @i < @query.size
          if @query[@i] == ' '
            @i += 1
            next
          elsif @query[@i] == '(' || @query[@i] == ')'
            @tokens << create_token(@query[@i], :paren)
            @i += 1
          elsif @query[@i] == 'a'
            if @query[@i+1] == 'n' && @query[@i+2] == 'd'
              @tokens <<  create_token('and', :loperator)
              @i += 3
            end
          elsif @query[@i] == 'o'
            if @query[@i+1] == 'r'
              @tokens << create_token('or', :loperator)
              @i += 2
            end
          elsif @query[@i] == 'x'
            if @query[@i+1] == 'o' && @query[@i+2] == 'r'
              @tokens << create_token('xor', :loperator)
              @i += 3
            end
          elsif @query[@i] == 'n'
            if @query[@i+1] == 'a' && @query[@i+2] == 'n' && @query[@i+3] == 'd'
              @tokens << create_token('nand', :loperator)
              @i += 4
            end
          elsif @query[@i] == '>'
            if @query[@i+1] == '='
              @tokens << create_token('>=', :coperator)
              @i += 2
            else
              @tokens << create_token('>', :coperator)
              @i += 1
            end
          elsif @query[@i] == '<'
            if @query[@i+1] == '='
              @tokens << create_token('<=', :coperator)
              @i += 2
            else
              @tokens << create_token('<', :coperator)
              @i += 1
            end
          elsif @query[@i] == '='
            if @query[@i+1] == '~'
              @tokens << create_token('=~', :coperator)
              @i += 2
            else
              @tokens << create_token('==', :coperator)
              @i += 1
            end
          elsif @query[@i] == '!'
            @tokens << create_token('!', :uoperator)
            @i += 1
          elsif @query[@i] == "'" || @query[@i] == '"'
            @tokens << create_string(@i)
          elsif @query[@i] =~ @numeric
            @tokens << create_numeric(@i)
          else
            @tokens << create_lookup(@i)
          end
        end

        if query && tokens
          @i = pushed_i
          @query = pushed_query
          @tokens = pushed_tokens
        end
      end

      private

      # Lookup tokens are our fallback. Anything that doesn't hit earlier
      # in tokenization is assumed to be a lookup token. This allows us to
      # fail at a later step in the parse process and make the language
      # feel more lenient.
      #
      # Lookup tokens are also the entry point into function tokens. This
      # means that functions are the very last tokens identified during
      # tokenization.
      def create_lookup(index)
        value = ''

        while(![' ', '=', '<', '>', '(', ')', nil].include?(@query[index]))
          value += @query[index]
          index += 1
        end

        if(@query[index] == '(')
          # Then we have identified a function
          return create_function(value, index)
        end

        @i = index
        create_token(value, :lookup)
      end

      def create_function(value, index)
        index += 1
        name = value.to_sym
        params = ''
        delim_count = 1

        while(@query[index] != nil)
          delim_count += 1 if @query[index] == '('
          delim_count -= 1 if @query[index] == ')'
          break if delim_count == 0
          params += @query[index]
          index += 1
        end

        filtered_params = []
        filter_params(params.gsub("\s", '').split(''), filtered_params)

        if @query[index] == nil
          raise BadTokenException, "Bad function token identified. Missing )"
        end

        param_tokens = []
        filtered_params.map { |p| tokenize(p.split(''), param_tokens) }
        @i = index + 1

        create_token([name, param_tokens], :function)
      end

      def filter_params(params, result)
        i = 0
        s = ''
        while i < params.size
          s += params[i]
          i += 1

          if params[i] == '('
            paren = 1
            while i < params.size
              s += params[i]
              paren -= 1 if params[i] == ')'
              paren += 1 if params[i] == '('
              break if paren == 0
              i += 1
            end

            result << s
            params.slice!(0..i)
            filter_params(params, result)

          elsif params[i] == ','
            result << s
            params.slice!(0..i)
            filter_params(params, result)
          end
        end
      end

      def create_numeric(index)
        value = ''
        delim_count = 0

        while((@query[index] =~ @numeric || @query[index] == '.') && delim_count < 2)
          value += @query[index]
          delim_count += 1 if @query[index] == '.'
          index += 1
        end

        (delim_count < 1) ? value = value.to_i : value = value.to_f

        @i = index
        create_token(value, :constant)
      end

      def create_string(index)
        value = ''
        delimiter = @query[index]
        value += delimiter
        index += 1

        while(@query[index] != delimiter)
          if @query[index] == nil
            raise BadTokenException, "Bad string token identified. Missing %s" % delimiter
          end

          value += @query[index]
          index += 1
        end

        value += delimiter
        @i = index + 1
        create_token(value, :constant)
      end

      def create_token(value, type)
        if type == :function
          {:type => type, :name => value[0], :params => value[1]}
        else
          {:type => type, :value => value}
        end
      end
    end
  end
end
