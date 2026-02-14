# frozen_string_literal: true

module Textbringer
  module Commands
    define_command(:previous_history_element,
                   doc: "Get previous element from minibuffer history.") do
      history = Buffer.minibuffer[:history]
      if history.nil?
        raise EditorError, "No history"
      end

      list = history.is_a?(Symbol) ? MinibufferHistory.get(history) : history
      if list.empty?
        raise EditorError, "Beginning of history; no preceding item"
      end

      index = Buffer.minibuffer[:history_index]

      # Save current input on first navigation
      if index < 0
        Buffer.minibuffer[:history_input] = Buffer.minibuffer.to_s
      end

      new_index = index + 1
      if new_index >= list.size
        raise EditorError, "Beginning of history; no preceding item"
      end

      Buffer.minibuffer[:history_index] = new_index
      Buffer.minibuffer.clear
      Buffer.minibuffer.insert(list[new_index])
    end

    define_command(:minibuffer_up,
                   doc: "Navigate up in minibuffer: cycle backward if cycling, else previous history.") do
      unless cycle_candidates_directly(-1)
        previous_history_element
      end
    end

    define_command(:minibuffer_down,
                   doc: "Navigate down in minibuffer: cycle forward if cycling, else next history.") do
      unless cycle_candidates_directly(1)
        next_history_element
      end
    end

    define_command(:next_history_element,
                   doc: "Get next element from minibuffer history.") do
      history = Buffer.minibuffer[:history]
      if history.nil?
        raise EditorError, "No history"
      end

      index = Buffer.minibuffer[:history_index]
      if index < 0
        raise EditorError, "End of history; no default available"
      end

      new_index = index - 1
      Buffer.minibuffer[:history_index] = new_index
      Buffer.minibuffer.clear

      if new_index < 0
        # Restore original input
        input = Buffer.minibuffer[:history_input]
        Buffer.minibuffer.insert(input) if input
      else
        list = history.is_a?(Symbol) ? MinibufferHistory.get(history) : history
        Buffer.minibuffer.insert(list[new_index])
      end
    end
  end
end
