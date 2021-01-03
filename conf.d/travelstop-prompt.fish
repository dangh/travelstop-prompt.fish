status is-interactive || exit

set --local STARSHIP_CONFIG_ORIGINAL $STARSHIP_CONFIG
set --global --export travelstop_prompt_aws_profile (string replace --regex '@.*' '' "$AWS_PROFILE")
set --global --export travelstop_prompt_aws_stage (string replace --regex '.*@' '' "$AWS_PROFILE")

function __travelstop_prompt_toggle --on-variable PWD
  set --query travelstop_dir || set --global travelstop_dir '/wip/travelstop/'
  if string match --quiet "*$travelstop_dir*" "$PWD/"
    set --global --export STARSHIP_CONFIG ~/.config/fish/conf.d/travelstop-prompt.toml
    set --global travelstop_prompt_enabled
  else
    set --global --export STARSHIP_CONFIG $STARSHIP_CONFIG_ORIGINAL
    set --erase --global travelstop_prompt_enabled
  end
end

__travelstop_prompt_toggle

function __travelstop_prompt_repaint --on-variable AWS_PROFILE
  set --global --export travelstop_prompt_aws_profile (string replace --regex '@.*' '' "$AWS_PROFILE")
  set --global --export travelstop_prompt_aws_stage (string replace --regex '.*@' '' "$AWS_PROFILE")
  commandline --function repaint-mode
end

function __restore_last_status --argument-names last_status
  return $last_status
end

functions --query fish_prompt_original || functions --copy fish_prompt fish_prompt_original
starship init fish | source
functions --query fish_prompt_travelstop && functions --erase fish_prompt_travelstop
functions --copy fish_prompt fish_prompt_travelstop

function __travelstop_prompt_linebreak_enable --on-event fish_postexec
  set --global travelstop_prompt_linebreak_enabled
end

function fish_prompt
  set last_status $status
  if set --query --global travelstop_prompt_enabled
    set --query --global travelstop_prompt_linebreak_enabled && echo
    __restore_last_status $last_status
    fish_prompt_travelstop
  else
    __restore_last_status $last_status
    fish_prompt_original
  end
end
