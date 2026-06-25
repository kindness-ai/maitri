# maitri fish config — sets up the maitri/maitri environment for fish.
# Add your own aliases, functions, and exports below the maitri block.

if status is-interactive
    # maitri / maitri paths + commands (maitri, maitri, etc.)
    set -gx MAITRI_PATH "$HOME/.local/share/maitri"
    fish_add_path "$MAITRI_PATH/bin" "$HOME/.local/bin"

    set -gx EDITOR code
    set -gx SUDO_EDITOR "$EDITOR"
    set -gx BAT_THEME ansi

    # Tool integrations (only if installed)
    command -q starship; and starship init fish | source
    command -q zoxide; and zoxide init fish | source
    command -q mise; and mise activate fish | source
    if command -q fzf
        fzf --fish 2>/dev/null | source
    end

    # maitri "Spark" syntax colors
    set -g fish_color_command 82AAFF
    set -g fish_color_param E6E9F0
    set -g fish_color_quote 7DE38B
    set -g fish_color_redirection C99BFF
    set -g fish_color_error FF6E6E
    set -g fish_color_autosuggestion 7E879B
    set -g fish_color_comment 7E879B
end
