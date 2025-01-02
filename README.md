# direlv

Directory activation for Elvish in the spirit of [direnv](https://direnv.net/), for native Elvish functions/variables rather than environment variables.

This does not replace `direnv`, it simply augments it with Elvish-specific support for shell-local variables.

## Why?

Why is this useful?  Isn't `direnv` enough?

If all you need is environment variables and path modifications giving access to external programs, then yes, `direnv` is enough, and is indeed wonderful.

If you also need Elvish functions to be loaded and unloaded from the REPL as you navigate your directories, then you need `direlv`.

The point of difference is that Elvish functions have a richer interface, that of value pipes, which is not available with external programs.

## Installation

Install the latest version of the package using epm.

```
> use epm
> epm:install &silent-if-installed=$true github.com/tesujimath/direlv
> epm:upgrade github.com/tesujimath/direlv
```

## Usage

For automatic directory activation and deactivation, simply install the hook like this:

```
> use github.com/tesujimath/direlv/direlv
> eval (direlv:hook | slurp)
```

These commands are suitable for inclusion in the user's global `rc.elv`.

Directories need to be approved before they can be activated, like with `direnv`.

Then, e.g.

```
> cd tests
> cd a
/home/sjg/vc/tesujimath/direlv/tests/a/dir.elv is blocked. Run `direlv:allow` to approve its content
> direlv:allow
loading: say-goodbye~ say-hello~ say-hello-a~ for /home/sjg/vc/tesujimath/direlv/tests/a/dir.elv
> say-hello
Hello activated world A

> cd nested/
/home/sjg/vc/tesujimath/direlv/tests/a/nested/dir.elv is blocked. Run `direlv:allow` to approve its content
> direlv:allow
loading: say-hello-nested~ say-goodbye~ say-hello~ for /home/sjg/vc/tesujimath/direlv/tests/a/nested/dir.elv
> say-hello
Hello activated nested world

> cd ..
reinstating: say-goodbye~ say-hello~ for /home/sjg/vc/tesujimath/direlv/tests/a
unloading: say-hello-nested~ for /home/sjg/vc/tesujimath/direlv/tests/a/nested/dir.elv
> say-hello
Hello activated world A

> cd ..
unloading: say-goodbye~ say-hello~ say-hello-a~ for /home/sjg/vc/tesujimath/direlv/tests/a/dir.elv
> say-hello
Exception: exec: "say-hello": executable file not found in $PATH
  [tty 37]:1:1-9: say-hello
```

Directories can be removed for approval using `direlv:revoke`.

Manual activation and deactivation is also possible, although this is not the main use case.

```
aya> direlv:activate &dir=tests/a
loading: say-goodbye~ say-hello~ say-hello-a~ for /home/sjg/vc/tesujimath/direlv/tests/a/dir.elv
aya> say-hello
Hello activated world A
aya> direlv:deactivate &dir=tests/a
unloading: say-goodbye~ say-hello~ say-hello-a~ for /home/sjg/vc/tesujimath/direlv/tests/a/dir.elv
aya> say-hello
Exception: exec: "say-hello": executable file not found in $PATH
  [tty 43]:1:1-9: say-hello
```
