fn hello {
  echo 'Hello activated nested world'
}

fn goodbye {
  echo 'Goodbye cruel activated nested world'
}

var export = [&hello~=$hello~ &goodbye~=$goodbye~]
