#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#define sv_is_string(sv) \
	(SvTYPE(sv) != SVt_PVGV && \
	 (SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK|SVp_IOK|SVp_NOK|SVp_POK)))

#define KEYPREFIX "Lexical::Var/"
#define KEYPREFIXLEN (sizeof(KEYPREFIX)-1)

#define LEXPACKAGE "Lexical::Var::<LEX>"
#define LEXPREFIX LEXPACKAGE"::"
#define LEXPREFIXLEN (sizeof(LEXPREFIX)-1)

#define CHAR_IDSTART 0x01
#define CHAR_IDCONT  0x02
#define CHAR_SIGIL   0x10
#define CHAR_USEPAD  0x20

static U8 char_attr[256] = {
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* NUL to BEL */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* BS to SI */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* DLE to ETB */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* CAN to US */
	0x00, 0x00, 0x00, 0x00, 0x30, 0x30, 0x10, 0x00, /* SP to ' */
	0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, /* ( to / */
	0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, /* 0 to 7 */
	0x02, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 8 to ? */
	0x30, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* @ to G */
	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* H to O */
	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* P to W */
	0x03, 0x03, 0x03, 0x00, 0x00, 0x00, 0x00, 0x03, /* X to _ */
	0x00, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* ` to g */
	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* h to o */
	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* p to w */
	0x03, 0x03, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, /* x to DEL */
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
};

static SV *name_key(char sigil, bool using_pad, SV *name)
{
	char const *p, *q, *end;
	STRLEN len;
	SV *key;
	p = SvPV(name, len);
	end = p + len;
	if(p == end) return NULL;
	if(!sigil) {
		if(!(char_attr[(U8)*p] & CHAR_SIGIL)) return NULL;
		sigil = *p++;
		if(p == end) return NULL;
	}
	if(using_pad) {
		if(memNE(p, LEXPREFIX, LEXPREFIXLEN)) return NULL;
		p += LEXPREFIXLEN;
		if(p == end) return NULL;
	}
	if(!(char_attr[(U8)*p] & CHAR_IDSTART)) return NULL;
	for(q = p+1; q != end; q++) {
		if(!(char_attr[(U8)*q] & CHAR_IDCONT)) return NULL;
	}
	key = sv_2mortal(newSV(KEYPREFIXLEN + 1 + (end-p)));
	sv_setpvs(key, KEYPREFIX"?");
	SvPVX(key)[KEYPREFIXLEN] = sigil;
	sv_catpvn(key, p, end-p);
	return key;
}

static OP *ck_rv2xv(pTHX_ OP *o, char sigil, bool using_pad,
		OP *(*nxck)(pTHX_ OP *o))
{
	OP *c;
	SV *ref, *key, *newref;
	HE *he;
	if((o->op_flags & OPf_KIDS) && (c = cUNOPx(o)->op_first) &&
			c->op_type == OP_CONST &&
			(c->op_private & (OPpCONST_ENTERED|OPpCONST_BARE)) &&
			(ref = cSVOPx(c)->op_sv) && SvPOK(ref) &&
			(key = name_key(sigil, using_pad, ref))) {
		if((he = hv_fetch_ent(GvHV(PL_hintgv), key, 0, 0))) {
			if(sigil == '&' && (c->op_private & OPpCONST_BARE))
				croak("can't reference lexical subroutine "
					"without & sigil (yet)");
			if(!using_pad) {
				/*
				 * A bogus symbol lookup has already been
				 * done (by the tokeniser) based on the name
				 * we're using, to support the package-based
				 * interpretation that we're about to
				 * replace.  This can cause bogus "used only
				 * once" warnings.  The best we can do here
				 * is to flag the symbol as multiply-used to
				 * suppress that warning, though this is at
				 * the risk of muffling an accurate warning.
				 */
				GV *gv = gv_fetchsv(ref,
					GV_NOADD_NOINIT|GV_NOEXPAND|GV_NOTQUAL,
					SVt_PVGV);
				if(gv && SvTYPE(gv) == SVt_PVGV)
					GvMULTI_on(gv);
			}
			newref = SvREFCNT_inc(HeVAL(he));
			replace_ref: {
				U16 type = o->op_type;
				op_free(o);
				return newUNOP(type, 0,
						newSVOP(OP_CONST, 0, newref));
			}
		} else if(using_pad) {
			/*
			 * Not a name that we have a defined meaning for,
			 * but it has the form of the "our" hack, implying
			 * that we did put an entry in the pad for it.
			 * Munge this back to what it would have been
			 * without the pad entry.  This should mainly
			 * happen due to explicit unimportation, but it
			 * might also happen if the scoping of the pad and
			 * %^H ever get out of synch.
			 */
			newref = newSVpvn(SvPVX(ref)+LEXPREFIXLEN,
						SvCUR(ref)-LEXPREFIXLEN);
			if(SvUTF8(ref)) SvUTF8_on(newref);
			goto replace_ref;
		}
	}
	return nxck(aTHX_ o);
}

static OP *(*nxck_rv2sv)(pTHX_ OP *o);
static OP *(*nxck_rv2av)(pTHX_ OP *o);
static OP *(*nxck_rv2hv)(pTHX_ OP *o);
static OP *(*nxck_rv2cv)(pTHX_ OP *o);
static OP *(*nxck_rv2gv)(pTHX_ OP *o);

static OP *ck_rv2sv(pTHX_ OP*o) { return ck_rv2xv(aTHX_ o,'$',1,nxck_rv2sv); }
static OP *ck_rv2av(pTHX_ OP*o) { return ck_rv2xv(aTHX_ o,'@',1,nxck_rv2av); }
static OP *ck_rv2hv(pTHX_ OP*o) { return ck_rv2xv(aTHX_ o,'%',1,nxck_rv2hv); }
static OP *ck_rv2cv(pTHX_ OP*o) { return ck_rv2xv(aTHX_ o,'&',0,nxck_rv2cv); }
static OP *ck_rv2gv(pTHX_ OP*o) { return ck_rv2xv(aTHX_ o,'*',0,nxck_rv2gv); }

static HV *stash_lex;

static void setup_pad(char const *vari_word, char const *name)
{
	CV *compcv;
	GV *compgv;
	AV *padlist, *padname, *padvar;
	PADOFFSET ouroffset;
	SV *ourname, *ourvar;
	/*
	 * Given that we're being invoked from a BEGIN block,
	 * PL_compcv here doesn't actually point to the sub
	 * being compiled.  Instead it points to the BEGIN block.
	 * The code that we want to affect is the parent of that.
	 * Along the way, better check that we are actually being
	 * invoked that way: PL_compcv may be null, indicating
	 * runtime, or it can be non-null in a couple of
	 * other situations (require, string eval).
	 */
	if(!(PL_compcv && CvSPECIAL(PL_compcv) &&
			(compgv = CvGV(PL_compcv)) &&
			strEQ(GvNAME(compgv), "BEGIN") &&
			(compcv = CvOUTSIDE(PL_compcv)) &&
			(padlist = CvPADLIST(compcv))))
		croak("can't set up lexical %s outside compilation",
			vari_word);
	padname = (AV*)*av_fetch(padlist, 0, 0);
	padvar = (AV*)*av_fetch(padlist, 1, 0);
	ourvar = *av_fetch(padvar, AvFILLp(padvar) + 1, 1);
	SvPADMY_on(ourvar);
	ouroffset = AvFILLp(padvar);
	ourname = newSV_type(SVt_PVMG);
	sv_setpv(ourname, name);
	SvPAD_OUR_on(ourname);
	SvOURSTASH_set(ourname, (HV*)SvREFCNT_inc((SV*)stash_lex));
	((XPVNV*)SvANY(ourname))->xnv_u.xpad_cop_seq.xlow = PL_cop_seqmax++;
	((XPVNV*)SvANY(ourname))->xnv_u.xpad_cop_seq.xhigh = I32_MAX;
	av_store(padname, ouroffset, ourname);
}

static SV *lookup_for_compilation(char base_sigil, char const *vari_word,
	SV *name)
{
	SV *key;
	HE *he;
	if(!sv_is_string(name)) croak("%s name is not a string", vari_word);
	key = name_key(base_sigil, 0, name);
	if(!key) croak("malformed %s name", vari_word);
	he = hv_fetch_ent(GvHV(PL_hintgv), key, 0, 0);
	return he ? SvREFCNT_inc(HeVAL(he)) : &PL_sv_undef;
}

static int svt_scalar(svtype t)
{
        switch(t) {
		case SVt_NULL: case SVt_IV: case SVt_NV: case SVt_RV:
		case SVt_PV: case SVt_PVIV: case SVt_PVNV:
		case SVt_PVMG: case SVt_PVLV: case SVt_PVGV:
			return 1;
		default:
			return 0;
	}
}

static void import(char base_sigil, char const *vari_word)
{
	dXSARGS;
	int i;
	SP -= items;
	if(items < 1)
		croak("too few arguments for import");
	if(items == 1)
		croak("%"SVf" does no default importation", SVfARG(ST(0)));
	if(!(items & 1))
		croak("import list for %"SVf
			" must alternate name and reference", SVfARG(ST(0)));
	PL_hints |= HINT_LOCALIZE_HH;
	for(i = 1; i != items; i += 2) {
		SV *name = ST(i), *ref = ST(i+1), *key;
		svtype rt;
		bool rok;
		char const *vt;
		char sigil;
		if(!sv_is_string(name))
			croak("%s name is not a string", vari_word);
		key = name_key(base_sigil, 0, name);
		if(!key) croak("malformed %s name", vari_word);
		sigil = SvPVX(key)[KEYPREFIXLEN];
		rt = SvROK(ref) ? SvTYPE(SvRV(ref)) : SVt_LAST;
		switch(sigil) {
			case '$': rok = svt_scalar(rt); vt="scalar"; break;
			case '@': rok = rt == SVt_PVAV; vt="array";  break;
			case '%': rok = rt == SVt_PVHV; vt="hash";   break;
			case '&': rok = rt == SVt_PVCV; vt="code";   break;
			case '*': rok = rt == SVt_PVGV; vt="glob";   break;
		}
		if(!rok) croak("%s is not %s reference", vari_word, vt);
		hv_store_ent(GvHV(PL_hintgv), key, newRV_inc(SvRV(ref)), 0);
		if(char_attr[sigil] & CHAR_USEPAD)
			setup_pad(vari_word, SvPVX(key)+KEYPREFIXLEN);
	}
	PUTBACK;
}

static void unimport(char base_sigil, char const *vari_word)
{
	dXSARGS;
	int i;
	SP -= items;
	if(items < 1)
		croak("too few arguments for unimport");
	if(items == 1)
		croak("%"SVf" does no default unimportation", SVfARG(ST(0)));
	PL_hints |= HINT_LOCALIZE_HH;
	for(i = 1; i != items; i++) {
		SV *name = ST(i), *ref, *key;
		char sigil;
		if(!sv_is_string(name))
			croak("%s name is not a string", vari_word);
		key = name_key(base_sigil, 0, name);
		if(!key) croak("malformed %s name", vari_word);
		sigil = SvPVX(key)[KEYPREFIXLEN];
		if(i != items && (ref = ST(i+1), SvROK(ref))) {
			HE *he;
			SV *cref;
			i++;
			he = hv_fetch_ent(GvHV(PL_hintgv), key, 0, 0);
			cref = he ? SvREFCNT_inc(HeVAL(he)) : &PL_sv_undef;
			if(SvROK(cref) && SvRV(cref) != SvRV(ref))
				continue;
		}
		hv_delete_ent(GvHV(PL_hintgv), key, G_DISCARD, 0);
		if(char_attr[sigil] & CHAR_USEPAD)
			setup_pad(vari_word, SvPVX(key)+KEYPREFIXLEN);
	}
}

MODULE = Lexical::Var PACKAGE = Lexical::Var

BOOT:
	stash_lex = gv_stashpv(LEXPACKAGE, 1);
	nxck_rv2sv = PL_check[OP_RV2SV]; PL_check[OP_RV2SV] = ck_rv2sv;
	nxck_rv2av = PL_check[OP_RV2AV]; PL_check[OP_RV2AV] = ck_rv2av;
	nxck_rv2hv = PL_check[OP_RV2HV]; PL_check[OP_RV2HV] = ck_rv2hv;
	nxck_rv2cv = PL_check[OP_RV2CV]; PL_check[OP_RV2CV] = ck_rv2cv;
	nxck_rv2gv = PL_check[OP_RV2GV]; PL_check[OP_RV2GV] = ck_rv2gv;

SV *
_variable_for_compilation(SV *class, SV *name)
CODE:
	RETVAL = lookup_for_compilation(0, "variable", name);
OUTPUT:
	RETVAL

void
import(SV *class, ...)
PPCODE:
	PUSHMARK(SP);
	/* the modified SP is intentionally lost here */
	import(0, "variable");
	SPAGAIN;

void
unimport(SV *class, ...)
PPCODE:
	PUSHMARK(SP);
	/* the modified SP is intentionally lost here */
	unimport(0, "variable");
	SPAGAIN;

MODULE = Lexical::Var PACKAGE = Lexical::Sub

SV *
_sub_for_compilation(SV *class, SV *name)
CODE:
	RETVAL = lookup_for_compilation('&', "subroutine", name);
OUTPUT:
	RETVAL

void
import(SV *class, ...)
PPCODE:
	PUSHMARK(SP);
	/* the modified SP is intentionally lost here */
	import('&', "subroutine");
	SPAGAIN;

void
unimport(SV *class, ...)
PPCODE:
	PUSHMARK(SP);
	/* the modified SP is intentionally lost here */
	unimport('&', "subroutine");
	SPAGAIN;
