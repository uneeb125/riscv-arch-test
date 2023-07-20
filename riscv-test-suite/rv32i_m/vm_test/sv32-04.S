// -----------
// Copyright (c) 2020. RISC-V International. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
// -----------

/* U mode page access in S mode, where Loads are performed when VA!=PA */

#include "model_test.h"
#include "arch_test.h"
RVTEST_ISA("RV32I")
        
.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

#ifdef TEST_CASE_1

RVTEST_CASE(0,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*Zicsr.*); def rvtest_mtrap_routine=True; def TEST_CASE_1=True",sv32)

RVTEST_SIGBASE( x12,signature_x12_1)

main: 
// Setup RWX PMP permissions for all the physical memory
#define REGION0_ADDR    (0x80000000 >> PMP_SHIFT)   
#define REGION1_ADDR    (0x88000000 >> PMP_SHIFT)   
#define REGION2_ADDR    (0x8c000000 >> PMP_SHIFT)   
#define REGION3_ADDR    (0x8f000000 >> PMP_SHIFT)   
#define RWX             (PMP_R|PMP_W|PMP_X)
#define PMPCONFIG0      ((((RWX|PMP_L|PMP_TOR)&0xFF) << 0)   | \
                        (((RWX|PMP_L|PMP_TOR)&0xFF) <<  8)   | \
                        (((RWX|PMP_L|PMP_TOR)&0xFF) << 16)   | \
                        (((RWX|PMP_L|PMP_TOR)&0xFF) << 24))

    /* Assigning addresses to PMP address registers */
    LI(a5, REGION0_ADDR)
	csrw 	pmpaddr0, a5
	LI(a5, REGION1_ADDR)
	csrw 	pmpaddr1, a5
    LI(a5, REGION2_ADDR)
	csrw 	pmpaddr2, a5
	LI(a5, REGION3_ADDR)
	csrw 	pmpaddr3, a5
    /* Decalring pmp configuration register */
	LI(a5, PMPCONFIG0)
	csrw pmpcfg0, a5

