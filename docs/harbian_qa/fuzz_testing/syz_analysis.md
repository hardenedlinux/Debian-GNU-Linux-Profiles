## Syzkaller fuzzer
This documentation will introduce some implement about syzkaller:
1. Show you how fuzzer sent data to executor and how executor execute a syscall. 
2. The sequence of syscalls generation.
3. About corpus.
4. About KCOV.

### Send progData to executor 
This section is about syz-fuzzer.
Syz-manager will run the command in VM by ssh:
```  
 /syz-fuzzer -executor=/syz-executor -name=vm-0 -arch=amd64 -manager=10.0.2.10:33185 -procs=1 -leak=false -cover=true -sandbox=none -debug=true -v=100
```  
In the fuzzer side, syz-fuzzer will run executors and send data to it by using pipe.
In syz-fusser/fuzzer.go function main, we can see:
```  
/* flagProcs is from -procs */
for pid := 0; pid < *flagProcs; pid++ {
	/* initiate Proc struct */
	proc, err := newProc(fuzzer, pid)
	if err != nil {
		Fatalf("failed to create proc: %v", err)
	}
	fuzzer.procs = append(fuzzer.procs, proc)
	go proc.loop()
}
```  
The loop() is in syz-fuzzer/proc.go. 'Generate' and 'Mutate' will determine syscall sequence of userspace process. 'proc.execute' send data to executor to run syscalls. 
```  
func (proc *Proc) loop() {
	ct := proc.fuzzer.choiceTable
	/* The corpus reflash every times */
	corpus := proc.fuzzer.corpusSnapshot()
	if len(corpus) == 0 || i%100 == 0 {
		// Generate a new prog.
		p := proc.fuzzer.target.Generate(proc.rnd, programLength, ct)
		Logf(1, "#%v: generated", proc.pid)
		proc.execute(proc.execOpts, p, ProgNormal, StatGenerate)
	} else {
		// Mutate an existing prog.
		p := corpus[proc.rnd.Intn(len(corpus))].Clone()
		p.Mutate(proc.rnd, programLength, ct, corpus)
		Logf(1, "#%v: mutated", proc.pid)
		proc.execute(proc.execOpts, p, ProgNormal, StatFuzz)
	}
}
```  
The process will be executed as following:
proc.execute -> executeRaw -> env.Exec -> env.cmd.exec
'env.Exec' setup the environment and make the commandline of executor. 'env.cmd.exec' will send progDate to executor continuously.
```  
func (env *Env) Exec(opts *ExecOpts, p *prog.Prog) (output []byte, info []CallInfo, failed, hanged bool, err0 error) {
	......

	/* progData will be sent to executor */
	var progData []byte
	if env.config.Flags&FlagUseShmem == 0 {
		progData = env.in[:progSize]
	}
	......

	atomic.AddUint64(&env.StatExecs, 1)
	/* Redirect the stdio and run syz-executor */
	if env.cmd == nil {
		atomic.AddUint64(&env.StatRestarts, 1)
		env.cmd, err0 = makeCommand(env.pid, env.bin, env.config, env.inFile, env.outFile)
		......
	}
	/* Send progData, executor will run syscalls  */
	var restart bool
	output, failed, hanged, restart, err0 = env.cmd.exec(opts, progData)
	if err0 != nil || restart {
		env.cmd.close()
		env.cmd = nil
		return
	}
	/* Read kernel coverage */
	if env.out != nil {
		info, err0 = env.readOutCoverage(p)
	}
	return
}
```  
'makeCommand': first, setup executor stdio to os.Pipe. Then, run executor by using osutil.Command:
```  
func makeCommand(pid int, bin []string, config *Config, inFile *os.File, outFile *os.File) (*command, error) {
        .....
	// executor->ipc command pipe.
	inrp, inwp, err := os.Pipe()
	if err != nil {
		return nil, fmt.Errorf("failed to create pipe: %v", err)
	}
	defer inwp.Close()
	c.inrp = inrp

	// ipc->executor command pipe.
	outrp, outwp, err := os.Pipe()
	if err != nil {
		return nil, fmt.Errorf("failed to create pipe: %v", err)
	}
	defer outrp.Close()
	c.outwp = outwp

	c.readDone = make(chan []byte, 1)
	c.exited = make(chan struct{})

	/* make command, similar to os/exec.Command */
	cmd := osutil.Command(bin[0], bin[1:]...)
	if inFile != nil && outFile != nil {
		cmd.ExtraFiles = []*os.File{inFile, outFile}
	}
	cmd.Env = []string{}
	cmd.Dir = dir
	/* redirect to pipe */
	cmd.Stdin = outrp
	cmd.Stdout = inwp
	......
	/* run syz-executor */
	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("failed to start executor binary: %v", err)
	}
	c.cmd = cmd
	wp.Close()
	inwp.Close()

	if c.config.Flags&FlagUseForkServer != 0 {
		/* Handshake to check the right using of pipe */
		if err := c.handshake(); err != nil {
			return nil, err
		}
	}
	tmp := c
	c = nil // disable defer above
	return tmp, nil
}
```  
Send progData continuously, executor run the syscalls continuously. 
```  
func (c *command) exec(opts *ExecOpts, progData []byte) (output []byte, failed, hanged,
	restart bool, err0 error) {
	req := &executeReq{
		......
		progSize:  uint64(len(progData)),
	}
	reqData := (*[unsafe.Sizeof(*req)]byte)(unsafe.Pointer(req))[:]
	if _, err := c.outwp.Write(reqData); err != nil {
		output = <-c.readDone
		err0 = fmt.Errorf("executor %v: failed to write control pipe: %v", c.pid, err)
		return
	}
	/* send progData by using pipe */
	if progData != nil {
		if _, err := c.outwp.Write(progData); err != nil {
			output = <-c.readDone
			err0 = fmt.Errorf("executor %v: failed to write control pipe: %v", c.pid, err)
			return
		}
	}
	// At this point program is executing.
	......	
```  
### Recive data from fuzzer 
On the executor side, it just read the input from fuzzer and run the syscalls. 
'executor' is run by fuzzer. First, it remap its input/output. 'do_sandbox_*' fork child process to get data and run syscalls.
In executor_linux.cc:
```  
int main(int argc, char** argv)
{
	if (argc == 2 && strcmp(argv[1], "version") == 0) {
		puts(GOOS " " GOARCH " " SYZ_REVISION " " GIT_REVISION);
		return 0;
	}
	/* remap input/output, kInFd/kOutFd will be close */
	prctl(PR_SET_PDEATHSIG, SIGKILL, 0, 0, 0);
	if (mmap(&input_data[0], kMaxInput, PROT_READ, MAP_PRIVATE | MAP_FIXED, kInFd, 0) != &input_data[0])
		fail("mmap of input file failed");
	// The output region is the only thing in executor process for which consistency matters.
	// If it is corrupted ipc package will fail to parse its contents and panic.
	// But fuzzer constantly invents new ways of how to currupt the region,
	// so we map the region at a (hopefully) hard to guess address surrounded by unmapped pages.
	output_data = (uint32*)mmap(kOutputDataAddr, kMaxOutput,
				    PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FIXED, kOutFd, 0);
	if (output_data != kOutputDataAddr)
		fail("mmap of output file failed");
	if (mmap((void*)SYZ_DATA_OFFSET, SYZ_NUM_PAGES * SYZ_PAGE_SIZE, PROT_READ | PROT_WRITE,
		 MAP_ANON | MAP_PRIVATE | MAP_FIXED, -1, 0) != (void*)SYZ_DATA_OFFSET)
		fail("mmap of data segment failed");
	// Prevent random programs to mess with these fds.
	// Due to races in collider mode, a program can e.g. ftruncate one of these fds,
	// which will cause fuzzer to crash.
	// That's also the reason why we close kInPipeFd/kOutPipeFd below.
	close(kInFd);
	close(kOutFd);
	/* dup stdio to kInPipeFd/kOutPipeFd( In executor.h) */
	setup_control_pipes();
	/* Handshake send from makeCommand */
	receive_handshake();

	cover_open();
	install_segv_handler();
	use_temporary_dir();

	/* fork and run syscalls */
	int pid = -1;
	switch (flag_sandbox) {
	case sandbox_none:
		pid = do_sandbox_none();
		break;
	case sandbox_setuid:
		pid = do_sandbox_setuid();
		break;
	case sandbox_namespace:
		pid = do_sandbox_namespace();
		break;
	default:
		fail("unknown sandbox type");
	}
	if (pid < 0)
		fail("clone failed");
	debug("spawned loop pid %d\n", pid);
	int status = 0;
	while (waitpid(-1, &status, __WALL) != pid) {
	}
	status = WEXITSTATUS(status);
	// Other statuses happen when fuzzer processes manages to kill loop.
	......
}
```  
We use the do_sandbox_none as a example, fork and run a loop to recive data:
```  
#if defined(SYZ_EXECUTOR) || defined(SYZ_SANDBOX_NONE)
static int do_sandbox_none(void)
{
	......
	}
	int pid = fork();
	if (pid < 0)
		fail("sandbox fork failed");
	if (pid)
		return pid;

#if defined(SYZ_EXECUTOR) || defined(SYZ_ENABLE_CGROUPS)
	setup_cgroups();
	setup_binfmt_misc();
#endif
	/* Common source limit */
	sandbox_common();
	if (unshare(CLONE_NEWNET)) {
		debug("unshare(CLONE_NEWNET): %d\n", errno);
	}
#if defined(SYZ_EXECUTOR) || defined(SYZ_TUN_ENABLE)
	initialize_tun();
	initialize_netdevices();
#endif

	loop();
	doexit(1);
}
```  
Here is the loop:
```  
static void loop()
{
#if defined(SYZ_EXECUTOR)
	// Tell parent that we are ready to serve.
	reply_handshake();
#endif
#if defined(SYZ_EXECUTOR) || defined(SYZ_RESET_NET_NAMESPACE)
	checkpoint_net_namespace();
#endif
	......
	int iter;
	for (iter = 0;; iter++) {
		......
#if defined(SYZ_EXECUTOR)
		receive_execute(false);
#endif
		int pid = fork();
		......
		if (pid == 0) {
			prctl(PR_SET_PDEATHSIG, SIGKILL, 0, 0, 0);
			setpgrp();
#if defined(SYZ_EXECUTOR)
			close(kInPipeFd);
			close(kOutPipeFd);
#endif

			output_pos = output_data;
			/*  execute_one executes program stored in input_data */
			execute_one();
			debug("worker exiting\n");
			doexit(0);
		}
		debug("spawned worker pid %d\n", pid);

		......
		for (;;) {
			int res = waitpid(-1, &status, __WALL | WNOHANG);
			if (res == pid) {
				debug("waitpid(%d)=%d\n", pid, res);
				break;
			}
			usleep(1000);
			debug("waitpid(%d)=%d\n", pid, res);
			debug("killing\n");
			kill(-pid, SIGKILL);
			kill(pid, SIGKILL);
			while (waitpid(-1, &status, __WALL) != pid) {
			}
			break;
		}
		......
	}
}
```  
The syscall will be called as following:
execute_one -> schedule_call -> thread_create -> thread_start -> worker_thread -> execute_call -> execute_syscall -> syscall

