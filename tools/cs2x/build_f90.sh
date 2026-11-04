#!/bin/bash
# Build the C#-to-Fortran translator (bin/cs2f90.dll) against the Roslyn assemblies that ship with the .NET SDK.
#   dotnet bin/cs2f90.dll ../../cs ../../f90/gen [stub_runtime.f90]
# Written by Claude (Anthropic) for the SWMM6 ports; see AI-USE.md.
set -e
cd "$(dirname "$0")"
FW=$(ls -d /usr/lib/dotnet/shared/Microsoft.NETCore.App/8.* | head -1)
RB=$(ls -d /usr/lib/dotnet/sdk/*/Roslyn/bincore | head -1)
REFS=$(for f in $FW/*.dll; do case $(basename $f) in Microsoft.VisualBasic*|mscorlib.dll|netstandard.dll|System.Private.*) ;; *) echo -n "-r:$f ";; esac; done)
mkdir -p bin
dotnet $RB/csc.dll -nologo -optimize+ -nullable:enable -nowarn:CS8600,CS8602,CS8603,CS8604,CS8618,CS8625 -langversion:latest -out:bin/cs2f90.dll $REFS -r:$FW/netstandard.dll -r:$FW/System.Private.CoreLib.dll \
  -r:$RB/Microsoft.CodeAnalysis.dll -r:$RB/Microsoft.CodeAnalysis.CSharp.dll Cs2F90.cs F90Types.cs F90Rt.cs F90Fn.cs F90Expr.cs F90Ops.cs F90Gen.cs
# the Roslyn assemblies are shared with the other translators in bin/: replace them only when they differ (a
# rewrite in place kills a translator running from bin/ with SIGBUS)
for f in Microsoft.CodeAnalysis.dll Microsoft.CodeAnalysis.CSharp.dll; do cmp -s $RB/$f bin/$f || cp $RB/$f bin/$f; done
printf '{"runtimeOptions":{"tfm":"net8.0","framework":{"name":"Microsoft.NETCore.App","version":"%s"}}}' $(basename $FW) > bin/cs2f90.runtimeconfig.json
