// func StartTSC() (uint64, uint32)
TEXT ·StartTSC(SB), $0-16
    // 1. Serialize the pipeline
    XORL AX, AX
    CPUID
    // 2. Read the counter
    RDTSC
    // 3. Pack DX:AX into RAX
    SHLQ $32, DX
    ORQ  DX, AX
    MOVQ AX, ret+0(FP)

    MOVL $1, AX  // Set EAX = 1
    CPUID        // This call specifically asks for the Processor ID
    SHRL $24, BX  // Shift right to get just the ID byte
    MOVL BX, cpu+8(FP)   // Second return (uint32 cpuID)

    RET

// func StopTSC() (uint64, uint32)
TEXT ·StopTSC(SB), $0-16
    // 1. Read counter and serialize previous instructions
    RDTSCP
    // 2. Pack DX:AX into RAX
    SHLQ $32, DX
    ORQ  DX, AX
    MOVQ AX, ret+0(FP)
    // 3. Final serialization (optional, prevents later code leaking up)
    XORL AX, AX
    MOVL CX, cpu+8(FP)
    // CPUID
    RET
    