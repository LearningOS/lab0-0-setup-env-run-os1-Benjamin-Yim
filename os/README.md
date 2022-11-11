```
# os/.cargo/config
[build]
target = "riscv64gc-unknown-none-elf"
```
1. 这将使 cargo 工具在 os 目录下默认会使用 riscv64gc-unknown-none-elf 作为目标平台。 这种编译器运行的平台（x86_64）与可执行文件运行的目标平台不同的情况，称为 交叉编译 (Cross Compile)。

2. 在 `main.rs` 添加 `#![no_std]` 表示不在使用 `Rust` 标准库 `std` 转而使用核心库 `core`

3. 运行 `cargo build` 发现 `println!` 报错。`println!` 宏是由标准库 `std` 提供的，且会使用到一个名为 `write` 的系统调用。 

4. 注释 `println!`

5. 提供 `#[panic_handler]` 语义，其大致功能是打印出错位置和原因并杀死当前应用。 但核心库 core 并没有提供这项功能，得靠我们自己实现。

6. 新建一个子模块 `lang_items.rs`，在里面编写 `panic` 处理函数，通过标记 `#[panic_handler]` 告知编译器采用我们的实现

7. 在 `main.rs` 中添加 `mod lang_items;`

8. `cargo build`  报错。 编译器提醒我们缺少一个名为 `start` 的语义项。 `start` 语义项代表了标准库 `std` 在执行应用程序之前需要进行的一些初始化工作。由于我们禁用了标准库，编译器也就找不到这项功能的实现了。

9. 在 `main.rs` 的开头加入设置 `#![no_main]` 告诉编译器我们没有一般意义上的 `main` 函数， 并将原来的 `main` 函数删除。

**我们终于移除了所有标准库依赖。目前的主要代码包括 main.rs 和 lang_items.rs**


### 新的开始,构建用户态执行环境

1. 首先我们要给 `Rust` 编译器编译器提供入口函数 `_start()`，在 `main.rs` 中添加

2. 编译后查看就会反向有 `_start` 入口

3. 运行 `qemu-riscv64 target/riscv64gc-unknown-none-elf/debug/os` 代码进入死循环，说明测试成功

4. 注释掉 `loop{}` 重新编译，然后重复第三步骤，发现 `Segmentation fault (core dumped)`。
 
    QEMU有两种运行模式：User mode 模式，即用户态模拟，如 qemu-riscv64 程序， 能够模拟不同处理器的用户态指令的执行，并可以直接解析ELF可执行文件， 加载运行那些为不同处理器编译的用户级Linux应用程序。

5. 增加一个退出机制代码，操作系统提供的 exit 系统调用来退出程序

6. 运行命令：`qemu-riscv64 target/riscv64gc-unknown-none-elf/debug/os` 成功退出

_start 函数调用了一个 sys_exit 函数， 向操作系统发出了退出的系统调用请求，退出码为 `9`[**echo $?**] 查看 

### 实现输出字符串的相关函数

1. 封装一下对 SYSCALL_WRITE 系统调用

2. 实现基于 `Write` `Trait` 的数据结构，并完成 `Write` `Trait` 所需要的 `write_str` 函数，并用 `print` 函数进行包装。

3. 基于 `print` 函数，实现 `Rust` 语言 格式化宏

4. `cargo build --target riscv64gc-unknown-none-elf` 编译成功

### 上一个阶梯，构建裸机执行环境

1. 把 `Hello world!` 应用程序从用户态搬到内核态。

2. `RustSBI` 是什么？
    `SBI` 是 `RISC-V` 的一种底层规范，`RustSBI` 是它的一种实现。 操作系统内核与 `RustSBI` 的关系有点像应用与操作系统内核的关系，后者向前者提供一定的服务。只是`SBI`提供的服务很少， 比如**关机**，**显示字符串**等。

3. 实现关机功能

4. 修改 `_start` 调用 `shutdown`.

5. 编译运行，发现死机无法返回。

6. 关闭终端，新建一个终端
    问题在哪？通过 rust-readobj 分析 os 可执行程序，发现其入口地址不是 RustSBI 约定的 0x80200000 。我们需要修改程序的内存布局并设置好栈空间。

### 设置正确的程序内存布局

1. 修改 `Cargo` 的配置文件来使用我们自己的链接脚本 `os/src/linker.ld`

2. 编写 `os/src/linker.ld` 脚本

### 正确配置栈空间布局

1. 创建 `src/entry.asm` 正确配置栈空间布局

2. 预留 4096*16 字节(64KB)空间栈空间给操作系统使用

3. 栈空间命名为 `.bss.stack` ，链接脚本里有它的位置。

4. `boot_stack_top` 设置栈顶的描述符位置,`boot_stack` 设置栈底描述符位置

5. `_start` 作为操作系统的入口地址，将依据链接脚本被放在 BASE_ADDRESS 处。