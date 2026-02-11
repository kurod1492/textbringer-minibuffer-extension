# frozen_string_literal: true

module Textbringer
  MINIBUFFER_HISTORY = Hash.new { |h, k| h[k] = [] }

  CONFIG[:history_length] = 100
  CONFIG[:history_delete_duplicates] = true

  module MinibufferHistory
    class << self
      def get(name)
        MINIBUFFER_HISTORY[name]
      end

      def add(name, value)
        return if value.nil? || value.empty?
        list = MINIBUFFER_HISTORY[name]
        list.delete(value) if CONFIG[:history_delete_duplicates]
        list.unshift(value)
        list.pop while list.size > CONFIG[:history_length]
      end
    end
  end
end
