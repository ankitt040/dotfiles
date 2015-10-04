#!/usr/bin/env zsh

HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=magenta,fg=white,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=red,fg=white,bold'
HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS='i'


function history-substring-search-up() {
_history-substring-search-begin

_history-substring-search-up-history ||
  _history-substring-search-up-buffer ||
  _history-substring-search-up-search

_history-substring-search-end
}

function history-substring-search-down() {
_history-substring-search-begin

_history-substring-search-down-history ||
  _history-substring-search-down-buffer ||
  _history-substring-search-down-search

_history-substring-search-end
}

zle -N history-substring-search-up
zle -N history-substring-search-down

zmodload zsh/terminfo
if [[ -n "$terminfo[kcuu1]" ]]; then
  bindkey "$terminfo[kcuu1]" history-substring-search-up
fi
if [[ -n "$terminfo[kcud1]" ]]; then
  bindkey "$terminfo[kcud1]" history-substring-search-down
fi

#-----------------------------------------------------------------------------
# implementation details
#-----------------------------------------------------------------------------

zmodload -F zsh/parameter


if [[ $+functions[_zsh_highlight] -eq 0 ]]; then
  function _zsh_highlight() {
  region_highlight=()
}

#
# Remove existing highlights when the user
# inserts printable characters into $BUFFER
#
function ordinary-key-press() {
if [[ $KEYS == [[:print:]] ]]; then
  region_highlight=()
fi
zle .self-insert
  }
  zle -N self-insert ordinary-key-press


  # Load ZSH module zsh/zleparameter, needed to override user defined widgets.
  zmodload zsh/zleparameter 2>/dev/null || {
  echo 'zsh-syntax-highlighting: failed loading zsh/zleparameter, exiting.' >&2
  return -1
}

# Override ZLE widgets to make them invoke _zsh_highlight.
for event in ${${(f)"$(zle -la)"}:#(_*|orig-*|.run-help|.which-command)}; do
  if [[ "$widgets[$event]" == completion:* ]]; then
    eval "zle -C orig-$event ${${${widgets[$event]}#*:}/:/ } ; $event() { builtin zle orig-$event && _zsh_highlight } ; zle -N $event"
  else
    case $event in
      accept-and-menu-complete)
        eval "$event() { builtin zle .$event && _zsh_highlight } ; zle -N $event"
        ;;

        # The following widgets should NOT remove any previously
        # applied highlighting. Therefore we do not remap them.
        .forward-char|.backward-char|.up-line-or-history|.down-line-or-history)
        ;;

      .*)
        clean_event=$event[2,${#event}] # Remove the leading dot in the event name
        case ${widgets[$clean_event]-} in
          (completion|user):*)
            ;;
          *)
            eval "$clean_event() { builtin zle $event && _zsh_highlight } ; zle -N $clean_event"
            ;;
        esac
        ;;
      *)
        ;;
    esac
  fi
done
unset event clean_event
#-------------->8------------------->8------------------->8-----------------
fi

