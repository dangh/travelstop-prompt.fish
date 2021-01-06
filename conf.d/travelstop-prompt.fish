status is-interactive || exit

set --local STARSHIP_CONFIG_ORIGINAL $STARSHIP_CONFIG

function __travelstop_prompt_aws_config --on-event clipboard_change --argument-names creds
  set --query travelstop_aws_config || return
  if string match --quiet --regex '^\[[[:alnum:]_]+\](\naws_[[:alpha:]_]+=.*)+$' "$creds"
    printf $creds | read --local --line profile aws_access_key_id aws_secret_access_key aws_session_token
    string match --regex '^\[([[:digit:]]+)_([[:alpha:]]+)\]' $profile | read --local --line _ account_id role
    for stage_config in $travelstop_aws_config
      echo $stage_config | read --delimiter=, --local _account_id stage region
      test "$account_id" = "$_account_id" || continue
      echo [$role@$stage]\n{$aws_access_key_id}\n{$aws_secret_access_key}\n{$aws_session_token} > ~/.aws/credentials
      set --universal --export AWS_PROFILE $role@$stage
      set --universal --export AWS_DEFAULT_REGION $region
    end
  end
end

function __travelstop_prompt_repaint --on-variable AWS_PROFILE
  set --local profile (string replace --regex '@.*' '' "$AWS_PROFILE")
  set --local stage (string replace --regex '.*@' '' "$AWS_PROFILE")
  switch $profile
  case ServerlessDeployNonProd
    set profile (set_color --bold yellow)$profile(set_color normal)
  case SystemAdministratorNonProd
    set profile (set_color --bold green)$profile(set_color normal)
  case AdministratorNonProd
    set profile (set_color --bold --underline green)$profile(set_color normal)
  end
  switch $stage
  case \*
    set stage (set_color --bold magenta)$stage(set_color normal)
  end
  set --global --export AWS_PROFILE_TRAVELSTOP $profile $stage
  commandline --function repaint-mode
end

function __travelstop_prompt_switch --on-variable PWD
  set --query travelstop_dir || set --local travelstop_dir '/wip/travelstop/'
  if string match --quiet "*$travelstop_dir*" "$PWD/"
    set --global --export STARSHIP_CONFIG ~/.config/fish/conf.d/travelstop-prompt.toml
    set --global travelstop_prompt_enabled
  else
    set --global --export STARSHIP_CONFIG $STARSHIP_CONFIG_ORIGINAL
    set --erase travelstop_prompt_enabled
  end
end

__travelstop_prompt_switch
__travelstop_prompt_repaint

functions --query fish_prompt_original || functions --copy fish_prompt fish_prompt_original
starship init fish | source
functions --query fish_prompt_travelstop && functions --erase fish_prompt_travelstop
functions --copy fish_prompt fish_prompt_travelstop

function fish_prompt
  set exit_code $status
  if set --query travelstop_prompt_enabled
    set --query travelstop_prompt_linebreak_enabled && echo
    set --global travelstop_prompt_linebreak_enabled
    test $exit_code -eq 0
    fish_prompt_travelstop
  else
    test $exit_code -eq 0
    fish_prompt_original
  end
end
