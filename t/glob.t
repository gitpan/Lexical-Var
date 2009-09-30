use warnings;
use strict;

use Test::More tests => 34;

BEGIN { $^H |= 0x20000 if $] < 5.008; }

$SIG{__WARN__} = sub {
	return if $_[0] =~ /\AAttempt to free unreferenced scalar[ :]/ &&
		$] < 5.008004;
	die "WARNING: $_[0]";
};

eval q{use Lexical::Var '*foo' => \undef;};
isnt $@, "";
eval q{use Lexical::Var '*foo' => \1;};
isnt $@, "";
eval q{use Lexical::Var '*foo' => \1.5;};
isnt $@, "";
eval q{use Lexical::Var '*foo' => \[];};
isnt $@, "";
eval q{use Lexical::Var '*foo' => \"abc";};
isnt $@, "";
eval q{use Lexical::Var '*foo' => bless(\(my$x="abc"));};
isnt $@, "";
eval q{use Lexical::Var '*foo' => \*main::wibble;};
is $@, "";
eval q{use Lexical::Var '*foo' => bless(\*main::wibble);};
is $@, "";
eval q{use Lexical::Var '*foo' => [];};
isnt $@, "";
eval q{use Lexical::Var '*foo' => bless([]);};
isnt $@, "";
eval q{use Lexical::Var '*foo' => {};};
isnt $@, "";
eval q{use Lexical::Var '*foo' => bless({});};
isnt $@, "";
eval q{use Lexical::Var '*foo' => sub{};};
isnt $@, "";
eval q{use Lexical::Var '*foo' => bless(sub{});};
isnt $@, "";

eval q{use Lexical::Var '*foo' => \*main::wibble; *foo if 0;};
is $@, "";
eval q{use Lexical::Var '*foo' => bless(\*main::wibble); *foo if 0;};
is $@, "";

$main::one = 1;
$main::one = 1;
$main::two = 2;
$main::two = 2;

our @values;

@values = ();
eval q{
	push @values, ${*foo{SCALAR}};
};
is $@, "";
is_deeply \@values, [ undef ];

@values = ();
eval q{
	use Lexical::Var '*foo' => \*one;
	push @values, ${*foo{SCALAR}};
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '*foo' => \*one;
	use Lexical::Var '*foo' => \*two;
	push @values, ${*foo{SCALAR}};
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Var '*foo' => \*one;
	{
		push @values, ${*foo{SCALAR}};
	}
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '*foo' => \*one;
	{ ; }
	push @values, ${*foo{SCALAR}};
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	{
		use Lexical::Var '*foo' => \*one;
	}
	push @values, ${*foo{SCALAR}};
};
is $@, "";
is_deeply \@values, [ undef ];

@values = ();
eval q{
	use Lexical::Var '*foo' => \*one;
	{
		use Lexical::Var '*foo' => \*two;
		push @values, ${*foo{SCALAR}};
	}
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Var '*foo' => \*one;
	{
		use Lexical::Var '*foo' => \*two;
	}
	push @values, ${*foo{SCALAR}};
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Var '*foo' => \*one;
	{
		use Lexical::Var '*foo' => \*two;
		push @values, ${*foo{SCALAR}};
	}
	push @values, ${*foo{SCALAR}};
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

1;
