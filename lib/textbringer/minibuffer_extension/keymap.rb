# frozen_string_literal: true

module Textbringer
  MINIBUFFER_LOCAL_MAP.define_key("\M-p", :previous_history_element)
  MINIBUFFER_LOCAL_MAP.define_key("\M-n", :next_history_element)
  MINIBUFFER_LOCAL_MAP.define_key(:up, :minibuffer_up)
  MINIBUFFER_LOCAL_MAP.define_key(:down, :minibuffer_down)
  MINIBUFFER_LOCAL_MAP.define_key(?\t, :cycle_complete_minibuffer)
  MINIBUFFER_LOCAL_MAP.define_key(:btab, :cycle_complete_minibuffer_backward)
end
