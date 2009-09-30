=head1 NAME

Lexical::Sub - subroutines without namespace pollution

=head1 SYNOPSIS

	use Lexical::Sub quux => sub { $_[0] + 1 };
	use Lexical::Sub carp => \&Carp::carp;

=head1 DESCRIPTION

This module implements lexical scoping of subroutines.  Although it can
be used directly, it is mainly intended to be infrastructure for modules
that export subroutines.

This module influences the meaning of single-part subroutine names that
appear directly in code, such as "C<&foo>".  Normally, in the absence of
any particular declaration, this would refer to the subroutine of that
name located in the current package.  A C<Lexical::Sub> declaration
can change this to refer to any particular subroutine, bypassing the
package system entirely.  A subroutine name that includes an explicit
package part, such as "C<&main::foo>", always refers to the subroutine
in the specified package, and is unaffected by this module.  A symbolic
reference through a string value, such as "C<&{'foo'}>", also looks in
the package system, and so is unaffected by this module.

Bareword references to subroutines, such as "C<foo(123)>", cannot
currently be handled by this module.  You must use the C<&> sigil, as in
"C<&foo(123)>".

A name definition supplied by this module takes effect from the end of the
definition statement up to the end of the immediately enclosing block,
except where it is shadowed within a nested block.  This is the same
lexical scoping that the C<my>, C<our>, and C<state> keywords supply.
These lexical definitions propagate into string C<eval>s, on Perl versions
that support it (5.9.3 and later).

This module is implemented through the mechanism of L<Lexical::Var>.
Its distinct name and declaration syntax exist to make lexical subroutine
declarations clearer.

=cut

package Lexical::Sub;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.001";

require Lexical::Var;
die "mismatched versions of Lexical::Var and Lexical::Sub modules"
	unless $Lexical::Var::VERSION eq $VERSION;

=head1 PACKAGE METHODS

These methods are meant to be invoked on the C<Lexical::Sub> package.

=over

=item Lexical::Sub->import(NAME => REF, ...)

Sets up lexical subroutine declarations, in the lexical environment that
is currently compiling.  Each I<NAME> must be a bare subroutine name
(e.g., "B<foo>"), and each I<REF> must be a reference to a subroutine.
The name is lexically associated with the referenced subroutine.

=item Lexical::Sub->unimport(NAME [=> REF], ...)

Sets up negative lexical subroutine declarations, in the lexical
environment that is currently compiling.  Each I<NAME> must be a bare
subroutine name (e.g., "B<foo>").  If the name is given on its own, it is
lexically dissociated from any subroutine.  Within the resulting scope,
the subroutine name will not be recognised.  If a I<REF> (which must
be a reference to a subroutine) is specified with a name, the name
will be dissociated if and only if it is currently associated with
that subroutine.

=back

=head1 BUGS

Subroutine invocations without the C<&> sigil cannot be correctly
processed by this module.  This is because the parser needs to look up
the subroutine early, in order to let any prototype affect parsing,
and it looks up the subroutine by a different mechanism than is used
to generate the call op.  (Some forms of sigilless call have other
complications of a similar nature.)  The early lookup is harder to
intercept, and fixing this will probably require changes to the Perl core.
If an attempt is made to call a lexical subroutine via a bareword, this
module will probably still be able to intercept the call op, and will
throw an exception to indicate that the parsing has gone wrong.  However,
in some cases compilation goes further wrong before this module can catch
it, resulting in either a confusing parse error or (in rare situations)
silent compilation to an incorrect op sequence.

Package hash entries get created for subroutine names that are used,
even though the subroutines are not actually being stored or looked
up in the package.  This can occasionally result in a "used only once"
warning failing to occur when it should.

=head1 SEE ALSO

L<Lexical::Var>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
