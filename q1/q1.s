
.globl make_node, insert, get, getAtMost

# ----------------------------------------------------------------------
# A node in  BST looks like this in memory:
#
#   [ val (4 bytes) | left ptr (4 bytes) | right ptr (4 bytes) ]
#     offset 0          offset 4              offset 8
#
# Total size: 12 bytes per node
# ----------------------------------------------------------------------

.section .data
size_node:  .word 12        # bytes malloc needs for one node

.section .text

# ----------------------------------------------------------------------
# make_node(int val)
#
# Creates a brand-new leaf node with the given value.
# Both children start as NULL
#
# a0 (in)  = the integer value to store
# a0 (out) = pointer to the new node, or NULL if malloc failed
# ----------------------------------------------------------------------
make_node:
    addi    sp, sp, -16
    sd      ra, 8(sp)
    sd      s0, 0(sp)

    mv      s0, a0              # hang onto val while we call malloc

    la      a0, size_node
    lw      a0, 0(a0)           # a0 = 12
    call    malloc
    beqz    a0, make_node_fail  # malloc returned NULL

    sw      s0, 0(a0)           # store val
    sw      zero, 4(a0)         # left  = NULL
    sw      zero, 8(a0)         # right = NULL

make_node_done:
    ld      ra, 8(sp)
    ld      s0, 0(sp)
    addi    sp, sp, 16
    ret

make_node_fail:
    li      a0, 0               # hand back NULL to the caller
    j       make_node_done


# ----------------------------------------------------------------------
# insert(struct Node* root, int val)
#
# Walks the BST to find the right spot for val and drops it in.
# Duplicate values go to the LEFT subtree (val <= node->val goes left).
# Returns the root of the (possibly updated) tree.
#
# a0 (in)  = root pointer (may be NULL for an empty tree)
# a1 (in)  = value to insert
# a0 (out) = root pointer (same address unless the tree was empty)
# ----------------------------------------------------------------------
insert:
    addi    sp, sp, -32
    sd      ra, 24(sp)
    sd      s0, 16(sp)
    sd      s1, 8(sp)
    sd      s2, 0(sp)           # s2 saved but unused

    mv      s0, a0              # s0 = root
    mv      s1, a1              # s1 = val

    bnez    s0, insert_recurse  # non-empty tree

    # Tree is empty here, so val becomes the new root
    mv      a0, s1
    call    make_node
    j       insert_done

insert_recurse:
    lw      t0, 0(s0)           # t0 = current node's value

    ble     s1, t0, insert_left # val <= node->val - go left

    # val > node->val - go right
    lw      a0, 8(s0)           # a0 = root->right
    mv      a1, s1
    call    insert
    sw      a0, 8(s0)           # root->right = whatever insert returned
    j       insert_return_root

insert_left:
    lw      a0, 4(s0)           # a0 = root->left
    mv      a1, s1
    call    insert
    sw      a0, 4(s0)           # root->left = whatever insert returned

insert_return_root:
    mv      a0, s0              # return the current root unchanged

insert_done:
    ld      ra, 24(sp)
    ld      s0, 16(sp)
    ld      s1, 8(sp)
    ld      s2, 0(sp)
    addi    sp, sp, 32
    ret


# ----------------------------------------------------------------------
# get(struct Node* root, int val)
#
# BST search — go left if smaller, right if bigger, done if equal.
#
# a0 (in)  = root pointer
# a1 (in)  = value to look for
# a0 (out) = pointer to the matching node, or NULL if not found
# ----------------------------------------------------------------------
get:
    beqz    a0, get_not_found   # fell off the tree — not here

    lw      t0, 0(a0)           # t0 = current node's value
    beq     t0, a1, get_found   # matched

    blt     a1, t0, get_go_left # val is smaller - search left subtree

    # val is larger - search right subtree
    lw      a0, 8(a0)
    j       get

get_go_left:
    lw      a0, 4(a0)
    j       get

get_found:
    ret                         # a0 already points at the node we want

get_not_found:
    li      a0, 0
    ret


# ----------------------------------------------------------------------
# getAtMost(int val, struct Node* root)
#
# Finds the largest value in the tree that is still <= val.
# Returns -1 if every value in the tree is strictly greater than val.
#
# whenever we find a node whose value fits (node->val <= val),
# we remember it as our best candidate and explore the RIGHT subtree
# If a node's value is too big, we go LEFT to find smaller ones.
#
# a0 (in)  = val  (the upper bound we are searching under)
# a1 (in)  = root pointer
# a0 (out) = best matching value, or -1
#
# ----------------------------------------------------------------------
getAtMost:
    addi    sp, sp, -16
    sd      ra, 8(sp)
    sd      s0, 0(sp)

    # We need one more saved register for the best-result.
    addi    sp, sp, -8
    sd      s1, 0(sp)

    mv      s0, a1              # s0 = current node 
    li      s1, -1              # s1 = best result so far 

getAtMost_loop:
    beqz    s0, getAtMost_done  # ran out of tree

    lw      t0, 0(s0)           # t0 = this node's value

    bgt     t0, a0, getAtMost_go_left   # node->val > val - go left

    # node->val <= val - this is a valid candidate, and it's the
    # largest we've seen so far on this path.
    mv      s1, t0              # update best
    lw      s0, 8(s0)           # try right child
    j       getAtMost_loop

getAtMost_go_left:
    lw      s0, 4(s0)           # value was too big, go left
    j       getAtMost_loop

getAtMost_done:
    mv      a0, s1              # a0 = best value found (or -1)
    ld      s1, 0(sp)
    addi    sp, sp, 8
    ld      ra, 8(sp)
    ld      s0, 0(sp)
    addi    sp, sp, 16
    ret