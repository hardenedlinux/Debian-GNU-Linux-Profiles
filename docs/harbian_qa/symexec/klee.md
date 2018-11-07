# Note about KLEE on debian
## Brief 
KLEE use the extern SAT/SMT solver to generate the descript of path and constrain( .smt format). Then, KLEE will handle the constrain, generate the testcase for symbol, run the testcase, track the symbolic variable's memory, confirm the relationship between path and constrain. There are also some santize is optional.

### Build
Debian 9  
LLVM 3.8.1  
libstp 2.1  
libminisat 2.1  
[KLEE build](http://klee.github.io/build-llvm38/).  
[stp build](http://klee.github.io/build-stp/).  
LLVM: [the error i met.](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=907621)  

### SMT solver generating  
In this part, we use stp solver as a SMT solver, ignore the detail, analyse how KLEE generate SMT solver. The concrete implement in /klee/lib/Solver/STPBuilder.cpp and /klee/lib/Solver/STPSolver.cpp use the stp interfaces. These interface can be found in /stp/lib/Interface/c_interface.cpp.
From klee/tools/klee/main.cpp function main, interpreter initialization can be found:

```  
int main(int argc, char **argv) {
  ...
Interpreter *interpreter =
    theInterpreter = Interpreter::create(ctx, IOpts, handler);
  ...
```
  
```  
Interpreter *Interpreter::create(LLVMContext &ctx, const InterpreterOptions &opts, InterpreterHandler *ih) {
  return new Executor(ctx, opts, ih);
}
```  

```  
Executor::Executor(LLVMContext &ctx, const InterpreterOptions &opts, InterpreterHandler *ih)
{
  ...
  /* initial */
  Solver *coreSolver = klee::createCoreSolver(CoreSolverToUse);
  if (!coreSolver)
    klee_error("Failed to create core solver\n");
    /* Write to smt file */
  Solver *solver = constructSolverChain(
      coreSolver,
      interpreterHandler->getOutputFilename(ALL_QUERIES_SMT2_FILE_NAME),
      interpreterHandler->getOutputFilename(SOLVER_QUERIES_SMT2_FILE_NAME),
      interpreterHandler->getOutputFilename(ALL_QUERIES_KQUERY_FILE_NAME),
      interpreterHandler->getOutputFilename(SOLVER_QUERIES_KQUERY_FILE_NAME));
  ...
}
```  

```  
Solver *createCoreSolver(CoreSolverType cst) {
  switch (cst) {
  case STP_SOLVER:
#ifdef ENABLE_STP
    klee_message("Using STP solver backend");
    return new STPSolver(UseForkedCoreSolver, CoreSolverOptimizeDivides);
#else
  ...
  }
}
```    

```  
STPSolver::STPSolver(bool useForkedSTP, bool optimizeDivides)
    : Solver(new STPSolverImpl(useForkedSTP, optimizeDivides)) {}
```  

vc_* is the stp interface:

```  
STPSolverImpl::STPSolverImpl(bool _useForkedSTP, bool _optimizeDivides)
    : vc(vc_createValidityChecker()),
      builder(new STPBuilder(vc, _optimizeDivides)), timeout(0.0),
      useForkedSTP(_useForkedSTP), runStatusCode(SOLVER_RUN_STATUS_FAILURE) {
  ...
  vc_setInterfaceFlags(vc, EXPRDELETE, 0);
  ...
  vc_registerErrorHandler(::stp_error_handler);
  ...
}
```  

Similarly, other handle finally use the stp interface. Run the follow command to generate the smt files, and print them out:

```  
clang-3.8 -I ../klee/include -emit-llvm -c -g test.c
../klee_build/bin/klee -debug-dump-stp-queries --use-query-log=all:smt2 -write-smt2s -write-paths test.bc --debug
```  

### Memory set and tracker  
KLEE use klee_make_symbolic to set memory as a testcase. After run the foregoing command, you can find a klee-oyt-* directory was created, you can also find several *.smt files with several *.ktest files. Use this command to decode the *.ktest:

```  
python ../klee_build/bin/ktest-tool klee-out-0/test000001.ktest
```  

Actually, a *.smt is a constrain of a code path, correspondingly a *.ktest record the value of the symbol of this path. klee_make_symbolic read the ktest file and generate the memory for symbol.

```  
void klee_make_symbolic(void *array, size_t nbytes, const char *name) {
  ...

  static int rand_init = -1;
  /* random initial */
  if (rand_init == -1) {
    if (getenv("KLEE_RANDOM")) {
      struct timeval tv;
      gettimeofday(&tv, 0);
      rand_init = 1;
      srand(tv.tv_sec ^ tv.tv_usec);
    } else {
      rand_init = 0;
    }
  }

  if (rand_init) {
    if (!strcmp(name,"syscall_a0")) {
      unsigned long long *v = array;
      assert(nbytes == 8);
      *v = rand() % 69;
    } else {
      char *c = array;
      size_t i;
      for (i=0; i<nbytes; i++)
        c[i] = rand_byte();
    }
    return;
  }

  /* Read .ktest file */
  if (!testData) {
    char tmp[256];
    char *name = getenv("KTEST_FILE");

    if (!name) {
      fprintf(stdout, "KLEE-RUNTIME: KTEST_FILE not set, please enter .ktest path: ");
      fflush(stdout);
      name = tmp;
      if (!fgets(tmp, sizeof tmp, stdin) || !strlen(tmp)) {
        fprintf(stderr, "KLEE-RUNTIME: cannot replay, no KTEST_FILE or user input\n");
        exit(1);
      }
      tmp[strlen(tmp)-1] = '\0'; /* kill newline */
    }
    /* generate testcase data */
    testData = kTest_fromFile(name);
    if (!testData) {
      fprintf(stderr, "KLEE-RUNTIME: unable to open .ktest file\n");
      exit(1);
    }
  }

  /* Fill symbol */
  for (;; ++testPosition) {
    if (testPosition >= testData->numObjects) {
      report_internal_error("out of inputs. Will use zero if continuing.");
      memset(array, 0, nbytes);
      break;
    } else {
      KTestObject *o = &testData->objects[testPosition];
      if (strcmp("model_version", o->name) == 0 &&
          strcmp("model_version", name) != 0) {
        // Skip over this KTestObject because we've hit
        // `model_version` which is from the POSIX runtime
        // and the caller didn't ask for it.
        continue;
      }
      /* Match the symbol name */
      if (strcmp(name, o->name) != 0) {
        report_internal_error(
            "object name mismatch. Requesting \"%s\" but returning \"%s\"",
            name, o->name);
      }
      /* memset the symbol value */
      memcpy(array, o->bytes, nbytes < o->numBytes ? nbytes : o->numBytes);
      /* Check the symbol size */
      if (nbytes != o->numBytes) {
        report_internal_error("object sizes differ. Expected %zu but got %u",
                              nbytes, o->numBytes);
        /* Fill with '0' if symbol size larger then read from .ktest */
        if (o->numBytes < nbytes)
          memset((char *)array + o->numBytes, 0, nbytes - o->numBytes);
      }
      ++testPosition;
      break;
    }
  }
}
```  

### Test status
Use klee-stats to print the result of all testcase.

```  
klee_build/bin/klee-stats --print-all dir ../tesr/klee-out-0
```  

The coverage will be record in *.cov for every testcase.
```  
./klee_build/bin/klee -debug-dump-stp-queries --use-query-log=all:smt2 -write-smt2s -write-cov test.bc --debug
```  

Replay a testcase.
```  
../klee_build/bin/klee-replay test klee-out-1/test000001.ktest  --debug   

```  

### Implement something like KLEE in Linux kernel

| | SAT/SMT solver | symbolic instrument | coverage | testcase running |  
|-|----------------|---------------------|----------|------------------|  
| KLEE | stp | klee_make_symbolic | bcov/icov | user space, fork |  
| Kernel | WIP | kernel hook | kcov/gcov | fixed user space test case, hijack kernel function |  

1. stp: Is it feasible that use stp as kernel SMT solver? To be verifted. But it seems that stp can hardly handle the heap behave, complex structure and pointer.
2. symbolic: klee_make_symbolic must be added to source code, kernel hook can be load dynamicly.
3. testcaes running: Userspace use fork to create testcase, consistency provide by fork. Kernel space test should be divided to two part: fixed userspace testcase and kernel hijack. Consistency provide by kernel process.

### Reference
[KLEE](https://klee.github.io/docs/)  
[KLEE tutorials](http://klee.github.io/tutorials/)  
[stp](https://github.com/stp/stp)  
[stp code guide](https://github.com/stp/stp/blob/master/docs/code-guide.rst)  
