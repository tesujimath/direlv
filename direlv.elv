use os
use path
use str

# emit hook suitable for inclusion in rc.elv
fn hook {
  echo '## hook for direlv
set @edit:before-readline = $@edit:before-readline {
  try {
  } catch e {
    echo $e
  }
}
'
}

fn canonical { |path|
  put (os:eval-symlinks (path:abs $path))
}

fn hash { |path|
  str:fields (echo $path | sha256sum) | take 1
}

fn hash-abbrev { |hash|
  put $hash[..7]
}

fn get-or-create-allow-dir {
  var data-home
  if (has-env XDG_DATA_HOME) {
    set data-home = $E:XDG_DATA_HOME
  } else {
    set data-home = (path:join $E:HOME '.local' 'share')
  }

  var allow-dir = (path:join $data-home 'direlv' 'allow')
  if (not (os:exists $allow-dir)) {
    os:mkdir-all $allow-dir
  }

  put $allow-dir
}

fn get-paths { |&dir=$nil|
  var module-path = (path:join (or $dir '.') 'activate.elv')

  if (not (os:exists $module-path)) {
    fail 'direlv: error activate.elv not found'
  }

  var canonical-module-path = (canonical $module-path)
  var canonical-module-path-hash = (hash $canonical-module-path)
  var namespace = (hash-abbrev $canonical-module-path-hash)
  var allow-path = (path:join (get-or-create-allow-dir) $canonical-module-path-hash)

  put [&module=$canonical-module-path &allow=$allow-path &namespace=$namespace]
}


# is `p` allowed, defaulting to current directory
fn is-allowed { |p|
  put (os:exists $p[allow])
}

# allow `dir`, defaulting to current directory
fn allow { |&dir=$nil|
  var p = (get-paths &dir=$dir)

  echo $p[module] >$p[allow]
}

# revoke `dir`, defaulting to current directory
fn revoke { |&dir=$nil|
  var p = (get-paths &dir=$dir)

  # allow-path not existing is harmless
  try {
    os:remove $p[allow]
  } catch e {
    if (not-eq $e os:-is-not-exist) {
      fail $e
    }
  }
}

fn activate {
  var p = (get-paths)
  if (not (is-allowed $p)) {
    fail $p[module]' is blocked. Run `direlv:allow` to approve its content'
  }

  eval &on-end={ |ns|
    echo >&2 'loading: '(keys $ns[export] | str:join ' ')
    edit:add-vars $ns[export]
  } (slurp <./activate.elv)
}
