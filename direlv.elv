use os
use path
use str

# preserved state for restoring on deactivation

# indexed by hash of activation
var exports = [&]

# list of slash-terminated directories in reverse activation order (children before parents)
var activation-stack = []

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

fn get-context { |&dir=$nil|
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

fn fail-if-no-module { |cx|
  if (not (has-key $cx module)) {
    fail 'direlv: error '(path:base $cx[module-base])' not found in '$cx[dir]
  }
}

# is `cx` allowed, defaulting to current directory
fn is-allowed { |cx|
  put (os:exists $cx[allow])
}

fn activate { |&dir=$nil &cx=$nil|
  if (eq $cx $nil) {
    set cx = (get-context &dir=$dir)
  }
  fail-if-no-module $cx

  if (not (is-allowed $cx)) {
    echo >&2 $cx[module]' is blocked. Run `direlv:allow` to approve its content'
  } elif (has-key $exports $cx[hash]) {
    echo >&2 $cx[module]' is already activated'
  } else {
    set activation-stack = (conj [$cx[dir]] $@activation-stack)

    eval &on-end={ |ns|
      var exported-names = (keys $ns[export] | put [(all)])
      echo >&2 'loading: '(str:join ' ' $exported-names)' for '$cx[module]
      edit:add-vars $ns[export]
      set exports = (assoc $exports $cx[hash] $exported-names)
    } (slurp <$cx[module])
  }
}

# deactivate and (TODO) restore the most recently overwritten variables
fn deactivate { |&dir=$nil|
  var cx = (get-context &dir=$dir)
  fail-if-no-module $cx

  if (not (has-key $exports $cx[hash])) {
    fail $cx[module]' is not activated'
  }

  if (not-eq $activation-stack[0] $cx[dir]) {
    fail $cx[module]' is not top of the activation stack'
  }

  set activation-stack = $activation-stack[1..]

  var exported-names = $exports[$cx[hash]]
  echo >&2 'unloading: '(str:join ' ' $exported-names)' for '$cx[module]
  edit:del-vars $exported-names
  set exports = (dissoc $exports $cx[hash])
}

fn is-ancestor { |ancestor descendant|
  str:has-prefix (str:trim-suffix $descendant '/')'/' (str:trim-suffix $ancestor '/')'/'
}

fn activate-after-ancestors { |dir|
  if (or (== (count $activation-stack) 0) (not-eq $activation-stack[0] $dir)) {
    var parent = (path:dir $dir)
    if (not-eq $parent $dir) {
      activate-after-ancestors $parent
    }

    var cx = (get-context &dir=$dir)
    if (has-key $cx module) {
      activate &cx=$cx
    }
  }
}

fn _deactivate-descendants { |dir|
  while (and (> (count $activation-stack) 0) (is-ancestor $dir $activation-stack[0])) {
    deactivate &dir=$activation-stack[0]
  }
}

# check and trigger activation if required
var handled-cwd

fn handle-cwd {
  var pwd = (pwd)

  if (not-eq $handled-cwd $pwd) {
    set handled-cwd = $pwd

    # deactivation, children before parents
    while (and (> (count $activation-stack) 0) (not (is-ancestor $activation-stack[0] $pwd))) {
      deactivate &dir=$activation-stack[0]
    }

    # activation, parents before children
    # TODO optimise this by not looking further than we need, according to what changed in cwd
    activate-after-ancestors $pwd
  }
}

# allow `dir`, defaulting to current directory
fn allow { |&dir=$nil|
  var cx = (get-context &dir=$dir)
  fail-if-no-module $cx

  echo $cx[module] >$cx[allow]

  # parents must always be activated before children, for overrides, so ...
  _deactivate-descendants $cx[dir]

  set handled-cwd = $nil
}

# revoke `dir`, defaulting to current directory
fn revoke { |&dir=$nil|
  var cx = (get-context &dir=$dir)
  fail-if-no-module $cx

  # allow-path not existing is harmless
  try {
    os:remove $cx[allow]
  } catch e {
    if (not-eq $e os:-is-not-exist) {
      fail $e
    }
  }
}

