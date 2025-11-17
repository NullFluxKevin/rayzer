# frozen_string_literal: true

require "test_helper"

class TestRayzer < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Rayzer::VERSION
  end
end
