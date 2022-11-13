mod context;

use crate::batch::run_next_app;
use crate::syscall::syscall;
use riscv::register::{
    mtvec::TrapMode,
    scause::{self, Exception, Trap},
    stval, stvec,
};

// 在 os/src/trap/trap.S 中实现 Trap 上下文保存/恢复的汇编代码
core::arch::global_asm!(include_str!("trap.S"));

pub fn init() {
    extern "C" {
        // 引入了一个外部符号 __alltraps。
        fn __alltraps();
    }
    unsafe {
        // 引入了一个外部符号 __alltraps ，并将 stvec 设置为 Direct 模式指向它的地址。
        stvec::write(__alltraps as usize, TrapMode::Direct);
    }
}

// Trap 分发及处理
#[no_mangle]
// 声明返回值为 &mut TrapContext 并在第 25 行实际将传入的 cx 原样返回
pub fn trap_handler(cx: &mut TrapContext) -> &mut TrapContext {
    let scause = scause::read();
    let stval = stval::read();
    // 根据 scause 寄存器所保存的 Trap 的原因进行分发处理
    match scause.cause() {
        Trap::Exception(Exception::UserEnvCall) => {
            // 触发 Trap 的原因是来自 U 特权级的 Environment Call，也就是系统调用
            // 首先修改保存在内核栈上的 Trap 上下文里面 sepc，让其增加 4
            cx.sepc += 4;
            // 从 Trap 上下文取出作为 syscall ID 的 a7 和系统调用的三个参数 a0~a2 传给 syscall 函数并获取返回值
            cx.x[10] = syscall(cx.x[17], [cx.x[10], cx.x[11], cx.x[12]]) as usize;
        }
        Trap::Exception(Exception::StoreFault) | Trap::Exception(Exception::StorePageFault) => {
            error!("[kernel] PageFault in application, core dumped.");
            run_next_app();
        }
        Trap::Exception(Exception::IllegalInstruction) => {
            error!("[kernel] IllegalInstruction in application, core dumped.");
            run_next_app();
        }
        _ => {
            panic!(
                "Unsupported trap {:?}, stval = {:#x}!",
                scause.cause(),
                stval
            );
        }
    }
    cx
}

pub use context::TrapContext;
