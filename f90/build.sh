#!/bin/bash
# build.sh - build the Fortran SWMM6 engine and its command line, f90/build/swmm6 (all build products in f90/build).
#   1. the runtime: for each part p in the order a, c, b, d (each module may use only the parts before it),
#      f90/runtime/cpp_rt_<p>.f90 when that part's real module exists, otherwise f90/runtime/stub/cpp_rt_<p>.f90;
#      then the real parts' submodules f90/runtime/cpp_rt_<p>_*.f90 (a submodule may use any part), then
#      f90/runtime/cpp_runtime.f90 (the re-export module the engine uses). A part's file may hold more than one
#      module (part B's cpp_rt_b.f90 holds cpp_rt_b0 and cpp_rt_b: one object, two .mod files); every part
#      object and every submodule object is linked;
#   2. the engine module f90/gen/swmm6_engine.f90, then its 62 submodules (two at a time);
#   3. the runner f90/runtime/swmm6_main.F90 (the port of cs/runtime/Program.cs), and the link.
# Flags (tools/cs2x/F90.md): -O2 -fwrapv -ffp-contract=off -fno-fast-math -frecursive -ffree-line-length-none
# -fimplicit-none -fno-range-check, nothing else touching floating point. Everything runs under nice -n 10.
#   -fwrapv            C#'s int arithmetic wraps on overflow
#   -ffp-contract=off  no fused multiply-add: every product is rounded, as in the C++/C# builds
#   -fno-fast-math     IEEE semantics (the default; stated for the record)
#   -frecursive        every procedure may be re-entered (runtime -> engine -> runtime through bindings)
# Options: JOBS=n (default 2, at most 2), FFLAGS=... (replaces the flags), OPT=-O1 (replaces -O2 only),
#   ONLY=runtime|engine (stop after that stage), TIMES=1 (per-file wall time and peak memory in build/times.txt),
#   BUILD_DIR=dir (instead of f90/build; tests/stdcheck/run_stream_f90.sh builds the runtime alone that way),
#   GEN=dir (the engine's sources from dir instead of f90/gen, e.g. a patched copy for a diagnosis),
#   RESUME=1 (skip a file whose object is newer than its source, e.g. to finish an interrupted build; it does not look
#   at module dependencies, so use it only when the runtime's interfaces have not changed since those objects).
# While part C is still the stub, the build's copy of stub C gets the ErrorCode component v (C#'s ErrorCode.v),
# which part D's file-system functions set; nothing else is changed.
# Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
set -e
cd "$(dirname "$0")"
F90=$(pwd)
B=${BUILD_DIR:-$F90/build}
mkdir -p "$B"
B=$(cd "$B" && pwd)
JOBS=${JOBS:-2}; [ "$JOBS" -gt 2 ] && JOBS=2
OPT=${OPT:--O2}
FFLAGS=${FFLAGS:-"$OPT -fwrapv -ffp-contract=off -fno-fast-math -frecursive -ffree-line-length-none -fimplicit-none -fno-range-check"}
FC="nice -n 10 gfortran"
[ "${RESUME:-0}" = 1 ] || : > "$B/times.txt"
# the machine has no /usr/bin/time: wall time and peak resident memory (getrusage of the children, the figure
# /usr/bin/time -v reports as "Maximum resident set size") through Python
cat > "$B/rss.py" <<'EOT'
import resource, subprocess, sys, time
t = time.time(); r = subprocess.call(sys.argv[3:])
with open(sys.argv[1], 'a') as f:
    f.write('%8.1f s %9d KB  %s\n' % (time.time() - t, resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss, sys.argv[2]))
sys.exit(r)
EOT
TIMEV="python3 -I $B/rss.py $B/times.txt"

# cc SRC OBJ [extra flags]: compile one file (mod/smod files in build/), timing it when TIMES=1
cc() {
	local src=$1 obj=$2; shift 2
	if [ "${RESUME:-0}" = 1 ] && [ -f "$obj" ] && [ "$obj" -nt "$src" ]; then return 0; fi
	# the object is written under a temporary name and renamed when the compile succeeds, so an interrupted build
	# never leaves a partial object that RESUME=1 would keep
	if [ "${TIMES:-0}" = 1 ]; then
		$TIMEV "$(basename "$src")" $FC $FFLAGS "$@" -J"$B" -I"$B" -c "$src" -o "$obj.part" || return 1
	else
		$FC $FFLAGS "$@" -J"$B" -I"$B" -c "$src" -o "$obj.part" || return 1
	fi
	mv -f "$obj.part" "$obj"
}

