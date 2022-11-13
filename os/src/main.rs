#![no_std]
#![no_main]
mod lang_items;
mod sbi;

#[macro_use]
mod console;
// fn main() {
    // println!("Hello, world!");
// }

core::arch::global_asm!(include_str!("link_app.S"));

const SYSCALL_EXIT: usize = 94;
const SYSCALL_WRITE: usize = 64;

fn syscall(id: usize, args: [usize; 3]) -> isize {
    let mut ret;
    unsafe{
        // 引入汇编
        core::arch::asm!(
            "ecall",
            inlateout("x10") args[0] => ret,
            in("x11") args[1],
            in("x12") args[2],
            in("x17") id,
        );
    }
    ret
}

pub fn sys_exit(xstate: i32) -> isize {
    // 引入系统调用
    syscall(SYSCALL_EXIT, [xstate as usize, 0, 0])
}

pub fn sys_write(fd: usize, buffer: &[u8]) -> isize {
    // 引入系统调用
    syscall(SYSCALL_WRITE,[fd, buffer.as_ptr() as usize, buffer.len()])
}



fn clear_bss(){
    extern "C"{
        fn sbss();
        fn ebss();
    }
    (sbss as usize..ebss as usize).for_each(|a|{
        unsafe{
            (a as *mut u8).write_volatile(0)
        }
    });
}

core::arch::global_asm!(include_str!("entry.asm"));

// #[no_mangle]
// extern "C" fn _start(){
//     print!("hello");
//     println!(" world!");
//     sbi::shutdown();
// }


#[no_mangle]
pub fn rust_main() {
    print!("Hello, world!");
    println!("Hello, world!");
    clear_bss();
    sbi::shutdown();
}
