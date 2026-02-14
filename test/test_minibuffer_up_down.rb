# frozen_string_literal: true

require_relative "test_helper"

class TestMinibufferUpDown < Textbringer::TestCase
  setup do
    @candidates = ["apple", "application", "apply"]
    @completion_proc = ->(s) {
      @candidates.select { |c| c.start_with?(s) }
    }
    Buffer.minibuffer[:completion_proc] = @completion_proc
    Buffer.minibuffer[:completion_ignore_case] = false
    Buffer.minibuffer[:cycle_candidates] = nil
    Buffer.minibuffer[:cycle_index] = nil
    COMPLETION[:completions_window] = nil
    Buffer.minibuffer.clear
  end

  def test_up_cycles_backward_after_tab_cycling
    Buffer.minibuffer.insert("appl")

    # 1st TAB: no progress, starts cycling to first candidate
    cycle_complete_minibuffer
    assert_equal("apple", Buffer.minibuffer.to_s)
    assert_equal(0, Buffer.minibuffer[:cycle_index])

    Controller.current.last_command = :cycle_complete_minibuffer

    # 2nd TAB: cycle forward
    cycle_complete_minibuffer
    assert_equal("application", Buffer.minibuffer.to_s)
    assert_equal(1, Buffer.minibuffer[:cycle_index])

    Controller.current.last_command = :cycle_complete_minibuffer

    # 3rd TAB: cycle forward
    cycle_complete_minibuffer
    assert_equal("apply", Buffer.minibuffer.to_s)
    assert_equal(2, Buffer.minibuffer[:cycle_index])

    Controller.current.last_command = :cycle_complete_minibuffer

    # Up: should cycle backward (not history!)
    minibuffer_up
    assert_equal("application", Buffer.minibuffer.to_s)
    assert_equal(1, Buffer.minibuffer[:cycle_index])
  end

  def test_down_cycles_forward_after_tab_cycling
    Buffer.minibuffer.insert("appl")

    # Start cycling
    cycle_complete_minibuffer
    assert_equal("apple", Buffer.minibuffer.to_s)

    Controller.current.last_command = :cycle_complete_minibuffer

    cycle_complete_minibuffer
    assert_equal("application", Buffer.minibuffer.to_s)

    Controller.current.last_command = :cycle_complete_minibuffer

    # Down: should cycle forward
    minibuffer_down
    assert_equal("apply", Buffer.minibuffer.to_s)
    assert_equal(2, Buffer.minibuffer[:cycle_index])
  end

  def test_up_falls_back_to_history_when_no_cycling
    Buffer.minibuffer[:history] = :test_history
    Buffer.minibuffer[:history_index] = -1
    MinibufferHistory.add(:test_history, "previous_entry")
    Buffer.minibuffer.insert("current")

    # No cycle_candidates set, should go to history
    minibuffer_up
    assert_equal("previous_entry", Buffer.minibuffer.to_s)
  end

  def test_up_continues_cycling_after_up
    Buffer.minibuffer.insert("appl")

    # Start cycling
    cycle_complete_minibuffer
    assert_equal("apple", Buffer.minibuffer.to_s)
    assert_equal(0, Buffer.minibuffer[:cycle_index])

    Controller.current.last_command = :cycle_complete_minibuffer

    # First Up: should cycle backward (wrap to last)
    minibuffer_up
    assert_equal("apply", Buffer.minibuffer.to_s)
    assert_equal(2, Buffer.minibuffer[:cycle_index])

    Controller.current.last_command = :minibuffer_up

    # Second Up: should continue cycling backward
    minibuffer_up
    assert_equal("application", Buffer.minibuffer.to_s)
    assert_equal(1, Buffer.minibuffer[:cycle_index])
  end
end