t0=$(date +%s)
# ---------------------------------------------------------------------------------------------- 1. runtime
OBJS=()
SUBS=()
for p in a c b d; do
	if [ -f runtime/cpp_rt_$p.f90 ]; then
		src=runtime/cpp_rt_$p.f90
		for s in runtime/cpp_rt_${p}_*.f90; do [ -f "$s" ] && SUBS+=("$s"); done
		echo "part $p: real ($src$(ls runtime/cpp_rt_${p}_*.f90 2>/dev/null | sed 's/^/ + /' | tr -d '\n'))"
	else
		src=runtime/stub/cpp_rt_$p.f90
		if [ $p = c ]; then
			# the stub's ErrorCode has no components; part D sets ErrorCode.v
			sed 's/^\(  type, extends(cpp_object) :: cpp_errorcode\)$/\1\n    integer(4) :: v = 0/' "$src" > "$B/stub_cpp_rt_c.f90"
			src=$B/stub_cpp_rt_c.f90
		fi
		echo "part $p: stub"
	fi
	cc "$src" "$B/cpp_rt_$p.o"
	OBJS+=("$B/cpp_rt_$p.o")
done
for s in "${SUBS[@]}"; do
	o=$B/$(basename "${s%.f90}").o
	cc "$s" "$o"
	OBJS+=("$o")
done
cc runtime/cpp_runtime.f90 "$B/cpp_runtime.o"
OBJS+=("$B/cpp_runtime.o")
t1=$(date +%s)
echo "runtime: $((t1 - t0)) s"
[ "${ONLY:-}" = runtime ] && exit 0

# ---------------------------------------------------------------------------------------------- 2. engine
GEN=${GEN:-gen}
cc "$GEN/swmm6_engine.f90" "$B/swmm6_engine.o"
OBJS+=("$B/swmm6_engine.o")
t2=$(date +%s)
echo "engine module: $((t2 - t1)) s"
export -f cc
export FC FFLAGS B TIMEV TIMES RESUME
ls "$GEN"/swmm6_engine_[0-9]*.f90 | xargs -P "$JOBS" -I{} bash -c 'f={}; o=$B/$(basename ${f%.f90}).o; cc "$f" "$o" || { echo "FAILED $f"; exit 255; }'
for f in "$GEN"/swmm6_engine_[0-9]*.f90; do OBJS+=("$B/$(basename "${f%.f90}").o"); done
t3=$(date +%s)
echo "engine submodules: $((t3 - t2)) s"
[ "${ONLY:-}" = engine ] && exit 0

# ---------------------------------------------------------------------------------------------- 3. runner, link
HAVE=()
# part C's FlushAll (what returning from main does to the open C files); without it the runner flushes stdout/stderr
grep -qi 'cpp_r_flushall' runtime/cpp_rt_c*.f90 2>/dev/null && HAVE+=(-DHAVE_FLUSHALL)
cc runtime/swmm6_main.F90 "$B/swmm6_main.o" -cpp "${HAVE[@]}"
# memory: the C# engine relies on .NET's garbage collector and the translation never frees, so every allocation goes
# to the system's Boehm collector (libgc1, f90/gc/gc_wrap.c; libgfortran static so its mallocs are wrapped too).
# Collection frees only unreachable memory; without it the long models run out of memory (lessons/15). NOGC=1 links
# without it.
if [ "${NOGC:-0}" = 1 ]; then
  nice -n 10 gfortran $FFLAGS -o "$B/swmm6" "$B/swmm6_main.o" "${OBJS[@]}" -lm
else
  LIBGC=${LIBGC:-$(ls /usr/lib/x86_64-linux-gnu/libgc.so /lib/x86_64-linux-gnu/libgc.so.1 2>/dev/null | head -1)}
  [ -n "$LIBGC" ] || { echo "build.sh: libgc (the Boehm collector, Ubuntu package libgc1) not found; NOGC=1 builds without it" >&2; exit 1; }
  nice -n 10 gcc -O2 -c gc/gc_wrap.c -o "$B/gc_wrap.o"
  nice -n 10 gfortran $FFLAGS -static-libgfortran -o "$B/swmm6" "$B/swmm6_main.o" "${OBJS[@]}" "$B/gc_wrap.o" "$LIBGC" -lm \
    -Wl,--wrap=malloc,--wrap=calloc,--wrap=realloc,--wrap=free
fi
t4=$(date +%s)
echo "runner + link: $((t4 - t3)) s"
echo "built $B/swmm6 in $((t4 - t0)) s"
