# frozen_string_literal: true

require "test_helper"


class TestDistributor < Minitest::Test

  Distributor = Rayzer::Distributor
  Constraint = Rayzer::Constraint

  using Distributor

  def test_int_respond_to_distribute
    assert rand(100).respond_to? :distribute
  end


  def test_float_respond_to_distribute
    assert rand.respond_to? :distribute
  end


  def test_distribute_raises_on_non_positive_number
    values = [rand * -1, 0, -100]

    values.each do |value|
      assert_raises ArgumentError, "Can not distribute negative value" do
        value.distribute 
      end
    end
  end


  def test_distribute_raises_on_non_real_number
    complex = 1.to_c

    assert_raises(ArgumentError, "Can not distribute non-real value") do
      complex.distribute 
    end
  end


  def test_distribute_fixed_constraints
    parts = 10.0.distribute(
      Constraint.fixed(0.5),
      Constraint.fixed(4),
      Constraint.fixed(3),
      Constraint.fixed(2.5),
    )

    assert_equal [0.5, 4, 3, 2.5], parts
  end

  
  def test_distribute_minimum_constraints
    value = rand(1..10)

    parts = value.distribute(
      Constraint.minimum(value),
    )

    assert_equal [value], parts
  end


  def test_distribute_raises_if_sum_exceeds_value_to_distribute
    value = rand(1..10)

    assert_raises ArgumentError, "Sum of required constraints exceeds #{value}" do
      value.distribute( Constraint.fixed(value), Constraint.minimum(value) )
    end
  end


  def test_distribute_adds_remaining_to_result
    value = rand(1..10)
    constraint = rand(value)

    parts = value.distribute(
      Constraint.fixed(constraint),
    )

    assert_equal [constraint, value - constraint], parts
  end


  def test_distribute_bang_raises_if_has_remaining
    value = rand(1..10)
    constraint = rand(value)
    remaining = value - constraint

    msg = "Incomplete distribution of #{value}, remaining #{remaining}"

    assert_raises msg do
      value.distribute!(
        Constraint.fixed(constraint)
      )
    end

  end


  def test_distribute_adds_remaining_to_the_first_min_constraint
    f1, f2 = 1, 2.5
    m1, m2 = 2, 2
    
    min = f1 + f2 + m1 + m2
    extra = rand(1..10)
    value = min + extra

    parts = value.distribute(
      Constraint.fixed(1),
      Constraint.minimum(2),
      Constraint.fixed(2.5),
      Constraint.minimum(2),
    )

    assert_equal [f1, m1 + extra, f2, m2], parts
  end


  def test_distribute_percentage_constraints
    value = rand(1..10)
    p1 = 35
    p2 = 65

    parts = value.distribute(
      Constraint.percentage(p1),
      Constraint.percentage(p2),
    )

    parts.zip [value * p1 * 0.01, value * p2 * 0.01] do |got, expect|
      assert_in_epsilon expect, got
    end

  end


  def test_distribute_raises_if_total_percentage_exceeds_100

    p1 = (rand(101) - rand(101)).abs
    p2 = 100 - p1

    assert_raises ArgumentError, "Sum of percentage constraints exceeds 100" do
      rand.distribute(
        Constraint.percentage(p1),
        Constraint.percentage(p2 * 2),
      )

    end
  end


  def test_distribute_ratio_constraints
    value = rand(1..10)
    r1 = rand(1..10)
    r2 = rand(1..10)
    r3 = rand(1..10)

    sum = r1 + r2 + r3
    per_ratio = value.fdiv sum

    parts = value.distribute(
      Constraint.ratio(r1),
      Constraint.ratio(r2),
      Constraint.ratio(r3),
    ) 

    assert_equal [r1, r2, r3].map { |r| r * per_ratio }, parts
  end


  def test_distribute_prioritizes_precentage_over_ratio
    value = 100

    parts = value.distribute(
      Constraint.percentage(40),
      Constraint.percentage(60),
      Constraint.ratio(2),
      Constraint.ratio(3),
    )

    expected = [40, 60, 0, 0]

    assert_equal expected, parts


    parts = value.distribute(
      Constraint.percentage(40),
      Constraint.percentage(55),
      Constraint.ratio(2),
      Constraint.ratio(3),
    )

    expected = [40, 55, 2, 3]

    expected.zip(parts).each do |exp, got|
      assert_in_epsilon exp, got
    end
  end


  def test_distribute_maximum_constraints
    value = rand 1..10
    maximum = rand 1..value

    parts = value.distribute(
      Constraint.maximum(maximum)
    )

    expected = [maximum]
    expected << value - maximum if value != maximum

    assert_equal expected, parts
  end


  def test_distribute_unstatisfied_maxmum_constraints

    value = rand 1..10
    m1 = rand 1..value
    m2 = value - m1 + 10
    m3 = rand value
    m4 = rand value

    parts = value.distribute(
      Constraint.maximum(m1),
      Constraint.maximum(m2),
      Constraint.maximum(m3),
      Constraint.maximum(m4),
    )

    assert_equal [m1, value - m1, 0, 0], parts
  end
    

  def test_mixed_constraints
    value = 100.0

    parts = value.distribute(
      Constraint.maximum(10),
      Constraint.fixed(5),
      Constraint.minimum(10),
      Constraint.percentage(10),
      Constraint.fixed(10),
      Constraint.percentage(20),
      Constraint.minimum(15),
      Constraint.maximum(10),
    )

    expected = [10, 5, 32, 6, 10, 12, 15, 10]
    
    assert_equal expected, parts
  end

end # end of Test
