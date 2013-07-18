module JGrep
  module Parser
    require 'jgrep/parser/tokenizer'
    require 'jgrep/parser/lexer'

    def self.parse(parse_string)
      tokenizer = Tokenizer.new(parse_string)
      tokenizer.tokenize
      Lexer.new(tokenizer.tokens).parse
    end
  end
end
