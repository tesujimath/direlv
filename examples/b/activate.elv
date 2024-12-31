fn hello {
  echo 'Hello activated world B'
}

fn goodbye {
  echo 'Goodbye cruel activated world B'
}

var export = [&hello~=$hello~ &goodbye~=$goodbye~]
