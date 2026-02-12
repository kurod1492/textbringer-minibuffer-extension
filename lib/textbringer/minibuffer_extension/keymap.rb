# frozen_string_literal: true

module Textbringer
  MINIBUFFER_LOCAL_MAP.define_key("\M-p", :previous_history_element)
  MINIBUFFER_LOCAL_MAP.define_key("\M-n", :next_history_element)
  MINIBUFFER_LOCAL_MAP.define_key(:up, :previous_history_element)
  MINIBUFFER_LOCAL_MAP.define_key(:down, :next_history_element)
  MINIBUFFER_LOCAL_MAP.define_key(?\t, :cycle_complete_minibuffer)
end
