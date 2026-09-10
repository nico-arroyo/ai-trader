---
description: Trace an error to root cause and apply the minimal fix
argument-hint: <error message or description>
---

Error: $ARGUMENTS

1. Search the codebase for the relevant code and reproduce the failure path.
2. Trace execution to the root cause — grep every caller of the function you
   suspect; the fix usually belongs in the shared function, not each caller.
3. Apply the smallest change that fixes the cause. No unrelated refactoring or
   style changes.
4. Add or update one runnable check that fails without the fix.
5. Report: root cause in one line, the diff, the check.
