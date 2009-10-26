use warnings;
use strict;

use Test::More tests => 4;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

is eval q{
	use Lexical::Var '$foo' => \(my $x=123);
	$foo;
}, 123;

is eval q{
	use Lexical::Var '$foo' => \123;
	$foo;
}, 123;

our $t3 = 0;
eval q{
	use Lexical::Var '$foo' => \123;
	$t3 = 1;
	$foo = 456;
};
like $@, qr/\ACan't modify constant item /;
is $t3, 0;

1;
