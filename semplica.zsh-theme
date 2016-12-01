NEWLINE=$'\n'
PROMPT='%{$fg[magenta]%}%n%{$reset_color%} in %{$fg[yellow]%}%C%{$reset_color%}$(git_prompt_info) using %{$fg[yellow]%}$(~/.rvm/bin/rvm-prompt)%{$reset_color%} ${time} ${NEWLINE}$  '

# The right-hand prompt

RPROMPT='$(battery)'

# Add this at the start of RPROMPT to include rvm info showing ruby-version@gemset-name
# %{$fg[yellow]%}$(~/.rvm/bin/rvm-prompt)%{$reset_color%} 

# local time, color coded by last return code
time_enabled="%(?.%{$fg[green]%}.%{$fg[red]%})%*%{$reset_color%}"
time_disabled="%{$fg[green]%}%*%{$reset_color%}"
time=$time_enabled

ZSH_THEME_GIT_PROMPT_PREFIX=" on %{$fg[magenta]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[green]%}!"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[green]%}?"
ZSH_THEME_GIT_PROMPT_CLEAN=""

# Determine if we are using a gemset.
function rvm_gemset() {
    GEMSET=`rvm gemset list | grep '=>' | cut -b4-`
    if [[ -n $GEMSET ]]; then
        echo "%{$fg[yellow]%}$GEMSET%{$reset_color%}|"
    fi 
}

# Credit goes to @brymck with https://gist.github.com/brymck/3083365

function battery {
  # Adjust to your preferred number of segments
  typeset -i SEGMENTS
  SEGMENTS=10

  # Get maximum and current capacity as floats via ioreg
  results="$(ioreg -rc AppleSmartBattery)"
  typeset -F max_capacity
  typeset -F current_capacity
  max_capacity="$(echo $results | grep 'MaxCapacity' | awk '{print $3}')"
  current_capacity="$(echo $results | grep 'CurrentCapacity' | awk '{print $3}')"

  # Calculate the number of green, yellow and red segments
  segments_left=$(( $current_capacity / $max_capacity * $SEGMENTS ))
  typeset -i green_segments
  typeset -i yellow_segments
  typeset -i red_segments
  green_segments=$segments_left
  yellow_segments=$(( $segments_left - $green_segments > 0.5 ))
  red_segments=$(( $SEGMENTS - $green_segments - $yellow_segments ))

  # Display everything
  echo -n "%{$fg[green]%}"
  repeat $green_segments echo -n "⚡"
  echo -n "%{$fg[yellow]%}"
  repeat $yellow_segments echo -n "⚡"
  echo -n "%{$fg[red]%}"
  repeat $red_segments echo -n "⚡"
  echo -n "%{$reset_color%}"
}

# Determine the time since last commit. If branch is clean,
# use a neutral color, otherwise colors will vary according to time.
function git_time_since_commit() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Only proceed if there is actually a commit.
        if [[ $(git log 2>&1 > /dev/null | grep -c "^fatal: bad default revision") == 0 ]]; then
            # Get the last commit.
            last_commit=`git log --pretty=format:'%at' -1 2> /dev/null`
            now=`date +%s`
            seconds_since_last_commit=$((now-last_commit))

            # Totals
            MINUTES=$((seconds_since_last_commit / 60))
            HOURS=$((seconds_since_last_commit/3600))
           
            # Sub-hours and sub-minutes
            DAYS=$((seconds_since_last_commit / 86400))
            SUB_HOURS=$((HOURS % 24))
            SUB_MINUTES=$((MINUTES % 60))
            
            if [[ -n $(git status -s 2> /dev/null) ]]; then
                if [ "$MINUTES" -gt 30 ]; then
                    COLOR="$ZSH_THEME_GIT_TIME_SINCE_COMMIT_LONG"
                elif [ "$MINUTES" -gt 10 ]; then
                    COLOR="$ZSH_THEME_GIT_TIME_SHORT_COMMIT_MEDIUM"
                else
                    COLOR="$ZSH_THEME_GIT_TIME_SINCE_COMMIT_SHORT"
                fi
            else
                COLOR="$ZSH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL"
            fi

            if [ "$HOURS" -gt 24 ]; then
                echo "($(rvm_gemset)$COLOR${DAYS}d${SUB_HOURS}h${SUB_MINUTES}m%{$reset_color%}|"
            elif [ "$MINUTES" -gt 60 ]; then
                echo "($(rvm_gemset)$COLOR${HOURS}h${SUB_MINUTES}m%{$reset_color%}|"
            else
                echo "($(rvm_gemset)$COLOR${MINUTES}m%{$reset_color%}|"
            fi
        else
            COLOR="$ZSH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL"
            echo "($(rvm_gemset)$COLOR~|"
        fi
    fi
}
