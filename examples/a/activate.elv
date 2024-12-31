fn hello {
  echo 'Hello activated world A'
}

fn hello-a {
  echo 'Hello uniquely activated world A'
}

fn hello2 {
  echo 'Hello again activated world A'
  private-hello
}

fn goodbye {
  echo 'Goodbye cruel activated world A'
}

fn private-hello {
  echo 'Hello from a private function'
}

var export = [&hello~=$hello~ &hello-a~=$hello-a~ &hello2~=$hello2~ &goodbye~=$goodbye~]
