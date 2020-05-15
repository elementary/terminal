[CCode (cprefix = "pcre2_", cheader_filename = "pcre2.h")]
namespace PCRE2 {
    [Flags]
    [CCode (cname = "unsigned int", cprefix = "PCRE2_")]
    public enum Flags {
        ALLOW_EMPTY_CLASS,
        ALT_BSUX,
        AUTO_CALLOUT,
        CASELESS,
        DOLLAR_ENDONLY,
        DOTALL,
        DUPNAMES,
        EXTENDED,
        FIRSTLINE,
        MATCH_UNSET_BACKREF,
        MULTILINE,
        NEVER_UCP,
        NEVER_UTF,
        NO_AUTO_CAPTURE,
        NO_AUTO_POSSESS,
        NO_DOTSTAR_ANCHOR,
        NO_START_OPTIMIZE,
        UCP,
        UNGREEDY,
        UTF,
        NEVER_BACKSLASH_C,
        ALT_CIRCUMFLEX,
        ALT_VERBNAMES,
        USE_OFFSET_LIMIT,
        EXTENDED_MORE,
        LITERAL,
        MATCH_INVALID_UTF
    }
}
