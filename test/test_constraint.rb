# frozen_string_literal: true

require "test_helper"

require 'rayzer/constraint'

class TestConstraint < Minitest::Test

  Constraint = Rayzer::Constraint

  def test_new
    types = Constraint.constants

    types.each do |type_const|
      type = Constraint.const_get type_const
      value = rand * 10

      got = Constraint.new(type, value)

      assert_equal type, got.type
      assert_equal value, got.value
    end
  end


  def test_new_raises_on_negative_value
    types = Constraint.constants

    types.each do |type_const|
      type = Constraint.const_get type_const
      value = rand * -10

      assert_raises ArgumentError, "Negative constraint value: #{value}" do
        Constraint.new(type, value)
      end
    end
  end


  def test_factory_class_methods
    types = Constraint.constants

    types.each do |type_const|
      type = Constraint.const_get type_const

      value = rand * 10
      expected = Constraint.new(type, value)

      got = Constraint.send type, value

      assert_equal expected, got  
    end
  end


  def test_parse_to_fixed_constraint
    int_value = rand 1..10
    float_value = rand * 10

    [int_value, float_value].each do |value|
      expected = Constraint.fixed(value)

      got = Constraint.parse(value)
      assert_equal expected, got

      v = value.to_s
      got = Constraint.parse(v)
      assert_equal expected, got

      got = Constraint.parse(v.to_sym)
      assert_equal expected, got
    end
  end


  def test_parse_to_minimum_constraint
    value = rand * 10

    constraint = ">=#{value}"

    expected = Constraint.minimum(value)

    got = Constraint.parse(constraint)
    assert_equal expected, got

    got = Constraint.parse(constraint.to_sym)
    assert_equal expected, got
  end


  def test_parse_to_percent_constraint
    value = rand * 10

    constraint = "#{value}%"

    expected = Constraint.percentage(value)

    got = Constraint.parse(constraint)
    assert_equal expected, got

    got = Constraint.parse(constraint.to_sym)
    assert_equal expected, got
  end


  def test_parse_to_ratio_constraint
    value = rand * 10

    constraint = ":#{value}"

    expected = Constraint.ratio(value)

    got = Constraint.parse(constraint)
    assert_equal expected, got

    got = Constraint.parse(constraint.to_sym)
    assert_equal expected, got
  end


  def test_parse_to_maximum_constraint
    value = rand * 10

    constraint = "<=#{value}"

    expected = Constraint.maximum(value)

    got = Constraint.parse(constraint)
    assert_equal expected, got

    got = Constraint.parse(constraint.to_sym)
    assert_equal expected, got
  end


  def test_parse_constraint_to_dup
    types = Constraint.constants

    types.each do |type_const|
      type = Constraint.const_get type_const

      value = rand * 10
      expected = Constraint.new(type, value)

      got = Constraint.parse expected

      assert_equal expected, got  
    end
  end


  def test_parse_raises_on_invalid_types
    invalid_arg = Class.new.new

    assert_raises ArgumentError, "Constraint.parse only accepts: Constraint, Integer, Float, Symbol and String of valid format" do
      Constraint.parse invalid_arg
    end

  end


  def test_parse_raises_on_invalid_symbol_and_string

    invalid_args = %i[
      <=30%
      !@#%#%
      %20.1.1
      <=>20
      20@#$@$024
    ]

    invalid_args.each do |arg|
      assert_raises ArgumentError, "Invalid argument format in: #{arg}" do
        Constraint.parse arg
      end
    end
  end

end
