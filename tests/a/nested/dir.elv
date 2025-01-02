fn say-hello {
  echo 'Hello activated nested world'
}

fn say-hello-nested {
  echo 'Hello uniquely activated nested world'
}

fn say-goodbye {
  echo 'Goodbye cruel activated nested world'
}

var export = [&say-hello~=$say-hello~ &say-hello-nested~=$say-hello-nested~ &say-goodbye~=$say-goodbye~]
