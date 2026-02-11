# frozen_string_literal: true

module Textbringer
  module Utils
    alias_method :read_from_minibuffer_without_history, :read_from_minibuffer

    def read_from_minibuffer(prompt, completion_proc: nil, default: nil,
                             initial_value: nil, completion_ignore_case: false,
                             keymap: MINIBUFFER_LOCAL_MAP,
                             history: nil)
      if Window.echo_area.active?
        raise EditorError,
          "Command attempted to use minibuffer while in minibuffer"
      end
      old_buffer = Buffer.current
      old_minibuffer_selected = Window.minibuffer_selected
      Window.minibuffer_selected = Window.current
      old_completion_proc = Buffer.minibuffer[:completion_proc]
      old_completion_ignore_case = Buffer.minibuffer[:completion_ignore_case]
      old_history = Buffer.minibuffer[:history]
      old_history_index = Buffer.minibuffer[:history_index]
      old_history_input = Buffer.minibuffer[:history_input]
      old_current_prefix_arg = Controller.current.current_prefix_arg
      old_minibuffer_map = Buffer.minibuffer.keymap
      Buffer.minibuffer.keymap = keymap
      Buffer.minibuffer[:completion_proc] = completion_proc
      Buffer.minibuffer[:completion_ignore_case] = completion_ignore_case
      Buffer.minibuffer[:history] = history
      Buffer.minibuffer[:history_index] = -1
      Buffer.minibuffer[:history_input] = nil
      Window.echo_area.active = true
      begin
        Window.current = Window.echo_area
        Buffer.minibuffer.clear
        Buffer.minibuffer.insert(initial_value) if initial_value
        if default
          prompt = prompt.sub(/:/, " (default #{default}):")
        end
        Window.echo_area.prompt = prompt
        Window.echo_area.redisplay
        Window.update
        recursive_edit
        s = Buffer.minibuffer.to_s
        result = if default && s.empty?
          default
        else
          s
        end
        # Add to history if using symbol-based history
        if history.is_a?(Symbol) && result && !result.empty?
          MinibufferHistory.add(history, result)
        end
        result
      ensure
        Window.echo_area.clear
        Window.echo_area.redisplay
        Window.update
        Window.echo_area.active = false
        Window.current = Window.minibuffer_selected
        Window.current.buffer = Buffer.current = old_buffer
        Window.minibuffer_selected = old_minibuffer_selected
        Buffer.minibuffer[:completion_ignore_case] = old_completion_ignore_case
        Buffer.minibuffer[:completion_proc] = old_completion_proc
        Buffer.minibuffer[:history] = old_history
        Buffer.minibuffer[:history_index] = old_history_index
        Buffer.minibuffer[:history_input] = old_history_input
        Buffer.minibuffer.keymap = old_minibuffer_map
        Buffer.minibuffer.disable_input_method
        Controller.current.current_prefix_arg = old_current_prefix_arg
        delete_completions_window
      end
    end

    alias_method :read_file_name_without_history, :read_file_name

    def read_file_name(prompt, default: nil, history: :file)
      f = ->(s) {
        s = File.expand_path(s) if s.start_with?("~")
        Dir.glob(s + "*").map { |file|
          if File.directory?(file)
            file + "/"
          else
            file
          end
        }
      }
      initial_value = default&.dup || Dir.pwd + "/"
      ignore_case = CONFIG[:read_file_name_completion_ignore_case]
      file = read_from_minibuffer(prompt, completion_proc: f,
                                  initial_value: initial_value,
                                  completion_ignore_case: ignore_case,
                                  history: history)
      File.expand_path(file)
    end

    alias_method :read_buffer_without_history, :read_buffer

    def read_buffer(prompt, default: Buffer.other.name, history: :buffer)
      f = ->(s) { complete_for_minibuffer(s, Buffer.names) }
      read_from_minibuffer(prompt, completion_proc: f, default: default,
                           history: history)
    end

    alias_method :read_command_name_without_history, :read_command_name

    def read_command_name(prompt, history: :command)
      f = ->(s) {
        complete_for_minibuffer(s.tr("-", "_"), Commands.list.map(&:to_s))
      }
      read_from_minibuffer(prompt, completion_proc: f, history: history)
    end
  end
end
