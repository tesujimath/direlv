use os
use path
use str

# in order of activation, most recent at the head
var _dir-stack = []

fn _get-context { |&dir=$nil|
  fn hash { |path|
    str:fields (echo $path | sha256sum) | take 1
  }

  fn canonical { |path|
    put (os:eval-symlinks (path:abs $path))
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

  var module-base = 'dir.elv'
  var module-path = (path:join (or $dir '.') $module-base)

  if (not (os:exists $module-path)) {
    put [&dir=(or $dir '.') &module-base=$module-base]
  } else {
    var canonical-module-path = (canonical $module-path)
    var canonical-module-path-hash = (hash $canonical-module-path)
    var canonical-module-dir = (path:dir $canonical-module-path)
    var allow-path = (path:join (get-or-create-allow-dir) $canonical-module-path-hash)

    put [&dir=$canonical-module-dir &module-base=$module-base &module=$canonical-module-path &allow=$allow-path &hash=$canonical-module-path-hash]
  }
}

fn _fail-if-missing { |cx|
  if (not (has-key $cx module)) {
    fail 'direlv: error '(path:base $cx[module-base])' not found in '$cx[dir]
  }
}

fn _beautify-path { |path|
  if (and (has-env HOME) (str:has-prefix $path $E:HOME)) {
    put '~'(str:trim-prefix $path $E:HOME)
  } else {
    put $path
  }
}

fn activate { |&dir=$nil &cx=$nil edit-ns:|
  fn is-allowed { |cx|
    put (os:exists $cx[allow])
  }

  if (eq $cx $nil) {
    set cx = (_get-context &dir=$dir)
  }
  _fail-if-missing $cx

  if (not (is-allowed $cx)) {
    echo >&2 'direlv: warning '(_beautify-path $cx[dir])' is blocked. Run `direlv:allow` to approve its content'
  } else {
    echo >&2 'direlv: loading '(_beautify-path $cx[dir])
    eval &on-end={ |ns|
      if (has-key $ns export) {
        var exported-names = (keys $ns[export] | put [(all)])
        echo >&2 'direlv: export '(str:join ' ' $exported-names)
        $edit-ns:add-vars~ $ns[export]
        set _dir-stack = (conj [[&dir=$cx[dir] &exports=$ns[export]]] $@_dir-stack)
      } else {
        echo >&2 'direlv: warning export not defined'
      }
    } (slurp <$cx[module])
  }
}

# deactivate and restore the most recently overwritten variables
fn deactivate { |&dir=$nil edit-ns:|
  var cx = (_get-context &dir=$dir)
  _fail-if-missing $cx

  echo >&2 'direlv: unloading '(_beautify-path $cx[dir])

  # get the names to deactivate
  var deactivating = [&]
  keep-if { |a| ==s $a[dir] $cx[dir] } $_dir-stack |
    each { |a| keys $a[exports] } |
    each { |name| set deactivating[$name] = $true }

  # determine what is still active
  set _dir-stack = (keep-if { |a| !=s $a[dir] $cx[dir] } $_dir-stack | put [(all)])

  # reinstate what was overridden
  for a $_dir-stack {
    var reinstating = [&]
    keys $deactivating | each { |name|
      if (has-key $a[exports] $name) {
        set reinstating[$name] = $a[exports][$name]
        del deactivating[$name]
      }
    }
    if (> (count $reinstating) 0) {
      echo >&2 'direlv: reinstate '(str:join ' ' (keys $reinstating | put [(all)]))' for '(_beautify-path $a[dir])
      $edit-ns:add-vars~ $reinstating
    }
  }

  # remove whatever didn't get reinstated
  var remaining-names = (keys $deactivating | put [(all)])
  echo >&2 'direlv: unexport '(str:join ' ' $remaining-names)
  $edit-ns:del-vars~ $remaining-names
}

fn _is-ancestor { |ancestor descendant|
  str:has-prefix (str:trim-suffix $descendant '/')'/' (str:trim-suffix $ancestor '/')'/'
}

fn _activate-after-ancestors { |dir edit-ns:|
  if (or (== (count $_dir-stack) 0) (not-eq $_dir-stack[0][dir] $dir)) {
    var parent = (path:dir $dir)
    if (not-eq $parent $dir) {
      _activate-after-ancestors $parent $edit-ns:
    }

    var cx = (_get-context &dir=$dir)
    if (has-key $cx module) {
      activate &cx=$cx $edit-ns:
    }
  }
}

fn _deactivate-descendants { |dir edit-ns:|
  while (and (> (count $_dir-stack) 0) (_is-ancestor $dir $_dir-stack[0][dir])) {
    deactivate &dir=$_dir-stack[0][dir] $edit-ns:
  }
}

# check and trigger activation if required
var _handled-cwd

fn handle-cwd { |edit-ns:|
  var pwd = (pwd)

  if (not-eq $_handled-cwd $pwd) {
    set _handled-cwd = $pwd

    # deactivation, children before parents
    while (and (> (count $_dir-stack) 0) (not (_is-ancestor $_dir-stack[0][dir] $pwd))) {
      deactivate &dir=$_dir-stack[0][dir] $edit-ns:
    }

    # activation, parents before children
    # TODO optimise this by not looking further than we need, according to what changed in cwd
    _activate-after-ancestors $pwd $edit-ns:
  }
}

# allow `dir`, defaulting to current directory
fn allow { |&dir=$nil edit-ns:|
  var cx = (_get-context &dir=$dir)
  _fail-if-missing $cx

  echo $cx[module] >$cx[allow]

  # parents must always be activated before children, for overrides, so ...
  _deactivate-descendants $cx[dir] $edit-ns:

  set _handled-cwd = $nil
}

# revoke `dir`, defaulting to current directory
fn revoke { |&dir=$nil edit-ns:|
  var cx = (_get-context &dir=$dir)
  _fail-if-missing $cx

  # allow-path not existing is harmless
  try {
    os:remove $cx[allow]
  } catch e {
    if (not-eq $e os:-is-not-exist) {
      fail $e
    }
  }

  set _handled-cwd = $nil
}
