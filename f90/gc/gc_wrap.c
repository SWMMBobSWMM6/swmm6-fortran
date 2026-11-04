/* gc_wrap.c - the Fortran engine's memory, collected by the system's Boehm-Demers-Weiser collector (libgc1).
 *
 * The C# engine relies on .NET's garbage collector; the Fortran translation allocates the same objects and never
 * frees them (the translator cannot know when a reference is the last one), so a long model exhausts memory. Linked
 * with -Wl,--wrap=malloc,--wrap=calloc,--wrap=realloc,--wrap=free (and libgfortran static, so its allocations are
 * wrapped too), every ALLOCATE of the engine and the runtime goes to GC_malloc, and memory nothing points to any more
 * is reclaimed. Collection frees only unreachable memory, so it cannot change what the engine computes.
 * A pointer from libc's own malloc (realpath, getline, ...) is passed to the real free.
 * Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md. */
#include <stddef.h>
#include <string.h>

void *GC_malloc(size_t);
void *GC_realloc(void *, size_t);
void GC_free(void *);
void *GC_base(void *);
void GC_init(void);

void *__real_malloc(size_t);
void *__real_realloc(void *, size_t);
void __real_free(void *);

void *__wrap_malloc(size_t n) { return GC_malloc(n ? n : 1); }
void *__wrap_calloc(size_t a, size_t b) { return GC_malloc(a * b ? a * b : 1); }   /* GC_malloc zeroes */
void *__wrap_realloc(void *p, size_t n)
{
    if (p != NULL && GC_base(p) == NULL) return __real_realloc(p, n);
    return GC_realloc(p, n ? n : 1);
}
void __wrap_free(void *p)
{
    if (p == NULL) return;
    if (GC_base(p) == NULL) { __real_free(p); return; }
    GC_free(p);
}
/* called first thing by the runner (bind(C) name gc_start) */
void gc_start(void) { GC_init(); }
