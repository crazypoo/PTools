#ifdef __arm64__
//
//  fix_UIKeyboardTaskQueue.s
//  PooTools_Example
//
//  Created by 邓杰豪 on 12/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

/**
 原实现
 -[UIKeyboardTaskQueue tryLockWhenReadyForMainThread]:
    ldr    x0, [x0, #0x10]
    mov    x2, #0x0
    b    "_objc_msgSend$tryLockWhenCondition:"
 */

// 重写实现
.section    __TEXT,__cstring,cstring_literals
tryLockWhenCondition.str:
.asciz      "tryLockWhenCondition:"

.text
.align 4
.global _fix_UIKeyboardTaskQueue_tryLockWhenReadyForMainThread
.cfi_startproc
_fix_UIKeyboardTaskQueue_tryLockWhenReadyForMainThread:
stp    x20, x19, [sp, #-0x20]!
stp    x29, x30, [sp, #0x10]
add    x29, sp, #0x10
mov    x19, x0                     ; self
adrp   x0, tryLockWhenCondition.str@PAGE
add    x0, x0, tryLockWhenCondition.str@PAGEOFF
bl     _sel_registerName           ; @selector(tryLockWhenCondition:)
mov    x1, x0
ldr    x0, [x19, #0x10]            ; _lock
mov    x2, #0x0
bl     _objc_msgSend               ; -[_lock tryLockWhenCondition:0]
ldp    x29, x30, [sp, #0x10]       ; 恢复fp和lr
ldp    x20, x19, [sp], #0x20       ; 恢复callee-saved寄存器、并恢复sp
cbz    x0, 1f
// 如tryLock成功，则继续执行-[UIKeyboardTaskQueue continueExecutionOnMainThread]的指令
ret

// 如tryLock失败，则模拟从-[UIKeyboardTaskQueue continueExecutionOnMainThread] return，不再继续执行
1:
ldp    x29, x30, [sp, #0x20]       ; 恢复fp和lr
ldp    x20, x19, [sp, #0x10]       ; 恢复callee-saved寄存器
add    sp, sp, #0x30               ; 恢复sp
autibsp                            ; Authenticate Instruction address
ret
.cfi_endproc
#endif
