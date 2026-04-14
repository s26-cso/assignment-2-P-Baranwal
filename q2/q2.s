
.globl main

.section .data
fmt_out:    .string "%d"            # printf format for integer
space:      .string " "             # space separator
newline:    .string "\n"            # final newline

.section .text

main:
    # Prologue – save registers and align stack (already 16‑byte aligned)
    addi    sp, sp, -80
    sd      ra, 72(sp)
    sd      s0, 64(sp)
    sd      s1, 56(sp)
    sd      s2, 48(sp)
    sd      s3, 40(sp)
    sd      s4, 32(sp)
    sd      s5, 24(sp)
    sd      s6, 16(sp)
    sd      s7, 8(sp)

    mv      s6, a0                  # s6 = argc
    mv      s7, a1                  # s7 = argv

    # argc in a0, argv in a1
    li      t0, 1
    ble     a0, t0, main_exit       # if argc <= 1, nothing to do

    # n = argc - 1
    addi    s0, a0, -1              # s0 = number of elements (n)

    # Convert command‑line arguments to integers and store in arr[]
    # Allocate arr: malloc(n * 4)
    slli    a0, s0, 2               # a0 = n * sizeof(int)
    call    malloc
    mv      s1, a0                  # s1 = arr (base address)

# Use saved regs for loop state - survive call atoi
    li      s8, 1                   # s8 = i (argv index), was t0
    li      s9, 0                  # s9 = j (arr index),  was t1

parse_loop:
    bge     s8, s6, parse_done      # while i < argc
    slli    t3, s8, 3               # t3 = i * 8
    add     t3, s7, t3              # use s7, not t2
    ld      a0, 0(t3)               # a0 = argv[i]
    call    atoi                    # a0 = integer 
    slli    t4, s9, 2               # t4 = j * 4
    add     t4, s1, t4
    sw      a0, 0(t4)               # arr[j] = value
    addi    s8, s8, 1               # i++
    addi    s9, s9, 1               # j++
    j       parse_loop

parse_done:

    # Allocate result array and stack array
    # result = malloc(n * 4)
    slli    a0, s0, 2
    call    malloc
    mv      s2, a0                  # s2 = result

    # stack = malloc(n * 4)   (store indices)
    slli    a0, s0, 2
    call    malloc
    mv      s3, a0                  # s3 = stack

    # stack top index (empty = -1)
    li      s4, -1                  # s4 = top

    # Algorithm: iterate from right to left
    # i = n - 1
    addi    s5, s0, -1              # s5 = i (loop counter)

loop_i:
    blt     s5, zero, loop_i_end    # if i < 0, done

    # while stack not empty and arr[stack[top]] <= arr[i] 
while_cond:
    blt     s4, zero, while_end     # if top < 0, stack empty
    # load arr[stack[top]]
    slli    t0, s4, 2
    add     t0, s3, t0
    lw      t0, 0(t0)               # t0 = stack[top] (index)
    slli    t1, t0, 2
    add     t1, s1, t1
    lw      t1, 0(t1)               # t1 = arr[stack[top]]
    # load arr[i]
    slli    t2, s5, 2
    add     t2, s1, t2
    lw      t2, 0(t2)               # t2 = arr[i]
    # compare
    bgt     t1, t2, while_end       # if arr[stack[top]] > arr[i], stop popping
    # pop: top--
    addi    s4, s4, -1
    j       while_cond
while_end:

    # set result[i] 
    blt     s4, zero, set_minus_one # stack empty -> result[i] = -1
    # stack not empty -> result[i] = stack[top]
    slli    t0, s4, 2
    add     t0, s3, t0
    lw      t0, 0(t0)               # t0 = stack[top]
    slli    t1, s5, 2
    add     t1, s2, t1
    sw      t0, 0(t1)               # result[i] = t0
    j       push_i
set_minus_one:
    li      t0, -1
    slli    t1, s5, 2
    add     t1, s2, t1
    sw      t0, 0(t1)               # result[i] = -1

push_i:
    # push current index i onto stack
    addi    s4, s4, 1               # top++
    slli    t0, s4, 2
    add     t0, s3, t0
    sw      s5, 0(t0)               # stack[top] = i

    # i--
    addi    s5, s5, -1
    j       loop_i
loop_i_end:

    # Print the result array
    li      s5, 0                   # i = 0
print_loop:
    bge     s5, s0, print_done      # while i < n
    slli    t1, s5, 2
    add     t1, s2, t1
    lw      a1, 0(t1)               # a1 = result[i]
    la      a0, fmt_out
    call    printf

    # print space if not the last element
    addi    t1, s5, 1
    bge     t1, s0, skip_space
    la      a0, space
    call    printf
skip_space:
    addi    s5, s5, 1
    j       print_loop
print_done:
    la      a0, newline
    call    printf

    mv      a0, s1
    call    free
    mv      a0, s2
    call    free
    mv      a0, s3
    call    free

main_exit:
    # Epilogue – restore registers and return
    li      a0, 0                   # return 0
    ld      ra, 72(sp)
    ld      s0, 64(sp)
    ld      s1, 56(sp)
    ld      s2, 48(sp)
    ld      s3, 40(sp)
    ld      s4, 32(sp)
    ld      s5, 24(sp)
    ld      s6, 16(sp)
    ld      s7, 8(sp)
    addi    sp, sp, 80
    ret