# direlv

Directory activation for Elvish in the spirit of [direnv](https://direnv.net/), for native Elvish functions/variables rather than environment variables.

This does not replace `direnv`, it simply augments it with Elvish-specific support for shell-local variables.

## Why?

Why is this useful?  Isn't `direnv` enough?

If all you need is environment variables and path modifications giving access to external programs, then yes, `direnv` is enough, and is indeed wonderful.

If you also need Elvish functions to be loaded and unloaded from the REPL as you navigate your directories, then you need `direlv`.

The point of difference is that Elvish functions have a richer interface, that of value pipes, which is not available with external programs.

# Usage

_To be completed_
