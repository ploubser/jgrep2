module JGrep

  class BadTokenException<Exception;end;

  require 'rubygems'
  require 'pp'
  require 'json'
  require 'yaml'
  require 'jgrep/jgrep'
  require 'jgrep/parser'

  def self.jgrep(target, parse_string)
    result = []
    begin
      tokens = Parser.parse(parse_string)
      result = JGrep.new(target, tokens, :json).grep
    rescue BadTokenException => e
      puts e.to_s
    rescue JSON::ParserError
      puts "Invalid JSON input given"
    ensure
      puts(JSON.pretty_generate(result))
    end
  end
end
