#!/bin/env rspec

require File.join(File.dirname(__FILE__), '../../', 'lib', 'jgrep.rb')

module JGrep
  describe JGrep do
    describe '#lookup_value' do
      let(:jgrep) { JGrep.new }

      it 'should find the value in a hash' do
        structure = {'foo' => 'bar'}
        jgrep.lookup_value(structure, 'foo').should == 'bar'
      end

      it 'should find a nested value in a hash' do
        structure = {'foo' => {'bar' => {'baz' => 'result'}}}
        jgrep.lookup_value(structure, 'foo.bar.baz').should == 'result'
        jgrep.lookup_value(structure, 'foo.bar').should == {'baz' => 'result'}
      end

      it 'should be able to walk over an array' do
        structure = {'foo' => ['bar' => 'baz']}
        jgrep.lookup_value(structure, 'foo.bar').should == 'baz'
      end

      it 'should return multiple values if nodes are in the same array' do
        structure = {'foo' => [ {'bar' => '1'},
                                {'bar' => '2'}]}
        jgrep.lookup_value(structure, 'foo.bar').should == ['1', '2']
      end

      it 'should return nil if the node cannot be found' do
        structure = {'foo' => 'bar'}
        jgrep.lookup_value(structure, 'foo.bar.baz').should == nil
      end

      it 'should return nil if the structure contains arrays and node cannot be found' do
        structure = {'foo' => [{'bar' => '1'},
                               {'bar' => '2'}]}

        jgrep.lookup_value(structure, 'foo.bar.baz').should == nil
      end
    end

    describe '#compare' do
      let(:jgrep) { JGrep.new }

      it 'compares with == correctly' do
        jgrep.compare('==', 'foo', 'foo').should == true
      end
    end
  end
end
