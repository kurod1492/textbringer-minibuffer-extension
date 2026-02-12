# frozen_string_literal: true

module Textbringer
  module Commands
    define_command(:cycle_complete_minibuffer,
                   doc: "Complete minibuffer input with cycling support.") do
      minibuffer = Buffer.minibuffer
      completion_proc = minibuffer[:completion_proc]
      next unless completion_proc
      ignore_case = minibuffer[:completion_ignore_case]
      current_text = minibuffer.to_s

      candidates = minibuffer[:cycle_candidates]
      if Controller.current.last_command == :cycle_complete_minibuffer &&
         candidates && candidates.size > 1
        cycle_index = minibuffer[:cycle_index]
        new_index = (cycle_index + 1) % candidates.size
        minibuffer[:cycle_index] = new_index
        complete_minibuffer_with_string(candidates[new_index])
      else
        xs = completion_proc.call(current_text)
        update_completions(xs)
        if xs.empty?
          message("No match", sit_for: 1)
          minibuffer[:cycle_candidates] = nil
          next
        end
        if xs.size == 1
          complete_minibuffer_with_string(xs[0])
          minibuffer[:cycle_candidates] = nil
          next
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
          minibuffer[:cycle_index] = 0
          complete_minibuffer_with_string(xs[0])
        else
          minibuffer[:cycle_candidates] = xs
          minibuffer[:cycle_index] = -1
        end
      end
    end
  end
end
