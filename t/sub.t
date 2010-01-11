use warnings;
use strict;

use Test::More tests => 90;

BEGIN { $^H |= 0x20000 if $] < 5.008; }

$SIG{__WARN__} = sub {
	return if $_[0] =~ /\AAttempt to free unreferenced scalar[ :]/ &&
		$] < 5.008004;
	die "WARNING: $_[0]";
};

eval q{use Lexical::Sub foo => \undef;};
isnt $@, "";
eval q{use Lexical::Sub foo => \1;};
isnt $@, "";
eval q{use Lexical::Sub foo => \1.5;};
isnt $@, "";
eval q{use Lexical::Sub foo => \[];};
isnt $@, "";
eval q{use Lexical::Sub foo => \"abc";};
isnt $@, "";
eval q{use Lexical::Sub foo => bless(\(my$x="abc"));};
isnt $@, "";
eval q{use Lexical::Sub foo => \*main::wibble;};
isnt $@, "";
eval q{use Lexical::Sub foo => bless(\*main::wibble);};
isnt $@, "";
eval q{use Lexical::Sub foo => qr/xyz/;};
isnt $@, "";
eval q{use Lexical::Sub foo => bless(qr/xyz/);};
isnt $@, "";
eval q{use Lexical::Sub foo => [];};
isnt $@, "";
eval q{use Lexical::Sub foo => bless([]);};
isnt $@, "";
eval q{use Lexical::Sub foo => {};};
isnt $@, "";
eval q{use Lexical::Sub foo => bless({});};
isnt $@, "";
eval q{use Lexical::Sub foo => sub{};};
is $@, "";
eval q{use Lexical::Sub foo => bless(sub{});};
is $@, "";

eval q{use Lexical::Sub foo => sub{}; &foo if 0;};
is $@, "";
eval q{use Lexical::Sub foo => bless(sub{}); &foo if 0;};
is $@, "";

sub main::foo { "main" }
sub main::bar () { "main" }
sub wibble::foo { "wibble" }

our @values;

@values = ();
eval q{
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	use Lexical::Sub foo => sub { 2 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	{
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	{ ; }
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	{
		use Lexical::Sub foo => sub { 1 };
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	{
		use Lexical::Sub foo => sub { 2 };
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	{
		use Lexical::Sub foo => sub { 2 };
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	{
		use Lexical::Sub foo => sub { 2 };
		push @values, &foo;
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	package wibble;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	package wibble;
	use Lexical::Sub foo => sub { 1 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	package wibble;
	use Lexical::Sub foo => sub { 1 };
	package main;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	package wibble;
	use Lexical::Sub foo => sub { 2 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	package wibble;
	use Lexical::Sub foo => sub { 2 };
	package main;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	{
		no Lexical::Sub "foo";
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	{
		no Lexical::Sub "foo";
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	{
		no Lexical::Sub foo => \&foo;
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	{
		no Lexical::Sub foo => \&foo;
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	{
		no Lexical::Sub foo => sub { 1 };
		push @values, &foo;
	}
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	{
		no Lexical::Sub foo => sub { 1 };
	}
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	use t::code_0;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main", 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	use t::code_1;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	use t::code_2;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	use t::code_3;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	use t::code_4;
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main", 1 ];

SKIP: { skip "no lexical propagation into string eval", 10 if $] < 5.009003;

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	eval q{
		push @values, &foo;
	};
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	eval q{
		use Lexical::Sub foo => sub { 1 };
	};
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ "main" ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	eval q{
		use Lexical::Sub foo => sub { 2 };
		push @values, &foo;
	};
};
is $@, "";
is_deeply \@values, [ 2 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	eval q{
		use Lexical::Sub foo => sub { 2 };
	};
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub { 1 };
	eval q{
		use Lexical::Sub foo => sub { 2 };
		push @values, &foo;
	};
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 2, 1 ];

}

@values = ();
eval q{
	use Lexical::Sub foo => sub () { 1 };
	push @values, &foo;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub () { 1 };
	push @values, &foo();
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub ($) { 1+$_[0] };
	push @values, &foo(10);
	push @values, &foo(20);
};
is $@, "";
is_deeply \@values, [ 11, 21 ];

@values = ();
eval q{
	use Lexical::Sub foo => sub ($) { 1+$_[0] };
	my @a = (10, 20);
	push @values, &foo(@a);
};
is $@, "";
is_deeply \@values, [ 11 ];

@values = ();
eval q{
	use Lexical::Sub bar => sub () { 1 };
	push @values, &bar;
};
is $@, "";
is_deeply \@values, [ 1 ];

@values = ();
eval q{
	use Lexical::Sub bar => sub () { 1 };
	push @values, &bar();
};
is $@, "";
is_deeply \@values, [ 1 ];

1;
