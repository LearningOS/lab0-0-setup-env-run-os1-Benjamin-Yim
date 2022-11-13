use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> !{
    // 无返回的函数，死循环
    loop{}
}