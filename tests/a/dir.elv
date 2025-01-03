fn say-hello {
  echo 'Hello activated world A'
}

fn say-hello-a {
  echo 'Hello uniquely activated world A'
}

# this currently doesn't work because the namespace is not available in the REPL:
# fn say-hello2 {
#   echo 'Hello again activated world A'
#   say-private-hello
# }

fn say-goodbye {
  echo 'Goodbye cruel activated world A'
}

fn say-private-hello {
  echo 'Hello from a private function'
}

var export = [
  &say-hello~=$say-hello~
  &say-hello-a~=$say-hello-a~
  # &say-hello2~=$say-hello2~
  &say-goodbye~=$say-goodbye~
]
