.altmacro
.macro SAVE_GP n
    sd x\n, \n*8(sp)
.endm
.macro LOAD_GP n
    ld x\n, \n*8(sp)
.endm
# RISC-V 中读写 CSR 的指令是一类能不会被打断地完成多个读写操作的指令。
# 这种不会被打断地完成多个操作的指令被称为 原子指令
    .section .text
    .globl __alltraps
    .globl __restore
    .align 2 # 将 __alltraps 地址4字节对齐
__alltraps:
    # 首先通过 __alltraps 将 Trap 上下文保存在内核栈上，
    # 这里交换 sscratch 和 sp 的效果
    # 交换前 sp 指向用户栈,sscratch 指向内核栈
    csrrw sp, sscratch, sp # 原型是:csrrw rd,csr,rs.将 CSR 当前的值读到通用寄存器  中，然后将 通用寄存器  的值写入该 CSR。
    # 交换后 sp 指向内核栈  sscratch 指向用户栈
    # allocate a TrapContext on kernel stack
    # 预分配 34*8 字节的栈帧
    # 这里改动的是 sp ，说明确实是在内核栈上。
    addi sp, sp, -34*8
    # 保存 Trap 上下文的通用寄存器 x0~x31，跳过 x0 和 tp(x4)
    sd x1, 1*8(sp)
    # skip sp(x2), we will save it later
    sd x3, 3*8(sp)
    # skip tp(x4), application does not use it
    # save x5~x31
    .set n, 5
    .rept 27
        SAVE_GP %n
        .set n, n+1
    .endr
    #  CSR sstatus 和 sepc 的值分别读到寄存器 t0 和 t1 中然后保存到内核栈对应的位置上
    csrr t0, sstatus
    csrr t1, sepc
    sd t0, 32*8(sp)
    sd t1, 33*8(sp)
    # 专门处理 sp 的问题。首先将 sscratch 的值读到寄存器 t2 并保存到内核栈上
    csrr t2, sscratch
    sd t2, 2*8(sp)
    # set input argument of trap_handler(cx: &mut TrapContext)
    # 让寄存器 a0 指向内核栈的栈指针也就是我们刚刚保存的 Trap 上下文的地址
    mv a0, sp
    # 跳转到使用 Rust 编写的 trap_handler 函数 完成 Trap 分发及处理
    call trap_handler

__restore:
    # 当 trap_handler 返回之后，使用 __restore 从保存在内核栈上的 Trap 上下文恢复寄存器
    # case1: start running app by __restore
    # case2: back to U after handling trap
    mv sp, a0
    # now sp->kernel stack(after allocated), sscratch->user stack
    # restore sstatus/sepc
    # 负责从内核栈顶的 Trap 上下文恢复通用寄存器和 CSR 
    # 注意我们要先恢复 CSR 再恢复通用寄存器，这样我们使用的三个临时寄存器 才能被正确恢复
    ld t0, 32*8(sp)
    ld t1, 33*8(sp)
    ld t2, 2*8(sp)
    csrw sstatus, t0
    csrw sepc, t1
    csrw sscratch, t2
    # restore general-purpuse registers except sp/tp
    ld x1, 1*8(sp)
    ld x3, 3*8(sp)
    .set n, 5
    .rept 27
        LOAD_GP %n
        .set n, n+1
    .endr
    # 之前，sp 指向保存了 Trap 上下文之后的内核栈栈顶， sscratch 指向用户栈栈顶
    # release TrapContext on kernel stack
    addi sp, sp, 34*8
    # now sp->kernel stack, sscratch->user stack
    csrrw sp, sscratch, sp
    sret
