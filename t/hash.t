use warnings;
use strict;

use Test::More tests => 48;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub {
	return if $_[0] =~ /\AVariable \"\%foo\" is not imported /;
	return if $_[0] =~ /\AAttempt to free unreferenced scalar[ :]/ &&
		"$]" < 5.008004;
	die "WARNING: $_[0]";
};

eval q{use Lexical::Var '%foo' => \undef;};
isnt $@, "";
eval q{use Lexical::Var '%foo' => \1;};
isnt $@, "";
eval q{use Lexical::Var '%foo' => \1.5;};
isnt $@, "";
eval q{use Lexical::Var '%foo' => \[];};
isnt $@, "";
eval q{use Lexical::Var '%foo' => \"abc";};
isnt $@, "";
eval q{use Lexical::Var '%foo' => bless(\(my$x="abc"));};
isnt $@, "";
eval q{use Lexical::Var '%foo' => \*main::wibble;};
isnt $@, "";
eval q{use Lexical::Var '%foo' => bless(\*main::wibble);};
isnt $@, "";
eval q{use Lexical::Var '%foo' => qr/xyz/;};
isnt $@, "";
eval q{use Lexical::Var '%foo' => bless(qr/xyz/);};
isnt $@, "";
eval q{use Lexical::Var '%foo' => [];};
isnt $@, "";
eval q{use Lexical::Var '%foo' => bless([]);};
isnt $@, "";
eval q{use Lexical::Var '%foo' => {};};
is $@, "";
eval q{use Lexical::Var '%foo' => bless({});};
is $@, "";
eval q{use Lexical::Var '%foo' => sub{};};
isnt $@, "";
eval q{use Lexical::Var '%foo' => bless(sub{});};
isnt $@, "";

eval q{use Lexical::Var '%foo' => {}; %foo if 0;};
is $@, "";
eval q{use Lexical::Var '%foo' => bless({}); %foo if 0;};
is $@, "";

%main::foo = (a=>undef);
%main::foo = (a=>undef);

our @values;

@values = ();
eval q{
	use strict;
	push @values, %foo;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	no strict;
	push @values, %foo;
};
is $@, "";
is_deeply \@values, [ a=>undef ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '%foo' => {a=>1};
	push @values, %foo;
};
is $@, "";
is_deeply \@values, [ a=>1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '%foo' => {a=>1};
	use Lexical::Var '%foo' => {a=>2};
	push @values, %foo;
};
is $@, "";
is_deeply \@values, [ a=>2 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '%foo' => {a=>1};
	{
		push @values, %foo;
	}
};
is $@, "";
is_deeply \@values, [ a=>1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '%foo' => {a=>1};
	{ ; }
	push @values, %foo;
};
is $@, "";
is_deeply \@values, [ a=>1 ];

@values = ();
eval q{
	use strict;
	{
		use Lexical::Var '%foo' => {a=>1};
	}
	push @values, %foo;
};
isnt $@, "";
is_deeply \@values, [];

@values = ();
eval q{
	no strict;
	{
		use Lexical::Var '%foo' => {a=>1};
	}
	push @values, %foo;
};
is $@, "";
is_deeply \@values, [ a=>undef ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '%foo' => {a=>1};
	{
		use Lexical::Var '%foo' => {a=>2};
		push @values, %foo;
	}
};
is $@, "";
is_deeply \@values, [ a=>2 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '%foo' => {a=>1};
	{
		use Lexical::Var '%foo' => {a=>2};
	}
	push @values, %foo;
};
is $@, "";
is_deeply \@values, [ a=>1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '%foo' => {a=>1};
	{
		use Lexical::Var '%foo' => {a=>2};
		push @values, %foo;
	}
	push @values, %foo;
};
is $@, "";
is_deeply \@values, [ a=>2, a=>1 ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '%foo' => { qw(a A b B c C) };
	push @values, $foo{b};
};
is $@, "";
is_deeply \@values, [ "B" ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '%foo' => { qw(a A b B c C) };
	my $i = "b";
	push @values, $foo{$i};
};
is $@, "";
is_deeply \@values, [ "B" ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '%foo' => { qw(a A b B c C) };
	push @values, @foo{qw(b c a)};
};
is $@, "";
is_deeply \@values, [ qw(B C A) ];

@values = ();
eval q{
	use strict;
	use Lexical::Var '%foo' => { qw(a A b B c C) };
	my @i = qw(b c a);
	push @values, @foo{@i};
};
is $@, "";
is_deeply \@values, [ qw(B C A) ];

1;
