declare function dupstr(s as const zstring ptr) as zstring ptr
declare function splitstr(Text As String, Delim As String = ",", Ret() As String) as long
declare function strreplace(byref text as string, byref a as string, byref b as string) as string
declare function loadstrings(fromFile as string, toArray() as string) as integer
declare function latinToUtf16le(src as const zstring ptr) as wstring ptr
declare function utf8ToUtf16le(src as const zstring ptr) as wstring ptr
declare function ttfLen(src as const zstring ptr) as double
declare function ttfSubstr(src as const zstring ptr, byref start as single, maxWidth as single) as string