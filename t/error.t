use warnings;
use strict;

use Test::More tests => 29;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

require_ok "Lexical::Var";

eval q{ Lexical::Var->import(); };
like $@, qr/\ALexical::Var does no default importation/;
eval q{ Lexical::Var->unimport(); };
like $@, qr/\ALexical::Var does no default unimportation/;
eval q{ Lexical::Var->import('foo'); };
like $@, qr/\Aimport list for Lexical::Var must alternate /;
eval q{ Lexical::Var->import('$foo', \1); };
like $@, qr/\Acan't set up lexical variable outside compilation/;
eval q{ Lexical::Var->unimport('$foo'); };
like $@, qr/\Acan't set up lexical variable outside compilation/;

eval q{ use Lexical::Var; };
like $@, qr/\ALexical::Var does no default importation/;
eval q{ no Lexical::Var; };
like $@, qr/\ALexical::Var does no default unimportation/;

eval q{ use Lexical::Var 'foo'; };
like $@, qr/\Aimport list for Lexical::Var must alternate /;

eval q{ use Lexical::Var undef, \1; };
like $@, qr/\Avariable name is not a string/;
eval q{ use Lexical::Var \1, sub{}; };
like $@, qr/\Avariable name is not a string/;
eval q{ use Lexical::Var undef, "wibble"; };
like $@, qr/\Avariable name is not a string/;

eval q{ use Lexical::Var 'foo', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ use Lexical::Var '$', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ use Lexical::Var '$foo(bar', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ use Lexical::Var '$1foo', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ use Lexical::Var '$foo\x{e9}bar', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ use Lexical::Var '$foo::bar', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ use Lexical::Var '!foo', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ use Lexical::Var 'foo', "wibble"; };
like $@, qr/\Amalformed variable name/;

eval q{ use Lexical::Var '$foo', "wibble"; };
like $@, qr/\Avariable is not scalar reference/;

eval q{ no Lexical::Var undef, \1; };
like $@, qr/\Avariable name is not a string/;
eval q{ no Lexical::Var \1, sub{}; };
like $@, qr/\Avariable name is not a string/;
eval q{ no Lexical::Var undef, "wibble"; };
like $@, qr/\Avariable name is not a string/;

eval q{ no Lexical::Var 'foo', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ no Lexical::Var '$', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ no Lexical::Var '$foo(bar', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ no Lexical::Var '$foo::bar', \1; };
like $@, qr/\Amalformed variable name/;
eval q{ no Lexical::Var '!foo', \1; };
like $@, qr/\Amalformed variable name/;

1;
