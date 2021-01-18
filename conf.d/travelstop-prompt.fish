function _tsp_notify --argument-names title message sound --description "send notification to system"
  osascript -e "display notification \"$message\" with title \"$title\"" &
  set sound "/System/Library/Sounds/$sound.aiff"
  test -f "$sound" && afplay $sound &
end

function _tsp_aws_config --on-event clipboard_change --argument-names creds
  set --query tsp_aws_config || return
  if string match --quiet --regex '^\[[[:alnum:]_]+\](\naws_[[:alpha:]_]+=.*)+$' "$creds"
    printf $creds | read --local --line profile aws_access_key_id aws_secret_access_key aws_session_token
    string match --regex '^\[([[:digit:]]+)_([[:alpha:]]+)\]' $profile | read --local --line _ account_id role
    for stage_config in $tsp_aws_config
      echo $stage_config | read --delimiter=, --local _account_id stage region
      test "$account_id" = "$_account_id" || continue
      echo [$role@$stage]\n{$aws_access_key_id}\n{$aws_secret_access_key}\n{$aws_session_token} > ~/.aws/credentials
      set --universal --export AWS_PROFILE $role@$stage
      set --universal --export AWS_DEFAULT_REGION $region
      set --local notif_profile $AWS_PROFILE
      set --local notif_region $region
      set --local title 📮 AWS profile updated
      functions --query fontface &&
        set notif_profile (fontface math_monospace "$notif_profile") &&
        set notif_region (fontface math_monospace "$notif_region")
      _tsp_notify "$title" "$notif_profile\n$notif_region"
    end
  end
end

status is-interactive || exit

set --query tsp_color_profile || set --global tsp_color_stage \--bold magenta
set --query tsp_color_stage || set --global tsp_color_stage \--bold magenta
set --query tsp_color_sep || set --global tsp_color_sep \--dim magenta
set --query tsp_sep || set --global tsp_sep @

for color in tsp_color_{profile,stage,sep}
  function $color --inherit-variable color
    set colors
    for color_ in {$color}_{$_tsp_profile}_{$_tsp_stage} {$color}_{$_tsp_profile} {$color}_{$_tsp_stage} $color
      set --query $color_ && set _color $color_ && break
    end
    set --global _$color (set_color $$_color)
  end
end

function _tsp_repaint --on-variable AWS_PROFILE
  set --global _tsp_profile (string replace --regex '@.*' '' "$AWS_PROFILE")
  set --global _tsp_stage (string replace --regex '.*@' '' "$AWS_PROFILE")
  tsp_color_profile
  tsp_color_stage
  tsp_color_sep
  commandline --function repaint-mode
  commandline --function repaint
end && _tsp_repaint

function _tsp_enable --on-variable PWD
  set --query tsp_path || set --local tsp_path '/wip/travelstop/'
  if string match --quiet "*$tsp_path*" "$PWD/"
    set --global _tsp_enable
  else
    set --erase _tsp_enable
  end
end && _tsp_enable

! functions --query fish_right_prompt_original && functions --query fish_right_prompt && functions --copy fish_right_prompt fish_right_prompt_original

function fish_right_prompt
  if set --query _tsp_enable
    string unescape "$_tsp_color_profile$_tsp_profile\x1b[0m$_tsp_color_sep$tsp_sep\x1b[0m$_tsp_color_stage$_tsp_stage\x1b[0m"
  else
    functions --query fish_right_prompt_original && fish_right_prompt_original
  end
end
