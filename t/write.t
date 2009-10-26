use warnings;
use strict;

use Test::More tests => 11;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

use Lexical::Var '$foo' => \(my $x=1);
is $foo, 1;
is ++$foo, 2;
is $foo, 2;

use Lexical::Var '@foo' => [];
is_deeply \@foo, [];
push @foo, qw(x y);
is_deeply \@foo, [qw(x y)];
push @foo, qw(a b);
is_deeply \@foo, [qw(x y a b)];
$foo[2] = "A";
is_deeply \@foo, [qw(x y A b)];

use Lexical::Var '%foo' => {};
is_deeply \%foo, {};
$foo{x} = "a";
is_deeply \%foo, {x=>"a"};
$foo{y} = "b";
is_deeply \%foo, {x=>"a",y=>"b"};
$foo{x} = "A";
is_deeply \%foo, {x=>"A",y=>"b"};

1;
