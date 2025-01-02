fn hello {
  echo 'Hello activated world B'
}

fn hello-b {
  echo 'Hello uniquely activated world B'
}

fn goodbye {
  echo 'Goodbye cruel activated world B'
}

var export = [&hello~=$hello~ &hello-b~=$hello-b~ &goodbye~=$goodbye~]
