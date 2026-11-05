# Instance variables for __MOLT_HOSTNAME__
# Sourced by molt_render when rendering .tmpl files, and read by molt for
# MOLT_INSTALL_PREFIX, MOLT_CLAUDE_CONFIG_DIR, MOLT_FONT_FAMILY and
# MOLT_TERMINAL_DRAWN_BY (set it to windows where Windows draws this sleeve's
# terminal, as under WSL, and doctor leaves the font to the Windows side), and
# by some liberators for their own, eg tiling's MOLT_TACTILE_ACTIVATE. The env
# liberator publishes each other <TOOL>_INSTALL_PREFIX exported here.
# All variables must be exported: envsubst and molt see only exported ones.

export MOLT_HOSTNAME="__MOLT_HOSTNAME__"
export MOLT_USER="__MOLT_USER__"
export MOLT_SSH_KEY="id_ed25519"
export MOLT_PRJ_DIR="$HOME/Devel/prj"
export MOLT_OPT_DIR="$HOME/Devel/opt"
export MOLT_FONT_FAMILY="Hack Nerd Font Mono"  # a Nerd Font; the prompt glyphs need one
export MOLT_FONT_SIZE=13
export MOLT_PROMPT_HOST_COLOR="#2E86AB"
