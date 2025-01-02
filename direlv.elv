use ./_direlv

fn activate { |&dir=$nil|
  _direlv:activate &dir=$dir $edit:
}

fn deactivate { |&dir=$nil|
  _direlv:deactivate &dir=$dir $edit:
}

fn handle-cwd {
  _direlv:handle-cwd $edit:
}

fn allow { |&dir=$nil|
  _direlv:allow &dir=$dir
}

fn revoke { |&dir=$nil|
  _direlv:revoke &dir=$dir
}

# emit hook suitable for inclusion in rc.elv
fn hook {
  echo '## hook for direlv
set @edit:before-readline = $@edit:before-readline {
  try {
    direlv:handle-cwd
  } catch e {
    echo $e
  }
}'
}
