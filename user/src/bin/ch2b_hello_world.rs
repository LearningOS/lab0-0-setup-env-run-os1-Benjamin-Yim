#![no_std]
#![no_main]

// 这个外部库其实就是 user 目录下的 lib.rs 以及它引用的若干子模块。
#[macro_use]
extern crate user_lib;

/// 正确输出：
/// Hello world from user mode program!

#[no_mangle]
fn main() -> i32 {
    println!("Hello, world from user mode program!");
    0
}