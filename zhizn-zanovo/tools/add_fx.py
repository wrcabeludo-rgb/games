# Добавить токены в fx выбора: python3 tools/add_fx.py (вызывается как модуль из скрипта)
import re
def block(s, eid):
    m = re.search(r"\n\s*\{\s*\n\s*id: '" + re.escape(eid) + "'", s)
    if not m: raise SystemExit('нет события ' + eid)
    i = s.index('{', m.start() + 1); depth = 0; q = None; j = i
    while True:
        ch = s[j]
        if q:
            if ch == '\\': j += 2; continue
            if ch == q: q = None
        elif ch in "'\"": q = ch
        elif ch == '{': depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0: break
        j += 1
    return i, j + 1
def add(path, eid, start, tokens, allow_many=False):
    s = open(path, encoding='utf8').read()
    a, b = block(s, eid); seg = s[a:b]; n = 0
    def esc(x): return re.escape(x)
    # { t: 'start...', fx: '...'
    pat1 = re.compile(r"(\{ t: '" + esc(start) + r"[^']*'(?:, if: [^}]*?\})?, fx: ')([^']*)(')")
    pat1b = re.compile(r"(\{ t: '" + esc(start) + r"[^']*')(, (?:res|run|if):)")
    pat2 = re.compile(r"(C\('" + esc(start) + r"[^']*', ')([^']*)(')")
    def r1(m):
        nonlocal n; n += 1; return m.group(1) + (m.group(2) + ' ' + tokens).strip() + m.group(3)
    seg2 = pat1.sub(r1, seg)
    if n == 0:
        seg2 = pat2.sub(r1, seg)
    if n == 0:
        def r2(m):
            nonlocal n; n += 1; return m.group(1) + ", fx: '" + tokens + "'" + m.group(2)
        seg2 = pat1b.sub(r2, seg)
    if n == 0: raise SystemExit('не нашёл выбор «%s» в %s' % (start, eid))
    if n > 1 and not allow_many: print('  несколько совпадений', eid, start, n)
    s = s[:a] + seg2 + s[b:]
    open(path, 'w', encoding='utf8').write(s)