// Definitions for PTEs
#define PTE_L1_addr 0x81000000  // base address of root (1st level) page table
#define PTE_L2_addr 0x82000000  // base address of 2nd level page table
// 
#define PA0 0x80000000 >> 2
#define PA1 0x80003000 >> 2
#define PA2 0x80002000 >> 2
// satp register for sv32: satp.mode = 1, satp.ppn = PTE_L1_addr
#define SATP_REG (SATP32_MODE | (PTE_L1_addr >> 12))
// setting up Page Table entries
#define PTE1_L1 ((PTE_L2_addr >> 2) | PTE_V)
#define PTE0_L2 (PA0 | PTE_V | PTE_X | PTE_A )
#define PTE1_L2 (PA1 | PTE_V | PTE_R | PTE_W | PTE_D | PTE_A | PTE_U) 	// sw
#define PTE2_L2 (PA2 | PTE_V | PTE_R | PTE_A | PTE_U )	// lw

    csrw mie, zero
  	csrw satp, zero                     // Disable address translation.
	LA (t0, mtvec_handler)
    csrw mtvec, t0						// Write vector table address

    /* setting mstatus.SUM =1 to get 
	acccess of U mode pages in S mode */
	li      t0, MSTATUS_SUM				
    csrs    mstatus, t0

    /* Goto S mode */
	LA (t3, Goto_smodetg763errr433w
	jalr t3
    
    LI (t0, PTE_L1_addr)
    LI (t1, 0x800)
    add t0, t0,t1
    LI (t1, PTE1_L1)
    sw t1, 0(t0) 

    LI (t0, PTE_L2_addr)
    addi t1,t0, 0x1c0
	addi t2,t0, 0x08
	addi t3,t0, 0xc

    LI (t4, PTE0_L2)
    sw t4, 0(t0)
    
    LI (t4, PTE1_L2)
    sw t4, 0(t1)
	sw t4, 0(t3)

	LI (t4, PTE2_L2)
    sw t4, 0(t2)

    LI (t3, SATP_REG)
    csrw satp, t3       // enable address translation

    LI (x12, 0x80070100)
inst_0:
// rs1 != rd, rs1==x6, rd==x24, ea_align == 0 and (imm_val % 4) == 0, imm_val < 0
// opcode:lw op1:x6; dest:x24; immval:-0x4; align:0
TEST_LOAD(x12,x17,0,x6,x24,-0x4,0,lw,0)

inst_1:
// rs1 == rd, rs1==x4, rd==x4, ea_align == 0 and (imm_val % 4) == 1, 
// opcode:lw op1:x4; dest:x4; immval:-0x3; align:0
TEST_LOAD(x12,x17,0,x4,x4,-0x3,4,lw,0)

inst_2:
// rs1==x21, rd==x15, ea_align == 0 and (imm_val % 4) == 2, 
// opcode:lw op1:x21; dest:x15; immval:-0xa; align:0
TEST_LOAD(x12,x17,0,x21,x15,-0xa,8,lw,0)

inst_3:
// rs1==x26, rd==x8, ea_align == 0 and (imm_val % 4) == 3, imm_val > 0
// opcode:lw op1:x26; dest:x8; immval:0x7; align:0
TEST_LOAD(x12,x17,0,x26,x8,0x7,12,lw,0)

inst_4:
// rs1==x27, rd==x26, imm_val == 0, 
// opcode:lw op1:x27; dest:x26; immval:0x0; align:0
TEST_LOAD(x12,x17,0,x27,x26,0x0,16,lw,0)

inst_5:
// rs1==x20, rd==x18, 
// opcode:lw op1:x20; dest:x18; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x20,x18,-0x800,20,lw,0)

inst_6:
// rs1==x30, rd==x9, 
// opcode:lw op1:x30; dest:x9; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x30,x9,-0x800,24,lw,0)

inst_7:
// rs1==x18, rd==x11, 
// opcode:lw op1:x18; dest:x11; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x18,x11,-0x800,28,lw,0)

inst_8:
// rs1==x13, rd==x6, 
// opcode:lw op1:x13; dest:x6; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x13,x6,-0x800,32,lw,0)

inst_9:
// rs1==x14, rd==x10, 
// opcode:lw op1:x14; dest:x10; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x14,x10,-0x800,36,lw,0)

inst_10:
// rs1==x9, rd==x3, 
// opcode:lw op1:x9; dest:x3; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x9,x3,-0x800,40,lw,0)

inst_11:
// rs1==x2, rd==x31, 
// opcode:lw op1:x2; dest:x31; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x2,x31,-0x800,44,lw,0)

inst_12:
// rs1==x23, rd==x0, 
// opcode:lw op1:x23; dest:x0; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x23,x0,-0x800,48,lw,0)

inst_13:
// rs1==x3, rd==x19, 
// opcode:lw op1:x3; dest:x19; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x3,x19,-0x800,52,lw,0)

inst_14:
// rs1==x7, rd==x13, 
// opcode:lw op1:x7; dest:x13; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x7,x13,-0x800,56,lw,0)

inst_15:
// rs1==x1, rd==x7, 
// opcode:lw op1:x1; dest:x7; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x1,x7,-0x800,60,lw,0)

inst_16:
// rs1==x19, rd==x14, 
// opcode:lw op1:x19; dest:x14; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x19,x14,-0x800,64,lw,0)

inst_17:
// rs1==x8, rd==x29, 
// opcode:lw op1:x8; dest:x29; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x8,x29,-0x800,68,lw,0)

inst_18:
// rs1==x24, rd==x5, 
// opcode:lw op1:x24; dest:x5; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x24,x5,-0x800,72,lw,0)

inst_19:
// rs1==x31, rd==x16, 
// opcode:lw op1:x31; dest:x16; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x31,x16,-0x800,76,lw,0)

inst_20:
// rs1==x10, rd==x25, 
// opcode:lw op1:x10; dest:x25; immval:-0x800; align:0
TEST_LOAD(x12,x17,0,x10,x25,-0x800,80,lw,0)

inst_21:
// rs1==x5, rd==x1, 
// opcode:lw op1:x5; dest:x1; immval:-0x800; align:0
TEST_LOAD(x12,x3,0,x5,x1,-0x800,84,lw,0)

inst_22:
// rs1==x15, rd==x22, 
// opcode:lw op1:x15; dest:x22; immval:-0x800; align:0
TEST_LOAD(x12,x3,0,x15,x22,-0x800,88,lw,0)

LI (x1, 0x80070000)			// sw VA ----> PA (0x80003XXX)

RVTEST_SIGBASE( x1,signature_x1_0)

inst_23:
// rs1==x17, rd==x27, 
// opcode:lw op1:x17; dest:x27; immval:-0x800; align:0
TEST_LOAD(x1,x3,0,x17,x27,-0x800,0,lw,0)

inst_24:
// rs1==x12, rd==x20, 
// opcode:lw op1:x12; dest:x20; immval:-0x800; align:0
TEST_LOAD(x1,x3,0,x12,x20,-0x800,4,lw,0)

inst_25:
// rs1==x28, rd==x30, 
// opcode:lw op1:x28; dest:x30; immval:-0x800; align:0
TEST_LOAD(x1,x3,0,x28,x30,-0x800,8,lw,0)

inst_26:
// rs1==x25, rd==x28, 
// opcode:lw op1:x25; dest:x28; immval:-0x800; align:0
TEST_LOAD(x1,x3,0,x25,x28,-0x800,12,lw,0)

inst_27:
// rs1==x22, rd==x12, 
// opcode:lw op1:x22; dest:x12; immval:-0x800; align:0
TEST_LOAD(x1,x3,0,x22,x12,-0x800,16,lw,0)

inst_28:
// rs1==x16, rd==x2, 
// opcode:lw op1:x16; dest:x2; immval:-0x800; align:0
TEST_LOAD(x1,x3,0,x16,x2,-0x800,20,lw,0)

inst_29:
// rs1==x29, rd==x21, 
// opcode:lw op1:x29; dest:x21; immval:-0x800; align:0
TEST_LOAD(x1,x3,0,x29,x21,-0x800,24,lw,0)

inst_30:
// rs1==x11, rd==x17, 
// opcode:lw op1:x11; dest:x17; immval:-0x800; align:0
TEST_LOAD(x1,x3,0,x11,x17,-0x800,28,lw,0)

inst_31:
// rd==x23, 
// opcode:lw op1:x12; dest:x23; immval:-0x800; align:0
TEST_LOAD(x1,x3,0,x12,x23,-0x800,32,lw,0)

j exit


	/* Trap Handler Starts */
mtvec_handler:
	csrr t1, mcause			// read mcause
	# RVTEST_SIGUPD(x3,t1,0)
	# addi x3,x3,4
	# csrr t0, mstatus		// read mstatus
	# RVTEST_SIGUPD(x3,t0,0)
	# addi x3,x3,4
	// set up temporary registers
    li t3, 0x3
	li t4, 0x9
	li t5, 0x10
	li t6, 0x11
	// set mepc to return address
	csrr 	t0, mepc
	addi 	t0,t0,4
	csrw 	mepc, t0
	# csrr 	t0, mepc
	# RVTEST_SIGUPD(x3,t0,0)
	# addi 	x3,x3,4
	beq 	t4,s1, u_mode
	beq 	t5,s1, s_mode
	beq 	t6,s1, m_mode
    bne     t3,t1, m_mode
	mret
m_mode:
	li      t0, MSTATUS_MPP
    csrs    mstatus, t0		// set mstatus.mpp=11
	# csrr 	a1, mstatus
	# RVTEST_SIGUPD(x3,a1,0)
	# addi x3,x3,4
	mret	
s_mode:
	li 		t0, MSTATUS_MPP
	csrc	mstatus, t0		// clear mstatus
	li      t0, 0x800
    csrs    mstatus, t0		// set mstatus.mpp=01
    # li      t0, MSTATUS_MXR
    # csrs    mstatus, t0
    # li      t0, MSTATUS_SUM
    # csrs    mstatus, t0
    # li      t0, MSTATUS_MPRV
    # csrs    mstatus, t0

	mret
u_mode:
	li 		t0, MSTATUS_MPP
	csrc	mstatus, t0		// clear mstatus --> mstatus.MPP=00
	# csrr 	a1, mstatus
	# RVTEST_SIGUPD(x3,a1,0)
	# addi x3,x3,4
	mret

	/* Trap Handler ends here  */

Goto_mmode:
	addi s1,x0,0x11
	ebreak
	addi s1,x0,0x0
	jr ra
Goto_smode:
	addi s1,x0,0x10
	ebreak
	addi s1,x0,0x0
	jr ra
Goto_umode:
	addi s1,x0,0x9
	ebreak
	addi s1,x0,0x0
	jr ra

exit: 
    la t0, Goto_mmode
	jalr t0
	# li t0,0xceeeeeed
	# RVTEST_SIGUPD(x3,t0,0)
	# addi x3,x3,4

#endif
    
RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
.align 4
rvtest_data:
.word 0xbabecafe
RVTEST_DATA_END

RVMODEL_DATA_BEGIN

signature_x3_0:
    .fill 0*(XLEN/32),4,0x00000000


signature_x12_1:
    .fill 23*(XLEN/32),4,0xcafebeef

signature_x1_0:
    .fill 9*(XLEN/32),4,0xcafebeef

#ifdef rvtest_mtrap_routine

mtrap_sigptr:
    .fill 12*(XLEN/32),4,0xdeadbeef

#endif

#ifdef rvtest_gpr_save

gpr_save:
    .fill 5*(XLEN/32),4,0xdeadbeef

#endif

RVMODEL_DATA_END