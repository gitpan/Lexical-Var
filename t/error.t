use warnings;
use strict;

use Test::More tests => 24;

require_ok "Lexical::Var";

eval { Lexical::Var->import() };
like $@, qr/\ALexical::Var does no default importation/;
eval { Lexical::Var->unimport() };
like $@, qr/\ALexical::Var does no default unimportation/;

eval { Lexical::Var->import('foo') };
like $@, qr/\Aimport list for Lexical::Var must alternate /;

eval { Lexical::Var->import(undef, \1) };
like $@, qr/\Avariable name is not a string/;
eval { Lexical::Var->import(\1, sub{}) };
like $@, qr/\Avariable name is not a string/;
eval { Lexical::Var->import(undef, "wibble") };
like $@, qr/\Avariable name is not a string/;

eval { Lexical::Var->import('foo', \1) };
like $@, qr/\Amalformed variable name/;
eval { Lexical::Var->import('$', \1) };
like $@, qr/\Amalformed variable name/;
eval { Lexical::Var->import('$foo(bar', \1) };
like $@, qr/\Amalformed variable name/;
eval { Lexical::Var->import('$1foo', \1) };
like $@, qr/\Amalformed variable name/;
eval { Lexical::Var->import('$foo\x{e9}bar', \1) };
like $@, qr/\Amalformed variable name/;
eval { Lexical::Var->import('$foo::bar', \1) };
like $@, qr/\Amalformed variable name/;
eval { Lexical::Var->import('!foo', \1) };
like $@, qr/\Amalformed variable name/;
eval { Lexical::Var->import('foo', "wibble") };
like $@, qr/\Amalformed variable name/;

eval { Lexical::Var->import('$foo', "wibble") };
like $@, qr/\Avariable is not scalar reference/;

eval { Lexical::Var->unimport(undef, \1) };
like $@, qr/\Avariable name is not a string/;
eval { Lexical::Var->unimport(\1, sub{}) };
like $@, qr/\Avariable name is not a string/;
eval { Lexical::Var->unimport(undef, "wibble") };
like $@, qr/\Avariable name is not a string/;

eval { Lexical::Var->unimport('foo', \1) };
like $@, qr/\Amalformed variable name/;
eval { Lexical::Var->unimport('$', \1) };
like $@, qr/\Amalformed variable name/;
eval { Lexical::Var->unimport('$foo(bar', \1) };
like $@, qr/\Amalformed variable name/;
eval { Lexical::Var->unimport('$foo::bar', \1) };
like $@, qr/\Amalformed variable name/;
eval { Lexical::Var->unimport('!foo', \1) };
like $@, qr/\Amalformed variable name/;

1;
