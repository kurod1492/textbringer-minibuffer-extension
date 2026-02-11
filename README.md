# textbringer-minibuffer-extension

Minibuffer extensions for [Textbringer](https://github.com/shugo/textbringer).

## Features

### Minibuffer History

Navigate through minibuffer input history using:

- `M-p` / `Up` - Previous history element
- `M-n` / `Down` - Next history element

History is automatically saved for:
- File names (`:file`)
- Buffer names (`:buffer`)
- Command names (`:command`)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'textbringer-minibuffer-extension'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install textbringer-minibuffer-extension
```

## Configuration

You can customize the history behavior in your `~/.textbringer.rb`:

```ruby
# Maximum number of history entries (default: 100)
CONFIG[:history_length] = 100

# Remove duplicate entries (default: true)
CONFIG[:history_delete_duplicates] = true

# Optional: Add C-p/C-n keybindings for history navigation
MINIBUFFER_LOCAL_MAP.define_key(?\C-p, :previous_history_element)
MINIBUFFER_LOCAL_MAP.define_key(?\C-n, :next_history_element)
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
