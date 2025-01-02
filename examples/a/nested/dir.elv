fn hello {
  echo 'Hello activated nested world'
}

fn hello-nested {
  echo 'Hello uniquely activated nested world'
}

fn goodbye {
  echo 'Goodbye cruel activated nested world'
}

var export = [&hello~=$hello~ &hello-nested~=$hello-nested~ &goodbye~=$goodbye~]
