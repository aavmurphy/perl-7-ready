# Perl 7 Ready

Make your script, packages and .cgi's Perl 7 ready !

## no feature qw( indirect )

`new fred( $a )` becomes `fred->new( $a )`

Gotchas:
* look out for the word new in inlined HTML
* need v5.32 for this pragma, the `package->new()` works, just not the pragma, so its commented out by default

## use signatures

`sub fred { my ( $self, $a ) = @_;` becomes `sub fred( $self, $a ) {`

This is an excellent new feature. Should have started using it ages ago.

Gotchas
* look out for `sub new()`, it should be `sub new( $class )`
* look out for optional args, it should be e.g. `sub fred ( $needed, $optional="" )`
* if you do something like `sub fred { $self = shift; my ($x) = @_` my regex wont work -you'll have to hack the code

#  use open qw(:std :utf8);

This broke everything for me, I suspect cos everything was double (de)coded. More thought needed!

So this pragma is commented out by default

Gotchas:
* use open is universal, its a per (all files/packages) thing, have it in 1 package, then its everywhere.

# use strict; use warnings;

Hopefully not contraversial. This script just makes sure they are there

# preamble

This is an extra, a standard set of comments at the start of each file, e.g. (c) you, your website, your email

# some extras

Fix line endings - comment this out of the code if you don't want it 

# See

Also see perltidy
