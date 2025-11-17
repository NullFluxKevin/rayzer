# frozen_string_literal: true

require "test_helper"

require 'rayzer/layout'
require 'rayzer/constraint'


class TestLayout < Minitest::Test
  Layout = Rayzer::Layout
  Constraint = Rayzer::Constraint

  def test_new
    x, y, width, height = Array.new(4) { rand 1..100 }

    got = Layout.new(x, y, width, height)

    assert_equal x, got.x
    assert_equal y, got.y
    assert_equal width, got.width
    assert_equal height, got.height
    assert_nil got.parent
    assert_empty got.children
    assert_equal Layout::LEAF, got.type
  end
end


class TestSplitToCols < Minitest::Test
  Layout = Rayzer::Layout
  Constraint = Rayzer::Constraint

  def test_split_to_cols
    x, y, width, height = 10, 20, 100, 200
    constraints = %i[10 >=10 30% :1 :1]

    expected = [
      Layout.new(x, y, 10, height),
      Layout.new(x + 10, y, 10, height),
      Layout.new(x + 20, y, 24, height),
      Layout.new(x + 44, y, 28, height),
      Layout.new(x + 72, y, 28, height),
    ]

    layout = Layout.new(x, y, width, height)

    got = layout.split_to_cols(constraints)

    assert_equal expected, got
    assert_equal Layout::COLUMN_CONTAINER, layout.type
  end


  def test_split_to_cols_returns_remaining
    x, y, width, height = 10, 20, 100, 200
    constraints = %i[10]

    expected = [
      Layout.new(x, y, 10, height),
      Layout.new(x + 10, y, 90, height),
    ]

    layout = Layout.new(x, y, width, height)

    got = layout.split_to_cols(constraints)

    assert_equal expected, got
  end


  def test_split_to_cols_adds_remaining_to_instance_var
    x, y, width, height = 10, 20, 100, 200
    constraints = %i[10]

    expected = Layout.new(x + 10, y, 90, height)
    

    layout = Layout.new(x, y, width, height)

    layout.split_to_cols(constraints)

    assert_equal expected, layout.remaining
  end


  def test_split_to_cols_yields_to_block
    x, y, width, height = 10, 20, 100, 200
    constraints = %i[10 >=10 30% <=10]

    expected = [
      Layout.new(x, y, 10, height),
      Layout.new(x + 10, y, 56, height),
      Layout.new(x + 66, y, 24, height),
      Layout.new(x + 90, y, 10, height),
    ]

    layout = Layout.new(x, y, width, height)

    got = nil
    layout.split_to_cols(constraints) do |block_got|
      got = block_got
    end
    assert_equal expected, got
  end


  def test_split_to_cols_yields_remaining
    x, y, width, height = 10, 20, 100, 200
    constraints = %i[10]

    expected = [
      Layout.new(x, y, 10, height),
      Layout.new(x + 10, y, 90, height),
    ]

    layout = Layout.new(x, y, width, height)

    got = nil
    layout.split_to_cols(constraints) do |block_got|
      got = block_got
    end
    assert_equal expected, got
  end


  def test_split_to_cols_given_names_args_adds_instance_variables
    x, y, width, height = 10, 20, 100, 200
    constraints = %i[10 >=10 30% <=10]
    names = %i[c1 c2 c3 c4]

    expected = [
      Layout.new(x, y, 10, height),
      Layout.new(x + 10, y, 56, height),
      Layout.new(x + 66, y, 24, height),
      Layout.new(x + 90, y, 10, height),
    ]

    layout = Layout.new(x, y, width, height)

    layout.split_to_cols(constraints, names)

    got = names.map { |name| layout.send name }

    assert_equal expected, got
  end


  def test_split_to_cols_raises_if_names_is_array_and_size_mismatches
    constraints = %i[1 2 3 4]
    names = %i[c1 c2 c3]

    layout = Layout.new(10, 10, 10, 10)

    assert_raises ArgumentError, "Size of names and size of constraints mismatch" do
      layout.split_to_cols(constraints, names)
    end
  end


  def test_split_to_cols_skip_nil_in_names_array
    x, y, width, height = 10, 20, 100, 200
    constraints = %i[10 >=10 30% <=10]
    names = ["c1", "c2", nil, "c4"]

    expected = [
      Layout.new(x, y, 10, height),
      Layout.new(x + 10, y, 56, height),
      Layout.new(x + 66, y, 24, height),
      Layout.new(x + 90, y, 10, height),
    ]

    layout = Layout.new(x, y, width, height)

    got = layout.split_to_cols(constraints, names)

    instance_vars = names.compact.map { |name| layout.send name }

    assert_equal expected, got
    assert_equal [0, 1, 3].map {|i| expected[i]}, instance_vars
  end


  def test_split_to_cols_names_can_have_holes_if_it_is_a_hash
    x, y, width, height = 10, 20, 100, 200
    constraints = %i[10 >=10 30% <=10]
    names = {0=>:c1, 1=>:c2, 3=>:c4}

    expected = [
      Layout.new(x, y, 10, height),
      Layout.new(x + 10, y, 56, height),
      Layout.new(x + 66, y, 24, height),
      Layout.new(x + 90, y, 10, height),
    ]

    layout = Layout.new(x, y, width, height)

    got = layout.split_to_cols(constraints, names)

    instance_vars = names.values.map { |name| layout.send name }

    assert_equal expected, got
    assert_equal [0, 1, 3].map {|i| expected[i]}, instance_vars
  end


  def test_split_to_cols_raises_on_invalid_index_key_of_names_hash
    x, y, width, height = 10, 20, 100, 200
    constraints = %i[10]
    names = {100=>:invalid}

    layout = Layout.new(x, y, width, height)

    assert_raises IndexError do
      layout.split_to_cols(constraints, names)
    end
  end


  def test_split_to_cols_raises_if_names_is_neither_array_nor_hash
    constraints = %w[1 2 3 4]
    names = Class.new.new

    layout = Layout.new(10, 10, 10, 10)
    assert_raises ArgumentError, "Invalid type for arg: names. Expecting Array or Hash" do
      layout.split_to_cols(constraints, names)
    end

  end

