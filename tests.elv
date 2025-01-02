#!/usr/bin/env elvish

use path

use github.com/tesujimath/elvish-tap/tap
var assert-expected~ = $tap:assert-expected~

use ./_direlv

# this is where we accumulate the variable bindings
var state = [&]

fn add-vars { |x|
  keys $x | each { |k|
    set state[$k] = $x[$k]
  }
}

fn del-vars { |v|
  for k $v {
    del state[$k]
  }
}

var edit-ns: = (ns [&add-vars~=$add-vars~ &del-vars~=$del-vars~])


var testdir = (path:join (pwd) 'tests')

# run all the functions we have accumumlated in state and collect their output
fn run-state-fns {
  var results = [&]
  keys $state | each { |f|
    var result = ($state[$f])
    set results[$f] = $result
  }
  put $results
}

var tests = [
  [&d=a &f={
    cd (path:join $testdir 'a')
    _direlv:handle-cwd $edit-ns:

    assert-expected (run-state-fns) [
      &say-hello~='Hello activated world A'
      &say-hello-a~='Hello uniquely activated world A'
      &say-goodbye~='Goodbye cruel activated world A'
    ]
  }]

  [&d=nested &f={
    cd (path:join $testdir 'a' 'nested')
    _direlv:handle-cwd $edit-ns:

    assert-expected (run-state-fns) [
      &say-hello-a~='Hello uniquely activated world A'
      &say-hello~='Hello activated nested world'
      &say-hello-nested~='Hello uniquely activated nested world'
      &say-goodbye~='Goodbye cruel activated nested world'
    ]
  }]

  [&d=a2 &f={
    cd (path:join $testdir 'a')
    _direlv:handle-cwd $edit-ns:

    assert-expected (run-state-fns) [
      &say-hello~='Hello activated world A'
      &say-hello-a~='Hello uniquely activated world A'
      &say-goodbye~='Goodbye cruel activated world A'
    ]
  }]

  [&d=b&f={
    cd (path:join $testdir 'b')
    _direlv:handle-cwd $edit-ns:

    assert-expected (run-state-fns) [
      &say-hello~='Hello activated world B'
      &say-hello-b~='Hello uniquely activated world B'
      &say-goodbye~='Goodbye cruel activated world B'
    ]
  }]

  [&d=nested2 &f={
    cd (path:join $testdir 'a' 'nested')
    _direlv:handle-cwd $edit-ns:

    assert-expected (run-state-fns) [
      &say-hello-a~='Hello uniquely activated world A'
      &say-hello~='Hello activated nested world'
      &say-hello-nested~='Hello uniquely activated nested world'
      &say-goodbye~='Goodbye cruel activated nested world'
    ]
  }]
]

tap:run $tests | tap:status
