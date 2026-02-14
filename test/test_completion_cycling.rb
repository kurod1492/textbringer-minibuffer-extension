# frozen_string_literal: true

require_relative "test_helper"

class TestCompletionCycling < Textbringer::TestCase
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

  def test_single_candidate_completes_without_cycling
    Buffer.minibuffer.insert("appl")
    completion_proc = ->(s) { ["application"] }
    Buffer.minibuffer[:completion_proc] = completion_proc

    cycle_complete_minibuffer

    assert_equal("application", Buffer.minibuffer.to_s)
    assert_nil(Buffer.minibuffer[:cycle_candidates])
  end

  def test_no_match_shows_message
    Buffer.minibuffer.insert("xyz")

    cycle_complete_minibuffer

    assert_nil(Buffer.minibuffer[:cycle_candidates])
  end

  def test_common_prefix_completion_with_progress
    Buffer.minibuffer.insert("a")

    cycle_complete_minibuffer

    assert_equal("appl", Buffer.minibuffer.to_s)
    assert_equal(@candidates, Buffer.minibuffer[:cycle_candidates])
    assert_equal(-1, Buffer.minibuffer[:cycle_index])
  end

  def test_no_progress_starts_cycling_immediately
    Buffer.minibuffer.insert("appl")

    cycle_complete_minibuffer

    assert_equal("apple", Buffer.minibuffer.to_s)
    assert_equal(@candidates, Buffer.minibuffer[:cycle_candidates])
    assert_equal(0, Buffer.minibuffer[:cycle_index])
  end

  def test_cycling_through_candidates
    Buffer.minibuffer.insert("appl")

    # First TAB: no progress on prefix, starts cycling to first candidate
    cycle_complete_minibuffer
    assert_equal("apple", Buffer.minibuffer.to_s)
    assert_equal(0, Buffer.minibuffer[:cycle_index])

    # Simulate that last_command was cycle_complete_minibuffer
    Controller.current.last_command = :cycle_complete_minibuffer

    # Second TAB: cycle to next candidate
    cycle_complete_minibuffer
    assert_equal("application", Buffer.minibuffer.to_s)
    assert_equal(1, Buffer.minibuffer[:cycle_index])

    Controller.current.last_command = :cycle_complete_minibuffer

    # Third TAB: cycle to next candidate
    cycle_complete_minibuffer
    assert_equal("apply", Buffer.minibuffer.to_s)
    assert_equal(2, Buffer.minibuffer[:cycle_index])
  end

  def test_cycling_wraps_around
    Buffer.minibuffer.insert("appl")

    # Start cycling
    cycle_complete_minibuffer
    assert_equal("apple", Buffer.minibuffer.to_s)

    Controller.current.last_command = :cycle_complete_minibuffer
    cycle_complete_minibuffer
    assert_equal("application", Buffer.minibuffer.to_s)

    Controller.current.last_command = :cycle_complete_minibuffer
    cycle_complete_minibuffer
    assert_equal("apply", Buffer.minibuffer.to_s)

    Controller.current.last_command = :cycle_complete_minibuffer

    # Should wrap around to first candidate
    cycle_complete_minibuffer
    assert_equal("apple", Buffer.minibuffer.to_s)
    assert_equal(0, Buffer.minibuffer[:cycle_index])
  end

  def test_reset_on_different_command
    Buffer.minibuffer.insert("appl")

    # Start cycling
    cycle_complete_minibuffer
    assert_equal("apple", Buffer.minibuffer.to_s)
    assert_equal(0, Buffer.minibuffer[:cycle_index])

    # Simulate a different command was executed
    Controller.current.last_command = :self_insert

    # TAB again should restart completion from scratch
    cycle_complete_minibuffer
    # "apple" has no common prefix progress from current "apple" text
    # completion_proc returns candidates starting with "apple" = ["apple"]
    # single match → complete without cycling
    assert_equal("apple", Buffer.minibuffer.to_s)
  end

  def test_prefix_progress_then_cycling
    # Start with "a", first TAB completes to "appl" (common prefix)
    Buffer.minibuffer.insert("a")

    cycle_complete_minibuffer
    assert_equal("appl", Buffer.minibuffer.to_s)
    assert_equal(-1, Buffer.minibuffer[:cycle_index])

    # Second TAB: last_command is cycle_complete_minibuffer but cycle_index is -1
    # Since cycle_index is -1, it means we haven't started cycling yet
    # But the condition checks cycle_candidates.size > 1 AND last_command
    # With cycle_index = -1, the cycling branch will execute and go to index 0
    Controller.current.last_command = :cycle_complete_minibuffer

    cycle_complete_minibuffer
    assert_equal("apple", Buffer.minibuffer.to_s)
    assert_equal(0, Buffer.minibuffer[:cycle_index])
  end

  def test_ignore_case_completion
    candidates = ["Apple", "APPLICATION", "Apply"]
    Buffer.minibuffer[:completion_proc] = ->(s) {
      candidates.select { |c| c.downcase.start_with?(s.downcase) }
    }
    Buffer.minibuffer[:completion_ignore_case] = true
    Buffer.minibuffer.insert("appl")

    cycle_complete_minibuffer

    # Common prefix is "Appl" (from first candidate "Apple"), which differs
    # from "appl" in case, so it counts as progress
    assert_equal("Appl", Buffer.minibuffer.to_s)
    assert_equal(candidates, Buffer.minibuffer[:cycle_candidates])
    assert_equal(-1, Buffer.minibuffer[:cycle_index])

    # Second TAB starts cycling
    Controller.current.last_command = :cycle_complete_minibuffer
    cycle_complete_minibuffer
    assert_equal("Apple", Buffer.minibuffer.to_s)
    assert_equal(0, Buffer.minibuffer[:cycle_index])
  end

  def test_no_completion_proc
    Buffer.minibuffer[:completion_proc] = nil
    Buffer.minibuffer.insert("test")

    # Should do nothing (next in the command block)
    cycle_complete_minibuffer

    assert_equal("test", Buffer.minibuffer.to_s)
  end

  def test_completions_buffer_content_on_cycling
    Buffer.minibuffer.insert("appl")

    # First TAB: no progress, starts cycling at index 0
    cycle_complete_minibuffer

    completions = Buffer["*Completions*"]
    assert_not_nil(completions)
    assert_equal("apple\napplication\napply\n", completions.to_s)
  end

  def test_completions_buffer_syntax_pattern_tracks_selection
    Buffer.minibuffer.insert("appl")

    # First TAB: cycling starts at index 0 (apple selected)
    cycle_complete_minibuffer

    pattern = CyclingCompletionListMode.instance_variable_get(:@syntax_table)[:completion_selected]
    assert_match(pattern, "apple")
    assert_not_match(pattern, "application")

    Controller.current.last_command = :cycle_complete_minibuffer

    # Second TAB: cycle to index 1 (application selected)
    cycle_complete_minibuffer

    pattern = CyclingCompletionListMode.instance_variable_get(:@syntax_table)[:completion_selected]
    assert_not_match(pattern, "apple")
    assert_match(pattern, "application")
    assert_not_match(pattern, "apply")

    Controller.current.last_command = :cycle_complete_minibuffer

    # Third TAB: cycle to index 2 (apply selected)
    cycle_complete_minibuffer

    pattern = CyclingCompletionListMode.instance_variable_get(:@syntax_table)[:completion_selected]
    assert_not_match(pattern, "apple")
    assert_not_match(pattern, "application")
    assert_match(pattern, "apply")
  end

  def test_completions_buffer_uses_cycling_completion_list_mode
    Buffer.minibuffer.insert("appl")

    cycle_complete_minibuffer

    completions = Buffer["*Completions*"]
    assert_instance_of(CyclingCompletionListMode, completions.mode)
  end

  def test_completions_buffer_point_follows_selection
    Buffer.minibuffer.insert("appl")

    # First TAB: index 0 selected, point at line 1
    cycle_complete_minibuffer

    completions = Buffer["*Completions*"]
    completions.save_excursion {
      completions.beginning_of_line
      completions.looking_at?(/^(.*)/)
      assert_equal("apple", completions.match_string(1))
    }

    Controller.current.last_command = :cycle_complete_minibuffer

    # Second TAB: index 1 selected, point at line 2
    cycle_complete_minibuffer

    completions.save_excursion {
      completions.beginning_of_line
      completions.looking_at?(/^(.*)/)
      assert_equal("application", completions.match_string(1))
    }
  end

  def test_backward_cycling_starts_from_last
    Buffer.minibuffer.insert("appl")

    # Shift-TAB: starts cycling backward from last candidate
    cycle_complete_minibuffer_backward

    assert_equal("apply", Buffer.minibuffer.to_s)
    assert_equal(@candidates, Buffer.minibuffer[:cycle_candidates])
    assert_equal(2, Buffer.minibuffer[:cycle_index])
  end

  def test_backward_cycling_through_candidates
    Buffer.minibuffer.insert("appl")

    # First Shift-TAB: start from last
    cycle_complete_minibuffer_backward
    assert_equal("apply", Buffer.minibuffer.to_s)
    assert_equal(2, Buffer.minibuffer[:cycle_index])

    Controller.current.last_command = :cycle_complete_minibuffer_backward

    # Second Shift-TAB: go to previous
    cycle_complete_minibuffer_backward
    assert_equal("application", Buffer.minibuffer.to_s)
    assert_equal(1, Buffer.minibuffer[:cycle_index])

    Controller.current.last_command = :cycle_complete_minibuffer_backward

    # Third Shift-TAB: go to first
    cycle_complete_minibuffer_backward
    assert_equal("apple", Buffer.minibuffer.to_s)
    assert_equal(0, Buffer.minibuffer[:cycle_index])

    Controller.current.last_command = :cycle_complete_minibuffer_backward

    # Fourth Shift-TAB: wrap around to last
    cycle_complete_minibuffer_backward
    assert_equal("apply", Buffer.minibuffer.to_s)
    assert_equal(2, Buffer.minibuffer[:cycle_index])
  end

  def test_mixed_forward_and_backward_cycling
    Buffer.minibuffer.insert("appl")

    # TAB: start forward cycling
    cycle_complete_minibuffer
    assert_equal("apple", Buffer.minibuffer.to_s)
    assert_equal(0, Buffer.minibuffer[:cycle_index])

    Controller.current.last_command = :cycle_complete_minibuffer

    # TAB: forward to next
    cycle_complete_minibuffer
    assert_equal("application", Buffer.minibuffer.to_s)
    assert_equal(1, Buffer.minibuffer[:cycle_index])

    Controller.current.last_command = :cycle_complete_minibuffer

    # Shift-TAB: go back
    cycle_complete_minibuffer_backward
    assert_equal("apple", Buffer.minibuffer.to_s)
    assert_equal(0, Buffer.minibuffer[:cycle_index])

    Controller.current.last_command = :cycle_complete_minibuffer_backward

    # TAB: forward again
    cycle_complete_minibuffer
    assert_equal("application", Buffer.minibuffer.to_s)
    assert_equal(1, Buffer.minibuffer[:cycle_index])
  end
end
