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

### Tab Completion Cycling

zsh-style tab completion cycling for minibuffer:

- **1st TAB** - Complete to the common prefix and show candidates in `*Completions*` buffer
- **2nd TAB** (when no further prefix progress) - Start cycling through candidates
- **Subsequent TABs** - Cycle to the next candidate (wraps around at the end)
- **Any other key** - Reset cycling state

This replaces the default `complete_minibuffer` command on the TAB key.

## Installation

### Via git clone

Clone this repository to your Textbringer plugins directory:

```bash
git clone https://github.com/kurod1492/textbringer-minibuffer-extension.git ~/.textbringer/plugins/textbringer-minibuffer-extension
```

### Via rake install

After checking out the repo, run `bundle install` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`.

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
