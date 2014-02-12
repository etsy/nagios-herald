require 'test/unit'

module Test::Unit::Assertions
  def assert_contains(expected_substring, string, *args)
    assert string.include?(expected_substring), *args
  end
end