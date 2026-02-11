# frozen_string_literal: true

require_relative "test_helper"

class TestMinibufferNested < Textbringer::TestCase
  def test_nested_minibuffer_raises_error
    # Simulate minibuffer being already active
    Window.echo_area.active = true

    error = assert_raise(EditorError) do
      read_from_minibuffer("Test: ", history: :test)
    end

    assert_match(/minibuffer/, error.message)
  ensure
    Window.echo_area.active = false
  end

  def test_history_navigation_commands
    # Test that history commands work properly
    MinibufferHistory.add(:test, "item1")
    MinibufferHistory.add(:test, "item2")

    # Setup minibuffer state as if we're in minibuffer
    Buffer.minibuffer[:history] = :test
    Buffer.minibuffer[:history_index] = -1
    Buffer.minibuffer[:history_input] = nil
    Buffer.minibuffer.clear

    # Test previous_history_element
    previous_history_element
    assert_equal(0, Buffer.minibuffer[:history_index])
    assert_equal("item2", Buffer.minibuffer.to_s)

    # Test next_history_element back
    Buffer.minibuffer.clear
    next_history_element
    assert_equal(-1, Buffer.minibuffer[:history_index])
  end

  def test_history_preserves_original_input
    MinibufferHistory.add(:test, "history_item")

    Buffer.minibuffer[:history] = :test
    Buffer.minibuffer[:history_index] = -1
    Buffer.minibuffer[:history_input] = nil
    Buffer.minibuffer.clear
    Buffer.minibuffer.insert("typed_input")

    # Navigate to history
    previous_history_element

    # Original input should be saved
    assert_equal("typed_input", Buffer.minibuffer[:history_input])

    # Navigate back
    Buffer.minibuffer.clear
    next_history_element

    # Should restore original input
    assert_equal("typed_input", Buffer.minibuffer.to_s)
  end

  def test_previous_history_at_empty_history
    Buffer.minibuffer[:history] = :empty_history
    Buffer.minibuffer[:history_index] = -1
    Buffer.minibuffer.clear

    error = assert_raise(EditorError) do
      previous_history_element
    end

    assert_match(/no preceding item/, error.message)
  end

  def test_next_history_at_beginning
    Buffer.minibuffer[:history] = :test
    Buffer.minibuffer[:history_index] = -1
    Buffer.minibuffer.clear

    error = assert_raise(EditorError) do
      next_history_element
    end

    assert_match(/no default available/, error.message)
  end
end
