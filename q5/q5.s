
.globl main

.section .data
filename:   .string "input.txt"
mode_r:     .string "r"
yes_str:    .string "Yes\n"
no_str:     .string "No\n"

.section .bss
    .lcomm buf1, 1          # single byte buffer for left character
    .lcomm buf2, 1          # single byte buffer for right character

.section .text

main:
    # Prologue – save return address and callee-saved registers
    # s0 = FILE*, s1 = file size, s2 = left index, s3 = right index
    addi    sp, sp, -40
    sd      ra, 32(sp)
    sd      s0, 24(sp)
    sd      s1, 16(sp)
    sd      s2, 8(sp)
    sd      s3, 0(sp)           

    # Open the file "input.txt"
    # fopen(filename, "r")
    # Returns FILE* in a0, or NULL on failure.
    la      a0, filename
    la      a1, mode_r
    call    fopen
    beqz    a0, print_no            # if FILE* == NULL, file cannot be opened

    mv      s0, a0                  # save FILE* in s0

    # Get file size using fseek(fp, 0, SEEK_END) + ftell(fp)
    # SEEK_END = 2
    mv      a0, s0                  # fp
    li      a1, 0                   # offset = 0
    li      a2, 2                   # whence = SEEK_END
    call    fseek
    bnez    a0, print_no            # fseek returns 0 on success

    mv      a0, s0                  # fp
    call    ftell                   # returns file size (position at end)
    bltz    a0, print_no            # ftell returns -1 on failure

    mv      s1, a0                  # s1 = file size (n)

    # Handle empty file: size 0 -> palindrome
    beqz    s1, print_yes

    # Initialize left and right indices
    li      s2, 0                   # left = 0
    addi    s3, s1, -1              # right = size - 1

    # Compare characters from both ends
loop:
    bge     s2, s3, print_yes       # if left >= right, all matched

    # Seek to and read character at 'left' index 
    mv      a0, s0                  # fp
    mv      a1, s2                  # offset = left
    li      a2, 0                   # SEEK_SET
    call    fseek
    bnez    a0, print_no

    # fread(&buf1, 1, 1, fp) – read one byte
    la      a0, buf1                # ptr
    li      a1, 1                   # size of each element
    li      a2, 1                   # number of elements
    mv      a3, s0                  # fp
    call    fread
    li      t0, 1
    bne     a0, t0, print_no        # should read exactly 1 element

    # Seek to and read character at 'right' index
    mv      a0, s0                  # fp
    mv      a1, s3                  # offset = right
    li      a2, 0                   # SEEK_SET
    call    fseek
    bnez    a0, print_no

    la      a0, buf2                # ptr
    li      a1, 1                   # size
    li      a2, 1                   # count
    mv      a3, s0                  # fp
    call    fread
    li      t0, 1
    bne     a0, t0, print_no

    # Compare the two bytes 
    la      t0, buf1
    lbu     t1, 0(t0)               # load left char
    la      t0, buf2
    lbu     t2, 0(t0)               # load right char
    bne     t1, t2, print_no        # mismatch -> not palindrome

    # Move pointers inward
    addi    s2, s2, 1
    addi    s3, s3, -1
    j       loop

# Output 
print_yes:
    la      a0, yes_str
    call    printf
    j       cleanup

print_no:
    la      a0, no_str
    call    printf

cleanup:
    beqz    s0, skip_fclose
    mv      a0, s0
    call    fclose
skip_fclose:

    li      a0, 0
    ld      ra, 32(sp)
    ld      s0, 24(sp)
    ld      s1, 16(sp)
    ld      s2, 8(sp)
    ld      s3, 0(sp)           
    addi    sp, sp, 40
    ret