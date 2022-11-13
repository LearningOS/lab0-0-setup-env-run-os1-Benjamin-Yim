    .section .text.entry
    .globl _start # _start 作为操作系统的入口地址，将依据链接脚本被放在 BASE_ADDRESS 处。
_start:
    # la sp, boot_stack_top 作为 OS 的第一条指令， 将 sp 设置为栈空间的栈顶
    la sp, boot_stack_top
    # 第二条指令函数调用 rust_main ，这里的 rust_main 是我们自己编写的应用入口。
    call rust_main
    # 栈空间被命名为 .bss.stack ，链接脚本里有它的位置。
    .section .bss.back 
    # 栈底    
    .globl boot_stack
boot_stack:
    # 我们预留了一块大小为 4096 * 16 字节，也就是  的空间， 用作操作系统的栈空间。
    .space 4096*16
    .globl boot_stack_top
# 栈顶
boot_stack_top: