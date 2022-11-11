OUTPUT_ARCH(riscv) /* 设置了目标平台为 riscv  */
ENTRY(_start)  /* 设置了整个程序的入口点为之前定义的全局符号 _start */
BASE_ADDRESS = 0x80200000; /* RustSBI 期望的 OS 起始地址 */

SECTIONS
{
    . = BASE_ADDRESS;
    skernel = .;

    stext = .;  /* 代码段 .text */
    .text : {
        *(.text.entry)     
        *(.text .text.*)    /* 起始地址 结束地址 */
    }

    . = ALIGN(4K);
    etext = .;  /* 只读数据段 .rodata */
    srodata = .;
    .rodata : {
        *(.rodata .rodata.*) /* 起始地址 结束地址 */
    }

    . = ALIGN(4K);
    erodata = .; /* 数据段 .data */
    sdata = .;
    .data : {
        *(.data .data.*) /* 起始地址 结束地址 */
    }

    . = ALIGN(4K);
    edata = .; /* bss 段 .bss 由低到高依次放置 */
    .bss : {
        *(.bss.stack)
        sbss = .;
        *(.bss .bss.*) /* 起始地址 结束地址 */
    }

    . = ALIGN(4K);
    ebss = .;
    ekernel = .;

    /DISCARD/ : {
        *(.eh_frame)
    }
}