end


class TestSplitToRows < Minitest::Test
  Layout = Rayzer::Layout
  Constraint = Rayzer::Constraint

  def test_split_to_rows
    x, y, width, height = 10, 10, 100, 100
    constraints = %i[10 >=10 30% :1 :1]

    expected = [
      Layout.new(x, y, width, 10),
      Layout.new(x, y + 10, width, 10),
      Layout.new(x, y + 20, width, 24),
      Layout.new(x, y + 44, width, 28),
      Layout.new(x, y + 72, width, 28),
    ]

    layout = Layout.new(x, y, width, height)

    got = layout.split_to_rows(constraints)

    assert_equal expected, got
    assert_equal Layout::ROW_CONTAINER, layout.type
  end


  def test_split_to_rows_returns_remaining
    x, y, width, height = 10, 10, 100, 100
    constraints = %i[10]

    expected = [
      Layout.new(x, y, width, 10),
      Layout.new(x, y + 10, width, 90),
    ]

    layout = Layout.new(x, y, width, height)

    got = layout.split_to_rows(constraints)

    assert_equal expected, got
  end


  def test_split_to_rows_adds_remaining_to_instance_var
    x, y, width, height = 10, 10, 100, 100
    constraints = %i[10]

    expected = Layout.new(x, y + 10, width, 90)

    layout = Layout.new(x, y, width, height)

    layout.split_to_rows(constraints)

    assert_equal expected, layout.remaining

  end


  def test_split_to_rows_yields_to_block
    x, y, width, height = 10, 10, 100, 100
    constraints = %i[10 >=10 30% :1 :1]

    expected = [
      Layout.new(x, y, width, 10),
      Layout.new(x, y + 10, width, 10),
      Layout.new(x, y + 20, width, 24),
      Layout.new(x, y + 44, width, 28),
      Layout.new(x, y + 72, width, 28),
    ]

    layout = Layout.new(x, y, width, height)

    got = nil
    layout.split_to_rows(constraints) do |block_got|
      got = block_got
    end
    assert_equal expected, got
  end


  def test_split_to_rows_yields_remaining
    x, y, width, height = 10, 10, 100, 100
    constraints = %i[10]

    expected = [
      Layout.new(x, y, width, 10),
      Layout.new(x, y + 10, width, 90),
    ]

    layout = Layout.new(x, y, width, height)

    got = nil
    layout.split_to_rows(constraints) do |block_got|
      got = block_got
    end

    assert_equal expected, got
  end


  def test_split_to_rows_given_names_args_adds_instance_variables
    x, y, width, height = 10, 10, 100, 100
    constraints = %i[10 >=10 30% <=10]
    names = %i[c1 c2 c3 c4]

    expected = [
      Layout.new(x, y, width, 10),
      Layout.new(x, y + 10, width, 56),
      Layout.new(x, y + 66, width, 24),
      Layout.new(x, y + 90, width, 10),
    ]

    layout = Layout.new(x, y, width, height)

    layout.split_to_rows(constraints, names)

    got = names.map { |name| layout.send name }

    assert_equal expected, got
  end


  def test_split_to_rows_raises_if_names_is_array_and_size_mismatches
    constraints = %i[1 2 3 4]
    names = %i[c1 c2 c3]

    layout = Layout.new(10, 10, 10, 10)

    assert_raises ArgumentError, "Size of names and size of constraints mismatch" do
      layout.split_to_rows(constraints, names)
    end
  end


  def test_split_to_rows_skip_nil_in_names_array
    x, y, width, height = 10, 10, 100, 100
    constraints = %i[10 >=10 30% <=10]
    names = ["c1", "c2", nil, "c4"]

    expected = [
      Layout.new(x, y, width, 10),
      Layout.new(x, y + 10, width, 56),
      Layout.new(x, y + 66, width, 24),
      Layout.new(x, y + 90, width, 10),
    ]

    layout = Layout.new(x, y, width, height)

    got = layout.split_to_rows(constraints, names)

    instance_vars = names.compact.map { |name| layout.send name }

    assert_equal expected, got
    assert_equal [0, 1, 3].map {|i| expected[i]}, instance_vars
  end


  def test_split_to_rows_names_can_have_holes_if_it_is_a_hash
    x, y, width, height = 10, 10, 100, 100
    constraints = %i[10 >=10 30% <=10]

    names = {0=>:c1, 1=>:c2, 3=>:c4}

    expected = [
      Layout.new(x, y, width, 10),
      Layout.new(x, y + 10, width, 56),
      Layout.new(x, y + 66, width, 24),
      Layout.new(x, y + 90, width, 10),
    ]

    layout = Layout.new(x, y, width, height)

    got = layout.split_to_rows(constraints, names)

    instance_vars = names.values.map { |name| layout.send name }

    assert_equal expected, got
    assert_equal [0, 1, 3].map {|i| expected[i]}, instance_vars
  end


  def test_split_to_rows_raises_on_invalid_index_key_of_names_hash
    x, y, width, height = 10, 10, 100, 100
    constraints = %i[10]

    names = {100=>:invalid}
    layout = Layout.new(x, y, width, height)

    assert_raises IndexError do
      layout.split_to_rows(constraints, names)
    end
  end


  def test_split_to_rows_raises_if_names_is_neither_array_nor_hash
    constraints = %w[1 2 3 4]
    names = Class.new.new

    layout = Layout.new(10, 10, 10, 10)
    assert_raises ArgumentError, "Invalid type for arg: names. Expecting Array or Hash" do
      layout.split_to_rows(constraints, names)
    end
  end
end


class TestSplitBang < Minitest::Test

  Layout = Rayzer::Layout
  Constraint = Rayzer::Constraint

  def test_split_to_cols_bang_raises_if_has_remaining
    x, y, width, height = 10, 10, 100, 100
    constraints = %i[10]
    layout = Layout.new(x, y, width, height)

    assert_raises Layout::RemainingSpaceError do
      layout.split_to_cols! constraints
    end
  end


  def test_split_to_rows_bang_raises_if_has_remaining
    x, y, width, height = 10, 10, 100, 100
    constraints = %i[10]
    layout = Layout.new(x, y, width, height)

    assert_raises Layout::RemainingSpaceError do
      layout.split_to_rows! constraints
    end
  end
end
