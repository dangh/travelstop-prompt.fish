status is-interactive || exit

function __travelstop-prompt-enable
  set --query travelstop_dir || set --global travelstop_dir '/wip/travelstop/'
  string match --quiet "*$travelstop_dir*" (pwd)/
end

function __travelstop-prompt-repaint --on-variable AWS_PROFILE
  commandline --function repaint
end

function __restore_last_status --argument-names last_status
  return $last_status
end

set --local STARSHIP_CONFIG_ORIGINAL $STARSHIP_CONFIG

functions --query fish_prompt_original || functions --copy fish_prompt fish_prompt_original
starship init fish | source
functions --query fish_prompt_travelstop && functions --erase fish_prompt_travelstop
functions --copy fish_prompt fish_prompt_travelstop

function fish_prompt
  set last_status $status
  if __travelstop-prompt-enable
    __restore_last_status $last_status
    set --export STARSHIP_CONFIG ~/.config/fish/conf.d/travelstop-prompt.toml
    fish_prompt_travelstop
  else
    __restore_last_status $last_status
    set --export STARSHIP_CONFIG $STARSHIP_CONFIG_ORIGINAL
    fish_prompt_original
  end
end
