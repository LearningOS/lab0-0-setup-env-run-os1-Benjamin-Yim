    .section .text.entry
    .globl _start  # _start 发送到GDT
_start:
    la sp, boot_stack_top # 取 boot_stack_top 地址存储到 sp
    call rust_main #调用 rust_main

    .section .bss.stack
    .globl boot_stack # boot_stack 发送到GDT
boot_stack:
    .space 4096 * 16
    .globl boot_stack_top # boot_stack_top 发送到 GDT
boot_stack_top: