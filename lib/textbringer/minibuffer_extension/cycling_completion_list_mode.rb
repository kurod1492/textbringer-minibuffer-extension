# frozen_string_literal: true

module Textbringer
  Face.define :completion_selected, reverse: true

  class CyclingCompletionListMode < CompletionListMode
    @syntax_table = {}
    define_syntax :completion_selected, /\z\A/
    define_syntax :link, /^.+$/

    def self.set_selected_pattern(candidate)
      @syntax_table[:completion_selected] = /^#{Regexp.escape(candidate)}$/
    end

    def choose_completion
      unless Window.echo_area.active?
        raise EditorError, "Minibuffer is not active"
      end
      s = @buffer.save_excursion {
        @buffer.beginning_of_line
        @buffer.looking_at?(/^(.*)/)
        @buffer.match_string(1)
      }
      if s && s.size > 0
        Window.current = Window.echo_area
        complete_minibuffer_with_string(s)
        delete_completions_window
      end
    end
  end
end