function _history-substring-search-begin() {
  setopt localoptions extendedglob
  _history_substring_search_move_cursor_eol=false
  _history_substring_search_query_highlight=

  #
  # Continue using the previous $_history_substring_search_result by default,
  # unless the current query was cleared or a new/different query was entered.
  #
  if [[ -z $BUFFER || $BUFFER != $_history_substring_search_result ]]; then
    _history_substring_search_query=$BUFFER

    #
    # $BUFFER contains the text that is in the command-line currently.
    # we put an extra "\\" before meta characters such as "\(" and "\)",
    # so that they become "\\\(" and "\\\)".
    #
    _history_substring_search_query_escaped=${BUFFER//(#m)[\][()|\\*?#<>~^]/\\$MATCH}

    #
    # Find all occurrences of the search query in the history file.
    #
    # (k) turns it an array of line numbers.
    #
    # (on) seems to remove duplicates, which are default
    #      options. They can be turned off by (ON).
    #
    _history_substring_search_matches=(${(kon)history[(R)(#$HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS)*${_history_substring_search_query_escaped}*]})

    #
    # Define the range of values that $_history_substring_search_match_index
    # can take: [0, $_history_substring_search_matches_count_plus].
    #
    _history_substring_search_matches_count=$#_history_substring_search_matches
    _history_substring_search_matches_count_plus=$(( _history_substring_search_matches_count + 1 ))
    _history_substring_search_matches_count_sans=$(( _history_substring_search_matches_count - 1 ))

    #
    # If $_history_substring_search_match_index is equal to
    # $_history_substring_search_matches_count_plus, this indicates that we
    # are beyond the beginning of $_history_substring_search_matches.
    #
    # If $_history_substring_search_match_index is equal to 0, this indicates
    # that we are beyond the end of $_history_substring_search_matches.
    #
    # If we have initially pressed "up" we have to initialize
    # $_history_substring_search_match_index to
    # $_history_substring_search_matches_count_plus so that it will be
    # decreased to $_history_substring_search_matches_count.
    #
    # If we have initially pressed "down" we have to initialize
    # $_history_substring_search_match_index to
    # $_history_substring_search_matches_count so that it will be increased to
    # $_history_substring_search_matches_count_plus.
    #
    if [[ $WIDGET == history-substring-search-down ]]; then
      _history_substring_search_match_index=$_history_substring_search_matches_count
    else
      _history_substring_search_match_index=$_history_substring_search_matches_count_plus
    fi
  fi
}

function _history-substring-search-end() {
  setopt localoptions extendedglob
  _history_substring_search_result=$BUFFER

  # move the cursor to the end of the command line
  if [[ $_history_substring_search_move_cursor_eol == true ]]; then
    CURSOR=${#BUFFER}
  fi

  # highlight command line using zsh-syntax-highlighting
  _zsh_highlight

  # highlight the search query inside the command line
  if [[ -n $_history_substring_search_query_highlight && -n $_history_substring_search_query ]]; then
    #
    # The following expression yields a variable $MBEGIN, which
    # indicates the begin position + 1 of the first occurrence
    # of _history_substring_search_query_escaped in $BUFFER.
    #
    : ${(S)BUFFER##(#m$HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS)($_history_substring_search_query##)}
    local begin=$(( MBEGIN - 1 ))
    local end=$(( begin + $#_history_substring_search_query ))
    region_highlight+=("$begin $end $_history_substring_search_query_highlight")
  fi


  # Exit successfully from the history-substring-search-* widgets.
  true
}

function _history-substring-search-up-buffer() {
  local buflines XLBUFFER xlbuflines
  buflines=(${(f)BUFFER})
  XLBUFFER=$LBUFFER"x"
  xlbuflines=(${(f)XLBUFFER})

  if [[ $#buflines -gt 1 && $CURSOR -ne $#BUFFER && $#xlbuflines -ne 1 ]]; then
    zle up-line-or-history
    return true
  fi

  false
}

function _history-substring-search-down-buffer() {
  local buflines XRBUFFER xrbuflines
  buflines=(${(f)BUFFER})
  XRBUFFER="x"$RBUFFER
  xrbuflines=(${(f)XRBUFFER})

  if [[ $#buflines -gt 1 && $CURSOR -ne $#BUFFER && $#xrbuflines -ne 1 ]]; then
    zle down-line-or-history
    return true
  fi

  false
}

function _history-substring-search-up-history() {
  if [[ -z $_history_substring_search_query ]]; then

    # we have reached the absolute top of history
    if [[ $HISTNO -eq 1 ]]; then
      BUFFER=

      # going up from somewhere below the top of history
    else
      zle up-history
    fi

    return true
  fi

  false
}

function _history-substring-search-down-history() {
  if [[ -z $_history_substring_search_query ]]; then

    # going down from the absolute top of history
    if [[ $HISTNO -eq 1 && -z $BUFFER ]]; then
      BUFFER=${history[1]}
      _history_substring_search_move_cursor_eol=true

      # going down from somewhere above the bottom of history
    else
      zle down-history
    fi

    return true
  fi

  false
}

function _history-substring-search-up-search() {
_history_substring_search_move_cursor_eol=true

if [[ $_history_substring_search_match_index -ge 2 ]]; then
  #
  # Highlight the next match:
  #
  # 1. Decrease the value of $_history_substring_search_match_index.
  #
  # 2. Use $HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND
  #    to highlight the current buffer.
  #
  (( _history_substring_search_match_index-- ))
  BUFFER=$history[$_history_substring_search_matches[$_history_substring_search_match_index]]
  _history_substring_search_query_highlight=$HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND

elif [[ $_history_substring_search_match_index -eq 1 ]]; then
  (( _history_substring_search_match_index-- ))
  _history_substring_search_old_buffer=$BUFFER
  BUFFER=$_history_substring_search_query
  _history_substring_search_query_highlight=$HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND

elif [[ $_history_substring_search_match_index -eq $_history_substring_search_matches_count_plus ]]; then
  (( _history_substring_search_match_index-- ))
  BUFFER=$_history_substring_search_old_buffer
  _history_substring_search_query_highlight=$HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND
fi
}

function _history-substring-search-down-search() {
  _history_substring_search_move_cursor_eol=true

  if [[ $_history_substring_search_match_index -le $_history_substring_search_matches_count_sans ]]; then
    (( _history_substring_search_match_index++ ))
    BUFFER=$history[$_history_substring_search_matches[$_history_substring_search_match_index]]
    _history_substring_search_query_highlight=$HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND

  elif [[ $_history_substring_search_match_index -eq $_history_substring_search_matches_count ]]; then
    (( _history_substring_search_match_index++ ))
    _history_substring_search_old_buffer=$BUFFER
    BUFFER=$_history_substring_search_query
    _history_substring_search_query_highlight=$HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND

  elif [[ $_history_substring_search_match_index -eq 0 ]]; then
    (( _history_substring_search_match_index++ ))
    BUFFER=$_history_substring_search_old_buffer
    _history_substring_search_query_highlight=$HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND
  fi
}
