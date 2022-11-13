
const SBI_SET_TIMER: usize = 0;
const SBI_CONSOLE_PUTCHAR: usize = 1;
const SBI_CONSOLE_GETCHAR: usize = 2;
const SBI_SHUTDOWN: usize = 8;

fn sbi_call(id: usize, arg0: usize, arg1: usize, arg2: usize) -> isize {
    let mut ret;
    unsafe{
        // 引入汇编
        core::arch::asm!(
            "ecall",
            inlateout("x10") arg0 => ret,
            in("x11") arg1,
            in("x12") arg2,
            in("x17") id,
        );
    }
    ret
}


pub fn console_putchar(c: usize) {
    sbi_call(SBI_CONSOLE_PUTCHAR, c, 0, 0);
}

pub fn console_getchar() -> usize {
    // 修改为调用内核方法
    sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0).try_into().unwrap()
}

pub fn shutdown() -> !{
    sbi_call(SBI_SHUTDOWN,0,0,0,);
    panic!("It should shutdown!");
}

