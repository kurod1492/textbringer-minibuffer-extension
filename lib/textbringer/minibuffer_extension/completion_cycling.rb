# frozen_string_literal: true

module Textbringer
  module Commands
    CYCLING_COMMANDS = [
      :cycle_complete_minibuffer,
      :cycle_complete_minibuffer_backward,
      :minibuffer_up,
      :minibuffer_down
    ].freeze

    define_command(:cycle_complete_minibuffer,
                   doc: "Complete minibuffer input with cycling support.") do
      cycle_complete_minibuffer_internal(1)
    end

    define_command(:cycle_complete_minibuffer_backward,
                   doc: "Complete minibuffer input with backward cycling.") do
      cycle_complete_minibuffer_internal(-1)
    end

    # 既存の candidates を使って cycling だけを行う（last_command チェックなし）
    def cycle_candidates_directly(direction)
      minibuffer = Buffer.minibuffer
      candidates = minibuffer[:cycle_candidates]
      return false unless candidates && candidates.size > 1
      cycle_index = minibuffer[:cycle_index]
      new_index = (cycle_index + direction) % candidates.size
      minibuffer[:cycle_index] = new_index
      complete_minibuffer_with_string(candidates[new_index])
      update_completions_with_selection(candidates, new_index)
      true
    end
    private :cycle_candidates_directly

    def cycle_complete_minibuffer_internal(direction)
      minibuffer = Buffer.minibuffer
      completion_proc = minibuffer[:completion_proc]
      return unless completion_proc
      ignore_case = minibuffer[:completion_ignore_case]
      current_text = minibuffer.to_s

      candidates = minibuffer[:cycle_candidates]
      if CYCLING_COMMANDS.include?(Controller.current.last_command) &&
         candidates && candidates.size > 1
        cycle_candidates_directly(direction)
      else
        xs = completion_proc.call(current_text)
        update_completions(xs)
        if xs.empty?
          message("No match", sit_for: 1)
          minibuffer[:cycle_candidates] = nil
          return
        end
        if xs.size == 1
          complete_minibuffer_with_string(xs[0])
          minibuffer[:cycle_candidates] = nil
          return
        end
        y, *ys = xs
        s = y.size.downto(1).lazy.map { |i| y[0, i] }.find { |i|
          ci = ignore_case ? i.downcase : i
          ys.all? { |j|
            cj = ignore_case ? j.downcase : j
            cj.start_with?(ci)
          }
        }
        if s
          complete_minibuffer_with_string(s)
        end
        completed_text = minibuffer.to_s
        if completed_text == current_text
          minibuffer[:cycle_candidates] = xs
          start_index = direction == 1 ? 0 : xs.size - 1
          minibuffer[:cycle_index] = start_index
          complete_minibuffer_with_string(xs[start_index])
          update_completions_with_selection(xs, start_index)
        else
          minibuffer[:cycle_candidates] = xs
          minibuffer[:cycle_index] = -1
        end
      end
    end
    private :cycle_complete_minibuffer_internal

    def update_completions_with_selection(xs, selected_index)
      if COMPLETION[:completions_window].nil?
        Window.list.last.split
        COMPLETION[:completions_window] = Window.list.last
      end
      completions = Buffer.find_or_new("*Completions*", undo_limit: 0)
      if !completions.mode.is_a?(CyclingCompletionListMode)
        completions.apply_mode(CyclingCompletionListMode)
      end
      CyclingCompletionListMode.set_selected_pattern(xs[selected_index])
      completions.read_only = false
      begin
        completions.clear
        xs.each do |x|
          completions.insert("#{x}\n")
        end
        completions.beginning_of_buffer
        selected_index.times { completions.next_line }
        COMPLETION[:completions_window].buffer = completions
      ensure
        completions.read_only = true
      end
    end
    private :update_completions_with_selection
  end
end
