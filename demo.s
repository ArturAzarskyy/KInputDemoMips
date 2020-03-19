
##################################
# Example of exception handling  #
# and memory-mapped I/O          #
##################################
################
# Handler Data #
################

        .kdata
        .align  4
ktemp:  .space  16       # allocate 4 consecutive words, 
                         # with storage uninitialized,
                         # for temporary saving (stack can't be used)


char:   .ascii  " "
nl:     .asciiz "\n"


##########################
# Handler Implementation #
##########################
        .ktext 0x80000180

        la     $k1, ktemp   # address of temporary save area
                            # in exception handler, can NOT use stack
                            # as stack pointer/stack may be corrupt!
                            # Consequence: exception handler NOT re-entrant!
        sw     $a0, 0($k1)  # save $a0 as we'll use it
        sw     $a1, 4($k1)  # save $a1 as we'll use it
        sw     $v1, 8($k1)  # save $v0 as we'll use it
        sw     $ra, 12($k1) # save $ra as we'll use it

        beq   $v1, $zero, e_key  # handle hardware interrupt (exception type 0)
        j     e_int_end

e_key: 

        mfc0  $v1, $13                      # Cause
        andi  $v1, $v1, 0x0100              # mask pending interrupt bit 8 
        beq   $v1, $zero, e_int_keyrecv_end # not keyboard interrupt

        # handle keyboard receive interrupt

        mfc0  $a0, $13        # coprocessor0 Cause register
        xor   $a0, $a0, $v0   # set pending interrupt bit 8 to 0
        mtc0  $a0, $13        # reset Cause (removing pending interrupt)

        li    $a0, 0xFFFF0004 # Receiver data address (interrupt based, so don't need to check Receiver control)
        lw    $v1, 0($a0)     # Receiver data 
        sb    $v1, 0($a0)     # store Received data (key pressed) 
                              # note: accessing data re-sets Ready bit 
                              # in Receiver control

        #la    $a0, key        # key pressed message/character
        jal   print_string

e_int_keyrecv_end:

e_int_end:

        # restore saved values
        la    $k1, ktemp
        lw    $a0, 0($k1)
        lw    $a1, 4($k1)
        lw    $v1, 8($k1)
        lw    $ra, 12($k1)

        eret  # return from exception, PC <- EPC


print_string: 
        li $v0, 4
        syscall
        jr    $ra 
#######################
# Program Entry Point #
#######################

        .text
        .globl main
main:
        li    $a0, 0xFFFF0000 # Receiver control
        lw    $t0, 0($a0)
        ori   $t0, 0x02       # set bit 1 to enable input interrupts
                              # such a-synchronous I/O (handling of keyboard input in this case) 
                              # this is much more efficient than the "polling" we use for output
                              # In particular, it does not "block" the main program in case there is no input
        sw     $t0, 0($a0)    # update Receiver control

# infinite loop

forever:      
        nop
        nop
        j forever

