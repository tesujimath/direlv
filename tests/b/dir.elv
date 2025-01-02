fn say-hello {
  echo 'Hello activated world B'
}

fn say-hello-b {
  echo 'Hello uniquely activated world B'
}

fn say-goodbye {
  echo 'Goodbye cruel activated world B'
}

var export = [&say-hello~=$say-hello~ &say-hello-b~=$say-hello-b~ &say-goodbye~=$say-goodbye~]