### Generation && Mutation   
'Generate' and 'Mutate' determine the sequence of syscalls in userspace. 'Generate' generates a random, new program. 'Mutate' will mutate from it. Mutate may insert/remove a syscall, change the call args or splice from the other corpus. The choice of behavior base on the probability.
```  
// Generate generates a random program of length ~ncalls.
// calls is a set of allowed syscalls, if nil all syscalls are used.
func (target *Target) Generate(rs rand.Source, ncalls int, ct *ChoiceTable) *Prog {
	p := &Prog{
		Target: target,
	}
	r := newRand(target, rs)
	s := newState(target, ct)
	/* Generate a userspace program with random sequence n*calls  */
	for len(p.Calls) < ncalls {
		calls := r.generateCall(s, p)
		for _, c := range calls {
			/* analyze args, resource */
			s.analyze(c)
			p.Calls = append(p.Calls, c)
		}
	......
	}
	return p
}
```  
RegisterTarget will initiate the target.Syscalls.
buildCallList will enable the Syscall refer to configure from syz-manager. 
BuildChoiceTable add information about prios. Prios in syzkaller is a two-dimensional array. Represent from syscall a to syscall b.
```  
func (r *randGen) generateCall(s *state, p *Prog) []*Call {
	idx := 0
	if s.ct == nil {
		/* All syscalls */
		idx = r.Intn(len(r.target.Syscalls))
	} else {
		/* Choose syscall will random id */
		call := -1
		if len(p.Calls) != 0 {
			call = p.Calls[r.Intn(len(p.Calls))].Meta.ID
		}
		/* Choose call refer to proi */
		idx = s.ct.Choose(r.Rand, call)
	}
	meta := r.target.Syscalls[idx]
	/* Generate args, add to calls */
	return r.generateParticularCall(s, meta)
}
```  
Here we can see several kinds of mutate in the switch, 'case' determin the probability of mutate mode choice. Probability of oneOf(n) is 1/n.  Probability of nOutOf(n, m) is n/m. The method used is similar to generate a call.
```  
func (p *Prog) Mutate(rs rand.Source, ncalls int, ct *ChoiceTable, corpus []*Prog) {
	r := newRand(p.Target, rs)

	retry := false
outer:
	for stop := false; !stop || retry; stop = r.oneOf(3) {
		retry = false
		switch {
		case r.oneOf(5):
			// Not all calls have anything squashable,
			// so this has lower priority in reality.
			complexPtrs := p.complexPtrs()
			if len(complexPtrs) == 0 {
				retry = true
				continue
			}
			ptr := complexPtrs[r.Intn(len(complexPtrs))]
			if !p.Target.isAnyPtr(ptr.Type()) {
				p.Target.squashPtr(ptr, true)
			}
			var blobs []*DataArg
			var bases []*PointerArg
			ForeachSubArg(ptr, func(arg Arg, ctx *ArgCtx) {
				if data, ok := arg.(*DataArg); ok && arg.Type().Dir() != DirOut {
					blobs = append(blobs, data)
					bases = append(bases, ctx.Base)
				}
			})
			if len(blobs) == 0 {
				retry = true
				continue
			}
			// TODO(dvyukov): we probably want special mutation for ANY.
			// E.g. merging adjacent ANYBLOBs (we don't create them,
			// but they can appear in future); or replacing ANYRES
			// with a blob (and merging it with adjacent blobs).
			idx := r.Intn(len(blobs))
			arg := blobs[idx]
			base := bases[idx]
			baseSize := base.Res.Size()
			arg.data = mutateData(r, arg.Data(), 0, maxBlobLen)
			// Update base pointer if size has increased.
			if baseSize < base.Res.Size() {
				s := analyze(ct, p, p.Calls[0])
				newArg := r.allocAddr(s, base.Type(), base.Res.Size(), base.Res)
				*base = *newArg
			}
		case r.nOutOf(1, 100):
			// Splice with another prog from corpus.
			if len(corpus) == 0 || len(p.Calls) == 0 {
				retry = true
				continue
			}
			p0 := corpus[r.Intn(len(corpus))]
			p0c := p0.Clone()
			idx := r.Intn(len(p.Calls))
			p.Calls = append(p.Calls[:idx], append(p0c.Calls, p.Calls[idx:]...)...)
			for i := len(p.Calls) - 1; i >= ncalls; i-- {
				p.removeCall(i)
			}
		case r.nOutOf(20, 31):
			// Insert a new call.
			if len(p.Calls) >= ncalls {
				retry = true
				continue
			}
			idx := r.biasedRand(len(p.Calls)+1, 5)
			var c *Call
			if idx < len(p.Calls) {
				c = p.Calls[idx]
			}
			s := analyze(ct, p, c)
			calls := r.generateCall(s, p)
			p.insertBefore(c, calls)
		case r.nOutOf(10, 11):
			// Change args of a call.
			if len(p.Calls) == 0 {
				retry = true
				continue
			}
			c := p.Calls[r.Intn(len(p.Calls))]
			if len(c.Args) == 0 {
				retry = true
				continue
			}
			s := analyze(ct, p, c)
			updateSizes := true
			retryArg := false
			for stop := false; !stop || retryArg; stop = r.oneOf(3) {
				retryArg = false
				ma := &mutationArgs{target: p.Target}
				ForeachArg(c, ma.collectArg)
				if len(ma.args) == 0 {
					retry = true
					continue outer
				}
				idx := r.Intn(len(ma.args))
				arg, ctx := ma.args[idx], ma.ctxes[idx]
				calls, ok := p.Target.mutateArg(r, s, arg, ctx, &updateSizes)
				if !ok {
					retryArg = true
					continue
				}
				p.insertBefore(c, calls)
				if updateSizes {
					p.Target.assignSizesCall(c)
				}
				p.Target.SanitizeCall(c)
			}
		default:
			// Remove a random call.
			if len(p.Calls) == 0 {
				retry = true
				continue
			}
			idx := r.Intn(len(p.Calls))
			p.removeCall(idx)
		}
	}

	for _, c := range p.Calls {
		/* Some syscalls may need specially modify */
		p.Target.SanitizeCall(c)
	}
	......
}
```  
### KCOV  
The syzkaller use the KCOV for collecting the kernel coverage triggered by fuzzer. Some information about KCOV：
1. gcc insert the calls to get information of kernel. [This is some information about trace_pc/trace_cmp](https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html). Note that KCOV doesn't show all the code triggered by userspace process. For example, a base-block may be recorded as a line coverage.
2. Implement of handle function which is called to get information at runtime. Implement the proc interface, fops/mmap/ioctl... Kernel implement local in 'kernel/kcov.c'.
4. Using of the proc/ interface in every userspace prog. Enable KCOV by ioctl and read information from mmap region. The syzkaller's implement is in 'executor/executor_linux.cc'.
