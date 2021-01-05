function travelstop-aws-config --on-event clipboard_change --argument-names creds
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
