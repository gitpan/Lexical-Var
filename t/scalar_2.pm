use strict;
use Lexical::Var '$foo' => \2;
push @main::values, $foo;
1;
