#!/usr/bin/env python3
"""Split the translator's one-module stub runtime (f90/runtime/stub/cpp_runtime_stub.f90, made by
`dotnet tools/cs2x/bin/cs2f90.dll cs f90/gen f90/runtime/stub/cpp_runtime_stub.f90`) into the four part modules
the real runtime has, cpp_rt_a, cpp_rt_c, cpp_rt_b, cpp_rt_d (that order: each may use only the earlier ones in
its specification part), using f90/runtime_parts.txt, and write the module cpp_runtime that re-exports them.

  split_stub.py OUTDIR [PARTS...]     e.g. split_stub.py f90/runtime/stub        (all four stub modules)

A part's author compiles against the other parts' stub modules (types complete as the engine sees them, bodies
empty) until the real ones exist; the real module of a part keeps the same name, type names and components (it may
add components and procedures). Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md."""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
ORDER = ['a', 'c', 'b', 'd']
BASE = {'cpp_object', 'cpp_slot', 'cpp_u8', 'cpp_u16', 'cpp_u32', 'cpp_u64'}   # the conventions' types: part A


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    part = {}
    for l in open(os.path.join(ROOT, 'runtime_parts.txt')):
        if l.startswith('#') or not l.strip(): continue
        n, p = l.split('\t')[:2]
        part[n.lower()] = p.lower()
    lines = open(os.path.join(ROOT, 'runtime', 'stub', 'cpp_runtime_stub.f90')).read().split('\n')
    ci = next(i for i, l in enumerate(lines) if l == 'contains')
    spec, body = lines[:ci], lines[ci + 1:]
    # spec: type blocks, the abstract interface blocks (split per interface body), variables
    types = {p: [] for p in ORDER}; ifaces = {p: [] for p in ORDER}; vars_ = {p: [] for p in ORDER}
    i = 0
    while i < len(spec):
        l = spec[i]; s = l.strip()
        m = re.match(r'type\s*(?:,[^:]*)?::\s*(\w+)', s)
        if m:
            j = i
            while not re.match(r'end type', spec[j].strip()): j += 1
            n = m.group(1).lower()
            types['a' if n in BASE else part.get(n, 'a')].extend(spec[i:j + 1]); i = j + 1; continue
        if s == 'abstract interface':
            j = i + 1
            while spec[j].strip() != 'end interface':
                k = j
                while not re.match(r'end (function|subroutine)', spec[k].strip()): k += 1
                hm = re.search(r'(?:function|subroutine)\s+(\w+)', spec[j])
                n = hm.group(1).lower()
                owner = 'a' if n == 'cpp_maker' else part.get(n[2:] if n.startswith('i_') else n, 'a')
                ifaces[owner].extend(spec[j:k + 1]); j = k + 1
            i = j + 1; continue
        m = re.match(r'(class|type|integer|real|logical|character)\b.*::\s*(\w+)', s)
        if m and not s.startswith('implicit'):
            n = m.group(2).lower(); vars_['a' if n == 'cpp_exc' else part.get(n, 'a')].append(l)
        i += 1
    procs = {p: [] for p in ORDER}
    i = 0
    while i < len(body):
        m = re.match(r'\s*(?:recursive\s+|pure\s+|elemental\s+)*(function|subroutine)\s+(\w+)', body[i])
        if m:
            j = i
            while not re.match(r'\s*end (function|subroutine)', body[j]): j += 1
            n = m.group(2).lower()
            procs['a' if n.startswith('cpp_object_') else part.get(n, 'a')].extend(body[i:j + 1]); i = j + 1; continue
        i += 1
    want = sys.argv[2:] or ORDER
    for k, p in enumerate(ORDER):
        if p not in want: continue
        uses = ['  use cpp_rt_' + q for q in ORDER[:k]]
        txt = ['! cpp_rt_%s - STUB of part %s of the Fortran runtime (types as the engine sees them, empty bodies), made by'
               % (p, p.upper()), '! f90/tools/split_stub.py from the translator\'s stub. Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.',
               'module cpp_rt_' + p] + uses + ['  implicit none'] + types[p] + vars_[p]
        if ifaces[p]: txt += ['  abstract interface'] + ifaces[p] + ['  end interface']
        txt += ['contains'] + procs[p] + ['end module cpp_rt_' + p, '']
        open(os.path.join(out, 'cpp_rt_%s.f90' % p), 'w').write('\n'.join(txt))
        print('cpp_rt_%s: %d type lines, %d procedure lines' % (p, len(types[p]), len(procs[p])))
    open(os.path.join(out, 'cpp_runtime.f90'), 'w').write(
        '! cpp_runtime - the module the engine uses: the four parts of the runtime, re-exported.\n'
        '! Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.\nmodule cpp_runtime\n'
        + ''.join('  use cpp_rt_%s\n' % p for p in ORDER) + '  implicit none\nend module cpp_runtime\n')


main()
