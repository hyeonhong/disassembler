*----------------------------------------------------------------------------------------------------
* Title      : I/O & Op-Code & EA
* Written by : Team Bazinga
* Date       : 12/14/2016
* Description: -------------------------------------------------------------------------------k
*----------------------------------------------------------------------------------------------------

*D6 and A6 is set, prior to calling this Macro
val_check   MACRO
            MOVE.L      #$FF000000,D5
            MOVE.L      #24,D7
            CLR.L       D4
val_loop\@  MOVE.L      D6,D1               *D6 holds the original hex-value
            AND.L       D5,D1
            LSR.L       D7,D1               *shift bits to the right

            CMPI.B      #$30,D1             * D1 < $30 (0 in hex)
            BLT         invalid
            CMPI.B      #$66,D1             * D1 > $66 (f in hex)
            BGT         invalid
            CMPI.B      #$61,D1             * D1 >= $61 (a in hex)
            BGE         lowercase\@
            CMPI.B      #$46,D1             * D1 > $46 (F in hex)
            BGT         invalid
            CMPI.B      #$39,D1             * D1 <= $39 (9 in hex)
            BLE         passed\@
            CMPI.B      #$41,D1             * D1 < $41  (A in hex)
            BLT         invalid
lowercase\@ CMPI.B      #$46,D1
            BLE         passed\@
            SUBI.B      #$20,D1
passed\@    CMPI.B      #$39,D1
            BLE         to_hex\@
            SUBI.B      #$7,D1
to_hex\@    SUBI.B      #$30,D1
            ADDQ.B      #1,D4
            ANDI.L      #$00000001,D4
            CMPI.B      #0,D4               *Is D4 even or odd?
            BEQ         even_num\@
            MOVE.B      D1,D2
            BRA         hex_next\@
even_num\@  LSL.B       #4,D2
            MOVE.B      D1,D3
            OR.B        D2,D3
            MOVE.B      D3,(A6)+            *A6 is set up as the pointer to which data will be written
hex_next\@  LSR.L       #8,D5
            SUBQ.B      #8,D7
            CMPI.B      #0,D7
            BGE         val_loop\@
            ENDM


*convert reg_digits to ascii-hex and write to the buffer
xreg2ascii  MACRO
            MOVE.B      #$44,(A1)+          *write the ascii-hex value of 'D' into the buffer
            MOVE.W      D0,D1
            ANDI.W      #%0000111000000000,D1
            LSR.W       #8,D1
            LSR.W       #1,D1
            ADDI.B      #$30,D1
            MOVE.B      D1,(A1)+            *write the ascii-hex value into the buffer
            ENDM

yreg2ascii  MACRO
            MOVE.B      #$44,(A1)+          *write the ascii-hex value of 'D' into the buffer
            MOVE.W      D0,D1
            ANDI.W      #%0000000000000111,D1
            ADDI.B      #$30,D1
            MOVE.B      D1,(A1)+            *write the ascii-hex value into the buffer
            ENDM
            
oreg2ascii  MACRO
            MOVE.W      D0,D1
            ANDI.W      #%0000111000000000,D1
            LSR.W       #8,D1
            LSR.W       #1,D1
            ADDI.B      #$30,D1
            MOVE.B      D1,(A1)+            *write the ascii-hex value into the buffer
            ENDM

add2ascii   MACRO
            MOVE.W      #$F000,D5
            MOVE.L      #12,D7
ad2ascii\@  MOVE.W      D6,D1               *D6 holds the original hex-value
            AND.W       D5,D1
            LSR.W       D7,D1               *shift 12 bits to the right
            CMPI.W      #9,D1
            BLE         adnumbers\@
            ADDI.W      #$7,D1
adnumbers\@ ADDI.W      #$30,D1
            MOVE.B      D1,(A1)+          *write the ascii-hex equivalent of hex-character to the buffer
            LSR.W       #4,D5
            SUBQ.B      #4,D7
            CMPI.B      #0,D7
            BGE         ad2ascii\@
            ENDM

*convert D1.W (hex-value) to the ascii-hex in D6 and write it into the buffer
w_2ascii    MACRO
            MOVE.W      #$F000,D4           *D4 - ANDING pattern
            MOVE.L      #12,D7
ascii_w\@   MOVE.W      D1,D6
            AND.W       D4,D6
            LSR.W       D7,D6               *shift bits to the right
            CMPI.W      #9,D6
            BLE         numbers_w\@
            ADDI.B      #$7,D6
numbers_w\@ ADDI.B      #$30,D6
            MOVE.B      D6,(A1)+          *write the ascii-hex equivalent of hex-value to the buffer
            LSR.W       #4,D4
            SUBQ.B      #4,D7
            CMPI.B      #0,D7
            BGE         ascii_w\@
            ENDM
            
*convert D1.L (hex-value) to the ascii-hex and write into the buffer
l_2ascii    MACRO
            MOVE.L      #$F0000000,D4       *D4 - ANDING pattern
            MOVE.L      #28,D7
ascii_l\@   MOVE.L      D1,D6
            AND.L       D4,D6
            LSR.L       D7,D6               *shift bits to the right
            CMPI.B      #9,D6
            BLE         numbers_l\@
            ADDI.B      #$7,D6
numbers_l\@ ADDI.B      #$30,D6
            MOVE.B      D6,(A1)+          *write the ascii-hex equivalent of hex-value to the buffer
            LSR.L       #4,D4
            SUBQ.B      #4,D7
            CMPI.B      #0,D7
            BGE         ascii_l\@
            ENDM


parsing_1   MACRO
            MOVE.B      (A0)+,D0
            MOVE.B      D0,D1               *D1 - register #
            MOVE.B      D0,D5               *D5 - mode
            ANDI.B      #%00111000,D5
            LSR.B       #3,D5
            ANDI.B      #%00000111,D1
            MOVE.B      D5,D3               *D3 - back-up
            MOVE.B      D1,D4               *D4 - back-up

            CMPI.B      #7,D5
            BNE         ea_check\@
            ADD.B       D1,D5
            ADDA.W      (A6),A5             *add displacement to the beginning of table
ea_check\@  MOVE.B      (A5)+,D1
            CMP.B       D5,D1
            BEQ         set_as_bad
            CMPI.B      #15,D1
            BNE         ea_check\@
                     
            MOVE.B      D3,D5               *Restore the value from back-up
            MOVE.B      D4,D1               *Restore the value from back-up
            ADDA.W      (A2),A0             *add jump_flag flag value to the memory pointer
            ENDM
            
parsing_2   MACRO
            MOVE.W      D0,D1
            ANDI.W      #%0000111000000000,D1
            LSR.W       #8,D1
            LSR.W       #1,D1
            MOVE.W      D0,D2
            ANDI.W      #%0000000111000000,D2
            LSR.W       #6,D2
            MOVE.W      D0,D3
            ANDI.W      #%0000000000111000,D3
            LSR.W       #3,D3
            MOVE.W      D0,D4
            ANDI.W      #%0000000000000111,D4
            ENDM



pgm_start   EQU         $1000               *Program runs here
stack       EQU         $A0000              *Put stack here

        
            ORG         pgm_start           *Program Origin
            LEA         stack, SP           *Initialize the stack pointer
            LEA         which_add,A5
            


beginning   BSR         io_code             *Take the input for starting address
            MOVE.B      #1,(A5)             *change the value of which_add to 1 - which indicates the end address
            BSR         io_code             *Take the input for ending address
            MOVE.B      #0,(A5)             *Reset the value

            LEA         newline,A1
            MOVE.B      #13,D0
            TRAP        #15            
            
            *assign the start & end address to A0 & A4                        
            LEA         start_addr,A4
            MOVE.L     (A4),D0
            MOVEA.L     D0,A5            
            LEA         (A5),A0             *A0 - start address
            LEA         end_addr,A5
            MOVE.L     (A5),D0
            MOVEA.L     D0,A6
            LEA         (A6),A4             *A4 - end address

            LEA         buffer,A1           *A1 - pointer to the buffer
            CLR.L       D2                  *D2 - counter for page break

op_loop     BSR         op_code
            *print to console
            LEA         buffer,A1           *Reset the buffer pointer
            MOVE.B      #13,D0
            TRAP        #15
            
            ADDQ.B      #1,D2
            *D2 MOD 25
            DIVU        #25,D2
            SWAP        D2                  *move the remainder to the lower-end of D2
            ANDI.L      #$00FF,D2           *clean up the upper-end of D2

            CMPI.B      #0,D2               *Is D2 zero or not?
            BNE         check_add

enter2con   LEA         string8,A1
            MOVE.B      #14,D0
            TRAP        #15

            LEA         reader,A1
            MOVE.B      #2,D0
            TRAP        #15
            
            CMPI.W      #0,D1
            BNE         enter2con
            
check_add   CMPA.L      A0,A4
            BGT         op_loop

            LEA         newline,A1
            MOVE.B      #13,D0
            TRAP        #15
            
            LEA         string9,A1
            MOVE.B      #13,D0
            TRAP        #15

            LEA         newline,A1
            MOVE.B      #13,D0
            TRAP        #15
            
read_again  LEA         string10,A1
            MOVE.B      #14,D0
            TRAP        #15
            
            LEA         reader,A1
            MOVE.B      #2,D0
            TRAP        #15
            
            CMPI.W      #0,D1
            BEQ         beginning
            CMPI.W      #1,D1
            BNE         read_again
            MOVE.B      (A1),D7
            CMPI.B      #$71,D7
            BEQ         the_end
            CMPI.B      #$51,D7
            BNE         read_again            

the_end     MOVE.B      #9,D0               *halt console simulator
            TRAP        #15
            STOP        #$2700


            

*****************************************************************************************************
* Subroutine I/O Code


            
io_code     MOVEM.L     A0-A6/D0-D7,-(SP)   *Save the working registers on stack
            LEA         which_add,A5

ask_start   CMPI.B      #0,(A5)
            BNE         end_chosen1
            LEA         string1,A1          *start address chosen
            BRA         ask_next
end_chosen1 LEA         string2,A1          *end address chosen
ask_next    MOVE.B      #14,D0
            TRAP        #15
            LEA         reader,A1
            MOVE.B      #2,D0
            TRAP        #15

            CMPI.W      #8,D1
            BLT         too_short                   * if ( D1 < 8) length is too short
            BGT         too_long                    * if ( D1 > 8) length is too long

            * validity check + conversion to hex + writing to memory variable (start_addr & end_addr)
val_start   LEA         reader,A2
            CMPI.B      #0,(A5)
            BNE         end_chosen2
            LEA         start_addr,A6       *start address chosen
            BRA         val_next
end_chosen2 LEA         end_addr,A6         *end address chosen
val_next    MOVE.L      (A2)+,D2            * temporarily hold the ascii-hex value in D2
            MOVE.L      D2,D6
            val_check
            MOVE.L      (A2)+,D2
            MOVE.L      D2,D6
            val_check
            
            * even boundary check and converting the address to even number
            CMPI.B      #0,(A5)
            BNE         end_chosen3
            LEA         start_addr,A6       *start address chosen
            BRA         bound_next
end_chosen3 LEA         end_addr,A6         *end address chosen
bound_next  MOVE.L      (A6),D7
            ANDI.L      #$00000001,D7       *Is it even or not?
            CMPI.B      #0,D7
            BEQ         range_check
            CMPI.B      #0,(A5)             *if it's end address, move to range check
            BNE         range_check            
            SUBI.L      #1,(A6)             *convert the address to even number
            LEA         string6,A1
            MOVE.B      #13,D0
            TRAP        #15

            * memory range check
range_check MOVE.L      (A6),D7
            ANDI.L      #$11000000,D7
            CMPI.L      #0,D7
            BNE         out_of_rang

            *legality check - end address should be greater or equal to start address
legal_check CMPI.B      #0,(A5)
            BEQ         exit_io
            LEA         start_addr,A6
            MOVE.L      (A6),D2
            LEA         end_addr,A6
            MOVE.L      (A6),D3
            SUB.L       D2,D3
            BMI         illegal

exit_io     MOVEM.L     (SP)+, A0-A6/D0-D7  *Restore the working registers from stack
            RTS
            
            

too_short   CMPI.W      #0,D1
            BEQ         ask_start
            LEA         reader,A2
            LEA         reader2,A3
            MOVE.L      #8,D2
            SUB.W       D1,D2
            CLR.L       D3                  *counter for 0 adder
z_adder     MOVE.B      #$30,(A3)+          *write the ascii-hex value of '0' into the reader2
            ADDQ.B      #1,D3
            CMP.W       D2,D3
            BLT         z_adder
            CLR.L       D3                  *counter for r_copy
r_copy      MOVE.B      (A2)+,(A3)+         *write the contents of reader into the reader2
            ADDQ.B      #1,D3
            CMP.W       D1,D3
            BLT         r_copy

            *copy the contents in reader2 to reader
            LEA         reader,A2
            LEA         reader2,A3
            MOVE.L      (A3)+,(A2)+         *copy 2 Long words
            MOVE.L      (A3)+,(A2)+
            BRA         val_start


too_long    LEA         string3,A1
            MOVE.B      #13,D0
            TRAP        #15
            BRA         ask_start
invalid     LEA         string4,A1
            MOVE.B      #13,D0
            TRAP        #15
            BRA         ask_start
out_of_rang LEA         string5,A1
            MOVE.B      #13,D0
            TRAP        #15
            BRA         ask_start
illegal     LEA         string7,A1
            MOVE.B      #13,D0
            TRAP        #15
            BRA         ask_start

****************************************************************************            




*****************************************************************************************************
* Subroutine Op-Code

op_code     MOVEM.L     A2-A6/D0-D7,-(SP)   *Save the working registers on stack
            LEA         case_1,A6           *Set up A6 as the pointer to the instruction table
            LEA         case_2,A5
            LEA         jump_flag,A4
            MOVE.L      #$20202020,(A1)+    *write '    ' of ascii-hex into the buffer
            MOVE.L      A0,D0
            MOVE.L      D0,D6               *D6 holds the original hex-value and will be used in the below MACRO
            LSR.L       #8,D6
            LSR.L       #8,D6
            add2ascii
            MOVE.W      D0,D6               *D6 holds the original hex-value and will be used in the below MACRO
            add2ascii
            MOVE.L      #$20202020,(A1)+    *write '    ' of ascii-hex into the buffer


            MOVE.W      (A0)+,D0
loop_1      CMP.W       (A6),D0
            BEQ         to_buffer_1
            ADDA.L      #16,A6              *Move to next row
            CMPA.L      A5,A6
            BNE         loop_1
loop_2      MOVE.W      D0,D1               *To modify the value, copy D0 to D1
            ANDI.W      #%1111111111111000,D1
            CMP.W       (A6),D1
            BEQ         to_buffer_2
            ADDA.L      #16,A6              *Move to next row
loop_3      LEA         case_4,A5
            MOVE.W      D0,D1
            ANDI.W      #%1111111111000000,D1
            CMP.W       (A6),D1
            BEQ         to_buffer_3
            ADDA.L      #16,A6              *Move to next row
            CMPA.L      A5,A6
            BNE         loop_3
loop_4      LEA         case_5,A5
            MOVE.W      D0,D1
            ANDI.W      #%1111000111000000,D1
            CMP.W       (A6),D1
            BEQ         to_buffer_4
            ADDA.L      #16,A6              *Move to next row
            CMPA.L      A5,A6
            BNE         loop_4            
loop_5      MOVE.W      D0,D1
            ANDI.W      #%1111111100000000,D1
            CMP.W       (A6),D1
            BEQ         to_buffer_5
            ADDA.L      #16,A6              *Move to next row
loop_6      LEA         case_7,A5
            MOVE.W      D0,D1
            ANDI.W      #%1111000111111000,D1
            CMP.W       (A6),D1
            BEQ         to_buffer_6
            ADDA.L      #16,A6              *Move to next row
            CMPA.L      A5,A6
            BNE         loop_6
loop_7      LEA         null,A5
            MOVE.W      D0,D1
            ANDI.W      #%1111000000000000,D1
            CMP.W       (A6),D1
            BEQ         to_buffer_7
            ADDA.L      #16,A6              *Move to next row
            CMPA.L      A5,A6
            BNE         loop_7
data_xxxx   MOVE.L      #$44415441,(A1)+    *write 'DATA' of ascii-hex into the buffer
            MOVE.L      #$20202020,(A1)+    *write '    ' of ascii-hex into the buffer
            MOVE.W      D0,D6               *D6 holds the original hex-value and will be used in the below MACRO
            add2ascii
            BRA         exit_op

                  
to_buffer_1 ADDA.L      #2,A6               *Move 1 column to the right
            MOVE.L      (A6)+,(A1)+         *Write two long words to the buffer
            MOVE.L      (A6)+,(A1)+
            BRA         exit_op

to_buffer_2 ADDA.L      #2,A6               *Move 1 column to the right
            MOVE.L      (A6)+,(A1)+         *Write two long words that contain ascii values to the buffer
            MOVE.L      (A6)+,(A1)+
            xreg2ascii
            BRA         exit_op            

to_buffer_3 ADDA.L      #2,A6               *Move 1 column to the right
            MOVEA.L     A0,A2               *Save A0 to A2 as a back-up
            MOVE.L      (A6)+,(A1)+         *Write two long words that contain ascii values to the buffer
            MOVE.L      (A6)+,(A1)+
            MOVE.W      (A6)+,D2            *D2 holds the syntax pattern number
            MOVE.W      (A6)+,D3            *D3 temporarily holds the imme_flag value
            LEA         dis_table,A3        *displacement of first column for each instruction in ea_table
            MOVE.W      (A6),(A3)
            CMPI.W      #0,D3
            BEQ         skip_imme_1
            LEA         imme_flag,A3
            MOVE.W      D3,(A3)
skip_imme_1 CMPI.W      #$0000,D2
            BNE         next_3_1
            * 0000 case - <ea>
            MOVEA.L     A2,A0               *Restore to the end point of memory instruction
            SUBA.L      #1,A0               *move back 1 byte the pointer to memory to decode
            MOVE.W      #$0000,(A4)         *jump_flag - 0000
            JSR         e_a
            BRA         exit_op
            
next_3_1    CMPI.W      #$0001,D2
            BNE         next_3_2
            * 0001 case - (.B) #$<hex-value>, <ea>
            MOVE.W      #$2324,(A1)+        *write '#$' of ascii-hex into the buffer
            MOVE.W      (A0)+,D1            *read the immediate value from the memory
            w_2ascii
            
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer            
            MOVEA.L     A2,A0               *Restore to the end point of memory instruction
            SUBA.L      #1,A0               *move back 1 byte the pointer to memory to decode
            MOVE.W      #$0002,(A4)         *jump_flag - 0002
            JSR         e_a
            BRA         exit_op

next_3_2    CMPI.W      #$0002,D2
            BNE         next_3_3
            * 0002 case - (.W) #$<hex-value>, <ea>
            MOVE.W      #$2324,(A1)+        *write '#$' of ascii-hex into the buffer
            MOVE.W      (A0)+,D1            *read the immediate value from the memory
            w_2ascii
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            MOVEA.L     A2,A0               *Restore to the end point of memory instruction
            SUBA.L      #1,A0               *move back 1 byte the pointer to memory to decode
            MOVE.W      #$0002,(A4)         *jump_flag - 0002
            JSR         e_a
            BRA         exit_op

next_3_3    CMPI.W      #$0003,D2
            BNE         next_3_4
            * 0003 case - (.L) #$<hex-value>, <ea>
            MOVE.W      #$2324,(A1)+        *write '#$' of ascii-hex into the buffer
            MOVE.L      (A0)+,D1            *read the immediate value from the memory
            l_2ascii
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            MOVEA.L     A2,A0               *Restore to the end point of memory instruction
            SUBA.L      #1,A0               *move back 1 byte the pointer to memory to decode
            MOVE.W      #$0004,(A4)         *jump_flag - 0004
            JSR         e_a
            BRA         exit_op

            
next_3_4    CMPI.W      #$0004,D2
            BNE         next_3_5
            * 0004 case - <register list>, <ea>
            CLR.L       D4                  *D4 holds the counter for mask_loop
            MOVE.W      (A0),D3             *D3 holds the register list mask
            MOVE.W      D0,D1
            ANDI.W      #%0000000000111000,D1
            LSR.W       #3,D1
            CMP.B       #%100,D1            *Is it the predecrement addressing mode?
            BNE         not_pre
            *reverse mask list case
            MOVE.W      #%1000000000000000,D6
            MOVE.L      #1,D7               *D7 - bit shift number
r_mask_loop MOVE.W      D3,D1
            AND.W       D6,D1
            ROL.W       D7,D1
            CMPI.W      #0,D1
            BEQ         r_mask_next
            MOVE.L      D4,D5
            CMPI.B      #7,D5
            BGT         r_write_a         
            MOVE.B      #$44,(A1)+          *write the ascii-hex value of 'D' into the buffer
            BRA         r_write_num
r_write_a   MOVE.B      #$41,(A1)+          *write the ascii-hex value of 'A' into the buffer
            SUBI.B      #8,D5
r_write_num ADDI.B      #$30,D5
            MOVE.B      D5,(A1)+            *write the ascii-hex value into the buffer
            MOVE.W      #$2F20,(A1)+        *write '/' and ' ' (space) of ascii-hex into the buffer            
r_mask_next ROR.W       #1,D6
            ADDQ.B      #1,D4
            ADDQ.B      #1,D7
            CMPI.B      #16,D4
            BNE         r_mask_loop
            SUBA.L      #2,A1               *delete the last '/' and ' ' (space) from the buffer
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            MOVEA.L     A2,A0               *Restore to the end point of memory instruction
            SUBA.L      #1,A0               *move back 1 byte the pointer to memory to decode
            MOVE.W      #$0002,(A4)         *jump_flag - 0002
            JSR         e_a
            BRA         exit_op

not_pre     MOVE.W      #%0000000000000001,D6
            CLR.L       D7                  *D7 - bit shift number
mask_loop_1 MOVE.W      D3,D1
            AND.W       D6,D1
            LSR.W       D7,D1
            CMPI.W      #0,D1
            BEQ         mask_next_1
            MOVE.L      D4,D5               *D5 - temporary variable that stores the counter value
            CMPI.B      #7,D5
            BGT         write_a_1       
            MOVE.B      #$44,(A1)+          *write the ascii-hex value of 'D' into the buffer
            BRA         write_num_1
write_a_1   MOVE.B      #$41,(A1)+          *write the ascii-hex value of 'A' into the buffer
            SUBI.B      #8,D5
write_num_1 ADDI.B      #$30,D5
            MOVE.B      D5,(A1)+            *write the ascii-hex value into the buffer
            MOVE.W      #$2F20,(A1)+        *write '/' and ' ' (space) of ascii-hex into the buffer            
mask_next_1 ROL.W       #1,D6
            ADDQ.B      #1,D4
            ADDQ.B      #1,D7
            CMPI.B      #16,D4
            BNE         mask_loop_1
            SUBA.L      #2,A1               *delete the last '/' and ' ' (space) from the buffer
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            MOVEA.L     A2,A0               *Restore to the end point of memory instruction
            SUBA.L      #1,A0               *move back 1 byte the pointer to memory to decode
            MOVE.W      #$0002,(A4)         *jump_flag - 0002
            JSR         e_a
            BRA         exit_op


            * 0005 case - <ea>, <register list>
next_3_5    MOVEA.L     A2,A0               *Restore to the end point of memory instruction
            SUBA.L      #1,A0               *move back 1 byte the pointer to memory to decode
            MOVE.W      #$0002,(A4)         *jump_flag - 0002
            JSR         e_a
            *check for the bad_flag
            LEA         bad_flag,A3
            CMPI.W      #0,(A3)
            BNE         exit_op
            
            MOVEA.L     A0,A3               *Save A0 to A3 as a back-up (which is the starting point for next instruction)
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            
            MOVEA.L     A2,A0               *Restore to the end point of memory instruction
            CLR.L       D4                  *D4 holds the counter for mask_loop
            MOVE.W      (A0),D3             *D3 holds the register list mask
            MOVE.W      #%0000000000000001,D6
            CLR.L       D7                  *D7 - bit shift number
mask_loop_2 MOVE.W      D3,D1
            AND.W       D6,D1
            LSR.W       D7,D1
            CMPI.W      #0,D1
            BEQ         mask_next_2
            MOVE.L      D4,D5               *D5 - temporary variable that stores the counter value
            CMPI.B      #7,D5
            BGT         write_a_2        
            MOVE.B      #$44,(A1)+          *write the ascii-hex value of 'D' into the buffer
            BRA         write_num_2
write_a_2   MOVE.B      #$41,(A1)+          *write the ascii-hex value of 'A' into the buffer
            SUBI.B      #8,D5
write_num_2 ADDI.B      #$30,D5
            MOVE.B      D5,(A1)+            *write the ascii-hex value into the buffer
            MOVE.W      #$2F20,(A1)+        *write '/' and ' ' (space) of ascii-hex into the buffer            
mask_next_2 ROL.W       #1,D6
            ADDQ.B      #1,D4
            ADDQ.B      #1,D7
            CMPI.B      #16,D4
            BNE         mask_loop_2
            SUBA.L      #2,A1               *delete the last '/' and ' ' (space) from the buffer            
            MOVEA.L     A3,A0               *Restore to the starting point of the next instruction
            BRA         exit_op



to_buffer_4 ADDA.L      #2,A6               *Move 1 column to the right
            MOVEA.L     A0,A2               *Save A0 to A2 as a back-up
            MOVE.L      (A6)+,(A1)+         *Write two long words that contain ascii values to the buffer
            MOVE.L      (A6)+,(A1)+
            MOVE.W      (A6)+,D2            *D2 holds the syntax pattern number
            MOVE.W      (A6)+,D3            *D3 temporarily holds the imme_flag value
            LEA         dis_table,A3        *displacement of first column for each instruction in ea_table
            MOVE.W      (A6),(A3)
            CMPI.W      #0,D3
            BEQ         skip_imme_2
            LEA         imme_flag,A3
            MOVE.W      D3,(A3)
skip_imme_2 CMPI.W      #$0000,D2
            BNE         next_4_1
            * 0000 case - <ea>, Dn
            MOVEA.L     A2,A0               *Restore to the end point of memory instruction
            SUBA.L      #1,A0               *move back 1 byte the pointer to memory to decode
            MOVE.W      #$0000,(A4)         *jump_flag - 0000
            JSR         e_a
            *check for the bad_flag
            LEA         bad_flag,A3
            CMPI.W      #0,(A3)
            BNE         exit_op
            
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            xreg2ascii
            BRA         exit_op
            
next_4_1    CMPI.W      #$0001,D2
            BNE         next_4_2
            * 0001 case - Dn, <ea>
            xreg2ascii
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            MOVEA.L     A2,A0               *Restore to the end point of memory instruction
            SUBA.L      #1,A0               *move back 1 byte the pointer to memory to decode
            MOVE.W      #$0000,(A4)         *jump_flag - 0000
            JSR         e_a                 *call e_a subroutine to fill the e.a. into the buffer
            BRA         exit_op
            
            * 0002 case - <ea>, An
next_4_2    MOVEA.L     A2,A0               *Restore to the end point of memory instruction
            SUBA.L      #1,A0               *move back 1 byte the pointer to memory to decode
            MOVE.W      #$0000,(A4)         *jump_flag - 0000
            JSR         e_a
            *check for the bad_flag
            LEA         bad_flag,A3
            CMPI.W      #0,(A3)
            BNE         exit_op
            
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            MOVE.B      #$41,(A1)+          *write the ascii-hex value of 'A' into the buffer            
            oreg2ascii
            BRA         exit_op


to_buffer_5 ADDA.L      #2,A6               *Move 1 column to the right
            MOVEA.L     A0,A2               *Save A0 to A2 as a back-up
            MOVE.L      (A6)+,(A1)+         *Write two long words that contain ascii values to the buffer
            MOVE.L      (A6)+,(A1)+
            MOVE.W      (A6)+,D2            *D2 holds the syntax pattern number
            MOVE.W      (A6)+,D3            *D3 temporarily holds the imme_flag value
            LEA         dis_table,A3        *displacement of first column for each instruction in ea_table
            MOVE.W      (A6),(A3)
            CMPI.W      #0,D3
            BEQ         skip_imme_3
            LEA         imme_flag,A3
            MOVE.W      D3,(A3)
skip_imme_3 CLR.L       D3
            CMPI.B      #$FF,D2
            BNE         next_5_1
            * #$FF case - 32 bit displacement
            ADDA.L      #2,A0
            MOVE.L      A0,D4               *D4 holds the address right before the displacement
            MOVE.L      (A0)+,D3            *D3 holds the displacement
            ADD.L       D3,D4               *D4 holds the memory address to branch to
            MOVE.L      D4,D6               *D6 holds the original hex-value and will be used in the below MACRO
            LSR.L       #8,D6
            LSR.L       #8,D6
            add2ascii
            MOVE.W      D4,D6               *D6 holds the original hex-value and will be used in the below MACRO
            add2ascii
            BRA         exit_op

next_5_1    CMPI.B      #$00,D2
            BNE         next_5_2
            * #$00 case - 16 bit displacement
            MOVE.L      A0,D4               *D4 holds the address right before the displacement
            MOVE.W      (A0)+,D3            *D3 holds the displacement
            ADD.W       D3,D4               *D4 holds the memory address to branch to
            MOVE.L      D4,D6               *D6 holds the original hex-value and will be used in the below MACRO
            LSR.L       #8,D6
            LSR.L       #8,D6
            add2ascii
            MOVE.W      D4,D6               *D6 holds the original hex-value and will be used in the below MACRO
            add2ascii
            BRA         exit_op
                        
            * case - 8 bit displacement
next_5_2    MOVE.L      A0,D4               *D4 holds the address right before the displacement
            MOVE.B      D2,D3               *D3 holds the displacement
            ADD.B       D3,D4               *D4 holds the memory address to branch to
            MOVE.L      D4,D6               *D6 holds the original hex-value and will be used in the below MACRO
            LSR.L       #8,D6
            LSR.L       #8,D6
            add2ascii
            MOVE.W      D4,D6               *D6 holds the original hex-value and will be used in the below MACRO
            add2ascii
            BRA         exit_op

to_buffer_6 ADDA.L      #2,A6               *Move 1 column to the right
            MOVEA.L     A0,A2               *Save A0 to A2 as a back-up
            MOVE.L      (A6)+,(A1)+         *Write two long words that contain ascii values to the buffer
            MOVE.L      (A6)+,(A1)+
            MOVE.W      (A6)+,D2            *D2 holds the syntax pattern number
            MOVE.W      (A6)+,D3            *D3 temporarily holds the imme_flag value
            LEA         dis_table,A3        *displacement of first column for each instruction in ea_table
            MOVE.W      (A6),(A3)
            CMPI.W      #0,D3
            BEQ         skip_imme_4
            LEA         imme_flag,A3
            MOVE.W      D3,(A3)
skip_imme_4 CMPI.W      #$0000,D2
            BNE         next_6_1
            * 0000 case - (I) # <decimal>, Dy
            MOVE.B      #$23,(A1)+        *write '#' of ascii-hex into the buffer

            MOVE.W      D0,D1
            ANDI.W      #%0000111000000000,D1
            LSR.W       #8,D1
            LSR.W       #1,D1
            ADDI.B      #$30,D1
            CMPI.B      #$30,D1
            BNE         one2seven
            ADDI.B      #$8,D1
one2seven   MOVE.B      D1,(A1)+            *write the ascii-hex value into the buffer

            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            yreg2ascii
            BRA         exit_op
            
next_6_1    CMPI.W      #$0001,D2
            BNE         next_6_2
            * 0001 case - (R) Dx, Dy
            xreg2ascii
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            yreg2ascii
            BRA         exit_op

next_6_2    CMPI.W      #$0002,D2
            BNE         next_6_3
            * 0002 case - Dx, Dy
            MOVE.B      #$44,(A1)+          *write the ascii-hex value of 'D' into the buffer
            oreg2ascii
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            MOVE.B      #$44,(A1)+          *write the ascii-hex value of 'D' into the buffer
            oreg2ascii
            BRA         exit_op
            
next_6_3    CMPI.W      #$0003,D2
            BNE         next_6_4
            * 0003 case - Ax, Ay
            MOVE.B      #$41,(A1)+          *write the ascii-hex value of 'A' into the buffer
            oreg2ascii
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            MOVE.B      #$41,(A1)+          *write the ascii-hex value of 'A' into the buffer
            oreg2ascii
            BRA         exit_op

            * 0004 case - Dx, Ay
next_6_4    MOVE.B      #$44,(A1)+          *write the ascii-hex value of 'D' into the buffer
            oreg2ascii
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            MOVE.B      #$41,(A1)+          *write the ascii-hex value of 'A' into the buffer
            oreg2ascii
            BRA         exit_op


to_buffer_7 ADDA.L      #2,A6               *Move 1 column to the right
            MOVEA.L     A0,A2               *Save A0 to A2 as a back-up
            MOVE.L      (A6)+,(A1)+         *Write two long words that contain ascii values to the buffer
            MOVE.L      (A6)+,(A1)+
            MOVE.W      (A6)+,D2            *D2 holds the syntax pattern number
            MOVE.W      (A6)+,D3            *D3 temporarily holds the imme_flag value
            LEA         dis_table,A3        *displacement of first column for each instruction in ea_table
            MOVE.W      (A6),(A3)
            CMPI.W      #0,D3
            BEQ         skip_imme_5
            LEA         imme_flag,A3
            MOVE.W      D3,(A3)
skip_imme_5 CMPI.W      #$0000,D2
            BNE         next_7_1
            * 0000 case - (.B)
            MOVEA.L     A2,A0               *Restore to the end point of memory instruction
            SUBA.L      #2,A0               *move back 2 byte the pointer to memory to decode
            MOVE.W      #$0005,(A4)         *jump_flag - 0005
            JSR         e_a
            BRA         exit_op

next_7_1    CMPI.W      #$0001,D2
            BNE         next_7_2
            * 0001 case - (.W)
            MOVEA.L     A2,A0               *Restore to the end point of memory instruction
            SUBA.L      #2,A0               *move back 2 byte the pointer to memory to decode
            MOVE.W      #$0006,(A4)         *jump_flag - 0006
            JSR         e_a
            BRA         exit_op
            
            * 0002 case - (.L)
next_7_2    MOVEA.L     A2,A0               *Restore to the end point of memory instruction
            SUBA.L      #2,A0               *move back 2 byte the pointer to memory to decode
            MOVE.W      #$0007,(A4)         *jump_flag - 0007
            JSR         e_a
            BRA         exit_op


            *check for the bad_flag
exit_op     LEA         bad_flag,A2
            CMPI.W      #0,(A2)
            BEQ         good_data
            MOVE.W      #0,(A2)             *reset the bag_flag
            LEA         buffer,A1
            ADDA.L      #16,A1              *adjust the buffer pointer
            BRA         data_xxxx            
good_data   MOVE.W      #$0000,(A1)+        *write '0'(null) of ascii-hex into the buffer
            MOVEM.L     (SP)+, A2-A6/D0-D7  *Restore the working registers from stack
            RTS                             *Return to the program



***************************************************************************************************
* Subroutine EA



e_a         MOVEM.L     A2-A6/D0-D7,-(SP)
            LEA         jump_flag,A2
            LEA         bad_flag,A4
            LEA         ea_table,A5
            LEA         dis_table,A6
            MOVE.W      (A2),D2

            CMPI.W      #4,D2               *is it MOVE instruction or not?
            BGT         ea_move
            parsing_1            
            BRA         ea2buffer
ea_move     MOVE.W      (A0)+,D0            *done only once and stored in D0
            parsing_2
            MOVE.W      D3,D5
            MOVE.W      D4,D1
            LEA         move_flag,A3
            MOVE.W      #1,(A3)
            BRA         ea2buffer
ea_move_d   MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            parsing_2
            MOVE.W      D1,D4
            MOVE.W      D2,D3
            MOVE.W      D2,D5
            LEA         move_flag,A3
            MOVE.W      #0,(A3)
            BRA         ea2buffer
            
set_as_bad  MOVE.W      #1,(A4)
            BRA         ea_exit_2
            
ea_exit     LEA         move_flag,A3
            CMPI.W      #0,(A3)
            BNE         ea_move_d
ea_exit_2   MOVEM.L     (SP)+, A2-A6/D0-D7
            RTS

ea2buffer   CMPI.W      #%000,D5
            BNE         ea2b_1
            MOVE.B      #$44,(A1)+          *write the ascii-hex value of 'D' into the buffer
            ADDI.B      #$30,D1
            MOVE.B      D1,(A1)+            *write the ascii-hex value of '0~7' into the buffer
            BRA         ea_exit
ea2b_1      CMPI.W      #%001,D5
            BNE         ea2b_2
            MOVE.B      #$41,(A1)+          *write the ascii-hex value of 'A' into the buffer
            ADDI.B      #$30,D1
            MOVE.B      D1,(A1)+            *write the ascii-hex value of '0~7' into the buffer
            BRA         ea_exit
ea2b_2      CMPI.W      #%010,D5
            BNE         ea2b_3            
            MOVE.W      #$2841,(A1)+        *write the ascii-hex value of '(' and 'A' into the buffer
            ADDI.B      #$30,D1
            MOVE.B      D1,(A1)+            *write the ascii-hex value of '0~7' into the buffer            
            MOVE.B      #$29,(A1)+          *write the ascii-hex value of ')' into the buffer
            BRA         ea_exit
ea2b_3      CMPI.W      #%011,D5
            BNE         ea2b_4            
            MOVE.W      #$2841,(A1)+        *write the ascii-hex value of '(' and 'A' into the buffer
            ADDI.B      #$30,D1
            MOVE.B      D1,(A1)+            *write the ascii-hex value of '0~7' into the buffer            
            MOVE.B      #$29,(A1)+          *write the ascii-hex value of ')' into the buffer
            MOVE.W      #$2B20,(A1)+        *write the ascii-hex value of '+' and ' ' into the buffer
            BRA         ea_exit
ea2b_4      CMPI.W      #%100,D5
            BNE         ea2b_5
            MOVE.W      #$202D,(A1)+        *write the ascii-hex value of ' ' and '-' into the buffer
            MOVE.W      #$2841,(A1)+        *write the ascii-hex value of '(' and 'A' into the buffer
            ADDI.B      #$30,D1
            MOVE.B      D1,(A1)+            *write the ascii-hex value of '0~7' into the buffer            
            MOVE.B      #$29,(A1)+          *write the ascii-hex value of ')' into the buffer
            BRA         ea_exit
ea2b_5      CMPI.W      #%101,D5
            BNE         ea2b_6
            MOVE.W      #$2028,(A1)+        *write the ascii-hex value of ' ' and '(' into the buffer

            MOVE.W      (A0)+,D7
            
            MOVE.W      D7,D6
            ANDI.W      #$8000,D6
            CMPI.W      #0,D6
            BEQ         no_signbit1
            MOVE.W      #$2D24,(A1)+          *write the ascii-hex value of '-$' into the buffer
            BRA         numberbit1
no_signbit1 MOVE.W      #$2B24,(A1)+          *write the ascii-hex value of '+$' into the buffer
numberbit1  MOVE.W      D7,D6
            ANDI.W      #$7FFF,D6
            add2ascii
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer            

            MOVE.B      #$41,(A1)+          *write the ascii-hex value of 'A' into the buffer
            MOVE.B      D3,D1               *Restore the back-up to D1
            ADDI.B      #$30,D1
            MOVE.B      D1,(A1)+            *write the ascii-hex value of '0~7' into the buffer            
            MOVE.W      #$2920,(A1)+          *write the ascii-hex value of ')' and ' ' into the buffer
            BRA         ea_exit

ea2b_6      CMPI.W      #%110,D5
            BNE         ea2b_7

            MOVE.W      #$2028,(A1)+        *write the ascii-hex value of ' ' and '(' into the buffer

            MOVE.W      (A0)+,D7
            MOVE.W      D7,D6
            ANDI.W      #$0080,D6
            CMPI.W      #0,D6
            BEQ         no_signbit2
            MOVE.W      #$2D24,(A1)+          *write the ascii-hex value of '-$' into the buffer
            BRA         numberbit2
no_signbit2 MOVE.W      #$2B24,(A1)+          *write the ascii-hex value of '+$' into the buffer
numberbit2  MOVE.W      D7,D6
            ANDI.W      #$007F,D6
            add2ascii
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer            

            MOVE.B      #$41,(A1)+          *write the ascii-hex value of 'A' into the buffer
            MOVE.B      D3,D1               *Restore the back-up to D1
            ADDI.B      #$30,D1
            MOVE.B      D1,(A1)+            *write the ascii-hex value of '0~7' into the buffer
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            
            MOVE.W      D7,D6
            ANDI.W      #$8000,D6
            CMPI.W      #0,D6
            BEQ         d_chosen1
            MOVE.B      #$41,(A1)+        *write the ascii-hex value of 'A' into the buffer
            BRA         x_number1
d_chosen1   MOVE.B      #$44,(A1)+        *write the ascii-hex value of 'D' into the buffer
x_number1   MOVE.B      D3,D1               *Restore the back-up to D1
            ADDI.B      #$30,D1
            MOVE.B      D1,(A1)+            *write the ascii-hex value of '0~7' into the buffer
        
            MOVE.W      #$2920,(A1)+          *write the ascii-hex value of ')' and ' ' into the buffer
            BRA         ea_exit


            * mode = #%111 & reg = #$000
ea2b_7      CMPI.B      #%000,D1
            BNE         ea2b_7_1
            MOVE.W      #$2024,(A1)+        *write ' ' and '$' of ascii-hex into the buffer
            MOVE.W      (A0)+,D6
            add2ascii
            BRA         ea_exit
            
ea2b_7_1    CMPI.B      #%001,D1
            BNE         ea2b_7_2
            MOVE.W      #$2024,(A1)+        *write ' ' and '$' of ascii-hex into the buffer
            MOVE.L      (A0)+,D4
            MOVE.L      D4,D6
            LSR.L       #8,D6
            LSR.L       #8,D6
            add2ascii
            MOVE.W      D4,D6
            add2ascii
            BRA         ea_exit
            
ea2b_7_2    CMPI.B      #%100,D1
            BNE         ea2b_7_3

            MOVE.W      #$2324,(A1)+        *write '#$' of ascii-hex into the buffer

            *check if the size for immediate value is Long or Word
            LEA         imme_flag,A3
            MOVE.W      (A3),D1
            CMPI.W      #0,D1
            BEQ         not_long
            MOVE.L      (A0)+,D1            *read the immediate value from the memory
            l_2ascii
            MOVE.W      #0,(A3)             *reset the imme_flag            
            BRA         ea_exit
not_long    MOVE.W      (A0)+,D1            *read the immediate value from the memory
            w_2ascii
            MOVE.W      #0,(A3)             *reset the imme_flag
            BRA         ea_exit
            
ea2b_7_3    CMPI.B      #%010,D1
            BNE         ea2b_7_4
            MOVE.W      #$2028,(A1)+        *write the ascii-hex value of ' ' and '(' into the buffer

            MOVE.W      (A0)+,D7
            
            MOVE.W      D7,D6
            ANDI.W      #$8000,D6
            CMPI.W      #0,D6
            BEQ         no_signbit3
            MOVE.W      #$2D24,(A1)+          *write the ascii-hex value of '-$' into the buffer
            BRA         numberbit3
no_signbit3 MOVE.W      #$2B24,(A1)+          *write the ascii-hex value of '+$' into the buffer
numberbit3  MOVE.W      D7,D6
            ANDI.W      #$7FFF,D6
            add2ascii
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer            

            MOVE.W      #$5043,(A1)+        *write the ascii-hex value of 'PC' into the buffer
            
            MOVE.W      #$2920,(A1)+          *write the ascii-hex value of ')' and ' ' into the buffer
            BRA         ea_exit

            * mode = #%111 & reg = #$011
ea2b_7_4    MOVE.W      #$2028,(A1)+        *write the ascii-hex value of ' ' and '(' into the buffer

            MOVE.W      (A0)+,D7
            MOVE.W      D7,D6
            ANDI.W      #$0080,D6
            CMPI.W      #0,D6
            BEQ         no_signbit4
            MOVE.W      #$2D24,(A1)+          *write the ascii-hex value of '-$' into the buffer
            BRA         numberbit4
no_signbit4 MOVE.W      #$2B24,(A1)+          *write the ascii-hex value of '+$' into the buffer
numberbit4  MOVE.W      D7,D6
            ANDI.W      #$007F,D6
            add2ascii
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer            

            MOVE.W      #$5043,(A1)+        *write the ascii-hex value of 'PC' into the buffer
            MOVE.W      #$2C20,(A1)+        *write ',' and ' ' (space) of ascii-hex into the buffer
            
            MOVE.W      D7,D6
            ANDI.W      #$8000,D6
            CMPI.W      #0,D6
            BEQ         d_chosen2
            MOVE.B      #$41,(A1)+        *write the ascii-hex value of 'A' into the buffer
            BRA         x_number2
d_chosen2   MOVE.B      #$44,(A1)+        *write the ascii-hex value of 'D' into the buffer
x_number2   MOVE.B      D3,D1               *Restore the back-up to D1
            ADDI.B      #$30,D1
            MOVE.B      D1,(A1)+            *write the ascii-hex value of '0~7' into the buffer
        
            MOVE.W      #$2920,(A1)+          *write the ascii-hex value of ')' and ' ' into the buffer
            BRA         ea_exit



***************************************************************************************************







case_1	DC.W		$4E71,'NOP     ',$0000,$0000,$0000
		DC.W		$4E75,'RTS     ',$0000,$0000,$0008
case_2	DC.W		$4840,'SWAP    ',$0000,$0000,$0010
case_3	DC.W		$0600,'ADDI.B  ',$0001,$0000,$0018
		DC.W		$0640,'ADDI.W  ',$0002,$0000,$0020
		DC.W		$0680,'ADDI.L  ',$0003,$0000,$0028
		DC.W		$0200,'ANDI.B  ',$0001,$0000,$0030
		DC.W		$0240,'ANDI.W  ',$0002,$0000,$0038
		DC.W		$0280,'ANDI.L  ',$0003,$0000,$0040
		DC.W		$E0C0,'ASR     ',$0000,$0000,$0048
		DC.W		$E1C0,'ASL     ',$0000,$0000,$0050
		DC.W		$4200,'CLR.B   ',$0000,$0000,$0058
		DC.W		$4240,'CLR.W   ',$0000,$0000,$0060
		DC.W		$4280,'CLR.L   ',$0000,$0000,$0068
		DC.W		$0C00,'CMPI.B  ',$0001,$0000,$0070
		DC.W		$0C40,'CMPI.W  ',$0002,$0000,$0078
		DC.W		$0C80,'CMPI.L  ',$0003,$0000,$0080
		DC.W		$0A00,'EORI.B  ',$0001,$0000,$0088
		DC.W		$0A40,'EORI.W  ',$0002,$0000,$0090
		DC.W		$0A80,'EORI.L  ',$0003,$0000,$0098
		DC.W		$4EC0,'JMP     ',$0000,$0000,$00A0
		DC.W		$4E80,'JSR     ',$0000,$0000,$00A8
		DC.W		$E2C0,'LSR     ',$0000,$0000,$00B0
		DC.W		$E3C0,'LSL     ',$0000,$0000,$00B8
		DC.W		$4400,'NEG.B   ',$0000,$0000,$00C0
		DC.W		$4440,'NEG.W   ',$0000,$0000,$00C8
		DC.W		$4480,'NEG.L   ',$0000,$0000,$00D0
		DC.W		$4600,'NOT.B   ',$0000,$0000,$00D8
		DC.W		$4640,'NOT.W   ',$0000,$0000,$00E0
		DC.W		$4680,'NOT.L   ',$0000,$0000,$00E8
		DC.W		$0000,'ORI.B   ',$0001,$0000,$00F0
		DC.W		$0040,'ORI.W   ',$0002,$0000,$00F8
		DC.W		$0080,'ORI.L   ',$0003,$0000,$0100
		DC.W		$E6C0,'ROR     ',$0000,$0000,$0108
		DC.W		$E7C0,'ROL     ',$0000,$0000,$0110
		DC.W		$0400,'SUBI.B  ',$0001,$0000,$0118
		DC.W		$0440,'SUBI.W  ',$0002,$0000,$0120
		DC.W		$0480,'SUBI.L  ',$0003,$0000,$0128
		DC.W		$4880,'MOVEM.W ',$0004,$0000,$0130
		DC.W		$4C80,'MOVEM.W ',$0005,$0000,$0138
		DC.W		$48C0,'MOVEM.L ',$0004,$0000,$0140
		DC.W		$4CC0,'MOVEM.L ',$0005,$0000,$0148
case_4	DC.W		$D000,'ADD.B   ',$0000,$0000,$0150
		DC.W		$D100,'ADD.B   ',$0001,$0000,$0158
		DC.W		$D040,'ADD.W   ',$0000,$0000,$0160
		DC.W		$D140,'ADD.W   ',$0001,$0000,$0168
		DC.W		$D080,'ADD.L   ',$0000,$0001,$0170
		DC.W		$D180,'ADD.L   ',$0001,$0000,$0178
		DC.W		$D0C0,'ADDA.W  ',$0002,$0000,$0180
		DC.W		$D1C0,'ADDA.L  ',$0002,$0001,$0188
		DC.W		$C000,'AND.B   ',$0000,$0000,$0190
		DC.W		$C100,'AND.B   ',$0001,$0000,$0198
		DC.W		$C040,'AND.W   ',$0000,$0000,$01A0
		DC.W		$C140,'AND.W   ',$0001,$0000,$01A8
		DC.W		$C080,'AND.L   ',$0000,$0001,$01B0
		DC.W		$C180,'AND.L   ',$0001,$0000,$01B8
		DC.W		$B000,'CMP.B   ',$0000,$0000,$01C0
		DC.W		$B040,'CMP.W   ',$0000,$0000,$01C8
		DC.W		$B080,'CMP.L   ',$0000,$0001,$01D0
		DC.W		$B0C0,'CMPA.W  ',$0002,$0000,$01D8
		DC.W		$B1C0,'CMPA.L  ',$0002,$0001,$01E0
		DC.W		$B100,'EOR.B   ',$0001,$0000,$01E8
		DC.W		$B140,'EOR.W   ',$0001,$0000,$01F0
		DC.W		$B180,'EOR.L   ',$0001,$0000,$01F8
		DC.W		$41C0,'LEA     ',$0002,$0000,$0200
		DC.W		$3040,'MOVEA.W ',$0002,$0000,$0208
		DC.W		$2040,'MOVEA.L ',$0002,$0001,$0210
		DC.W		$8000,'OR.B    ',$0000,$0000,$0218
		DC.W		$8100,'OR.B    ',$0001,$0000,$0220
		DC.W		$8040,'OR.W    ',$0000,$0000,$0228
		DC.W		$8140,'OR.W    ',$0001,$0000,$0230
		DC.W		$8080,'OR.L    ',$0000,$0001,$0238
		DC.W		$8180,'OR.L    ',$0001,$0000,$0240
		DC.W		$9000,'SUB.B   ',$0000,$0000,$0248
		DC.W		$9100,'SUB.B   ',$0001,$0000,$0250
		DC.W		$9040,'SUB.W   ',$0000,$0000,$0258
		DC.W		$9140,'SUB.W   ',$0001,$0000,$0260
		DC.W		$9080,'SUB.L   ',$0000,$0001,$0268
		DC.W		$9180,'SUB.L   ',$0001,$0000,$0270
		DC.W		$90C0,'SUBA.W  ',$0002,$0000,$0278
		DC.W		$91C0,'SUBA.L  ',$0002,$0001,$0280
case_5	DC.W		$6100,'BSR     ',$0000,$0000,$0288
case_6	DC.W		$C140,'EXG     ',$0002,$0000,$0290
		DC.W		$C148,'EXG     ',$0003,$0000,$0298
		DC.W		$C188,'EXG     ',$0004,$0000,$02A0
		DC.W		$E008,'LSR.B   ',$0000,$0000,$02A8
		DC.W		$E028,'LSR.B   ',$0001,$0000,$02B0
		DC.W		$E048,'LSR.W   ',$0000,$0000,$02B8
		DC.W		$E068,'LSR.W   ',$0001,$0000,$02C0
		DC.W		$E088,'LSR.L   ',$0000,$0000,$02C8
		DC.W		$E0A8,'LSR.L   ',$0001,$0000,$02D0
		DC.W		$E108,'LSL.B   ',$0000,$0000,$02D8
		DC.W		$E128,'LSL.B   ',$0001,$0000,$02E0
		DC.W		$E148,'LSL.W   ',$0000,$0000,$02E8
		DC.W		$E168,'LSL.W   ',$0001,$0000,$02F0
		DC.W		$E188,'LSL.L   ',$0000,$0000,$02F8
		DC.W		$E1A8,'LSL.L   ',$0001,$0000,$0300
		DC.W		$E018,'ROR.B   ',$0000,$0000,$0308
		DC.W		$E038,'ROR.B   ',$0001,$0000,$0310
		DC.W		$E058,'ROR.W   ',$0000,$0000,$0318
		DC.W		$E078,'ROR.W   ',$0001,$0000,$0320
		DC.W		$E098,'ROR.L   ',$0000,$0000,$0328
		DC.W		$E0B8,'ROR.L   ',$0001,$0000,$0330
		DC.W		$E118,'ROL.B   ',$0000,$0000,$0338
		DC.W		$E138,'ROL.B   ',$0001,$0000,$0340
		DC.W		$E158,'ROL.W   ',$0000,$0000,$0348
		DC.W		$E178,'ROL.W   ',$0001,$0000,$0350
		DC.W		$E198,'ROL.L   ',$0000,$0000,$0358
		DC.W		$E1B8,'ROL.L   ',$0001,$0000,$0360
		DC.W		$E000,'ASR.B   ',$0000,$0000,$0368
		DC.W		$E020,'ASR.B   ',$0001,$0000,$0370
		DC.W		$E040,'ASR.W   ',$0000,$0000,$0378
		DC.W		$E060,'ASR.W   ',$0001,$0000,$0380
		DC.W		$E080,'ASR.L   ',$0000,$0000,$0388
		DC.W		$E0A0,'ASR.L   ',$0001,$0000,$0390
		DC.W		$E100,'ASL.B   ',$0000,$0000,$0398
		DC.W		$E120,'ASL.B   ',$0001,$0000,$03A0
		DC.W		$E140,'ASL.W   ',$0000,$0000,$03A8
		DC.W		$E160,'ASL.W   ',$0001,$0000,$03B0
		DC.W		$E180,'ASL.L   ',$0000,$0000,$03B8
		DC.W		$E1A0,'ASL.L   ',$0001,$0000,$03C0
case_7	DC.W		$1000,'MOVE.B  ',$0000,$0000,$03C8
		DC.W		$3000,'MOVE.W  ',$0001,$0000,$03D0
		DC.W		$2000,'MOVE.L  ',$0002,$0001,$03D8

null     DC.B    0                                 *Null terminator



ea_table		DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$0F0F,$0F0F,$0F0F
			DC.W		$010B,$0F0F,$0F0F,$0F0F
			DC.W		$010B,$0F0F,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$0001,$0304,$0B0F,$0F0F
			DC.W		$0001,$0304,$0B0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$0001,$030B,$090A,$0F0F
			DC.W		$0001,$040B,$0F0F,$0F0F
			DC.W		$0001,$030B,$090A,$0F0F
			DC.W		$0001,$040B,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$010F,$0F0F,$0F0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$010F,$0F0F,$0F0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$010F,$0F0F,$0F0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$010B,$090A,$0F0F,$0F0F
			DC.W		$0001,$0304,$0B0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$010F,$0F0F,$0F0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$010F,$0F0F,$0F0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$010F,$0F0F,$0F0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0001,$0B09,$0A0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F
			DC.W		$0F0F,$0F0F,$0F0F,$0F0F



string1     DC.W    'Enter the starting address in Hex: ',0
string2     DC.W    'Enter the ending address in Hex: ',0
string3     DC.W    'Length is too long. Maximum allowed number of characters are 8',0
string4     DC.W    'Invalid character detected. Only hexadecimal characters are allowed.',0
string5     DC.W    'Memory is out of range. The correct memory range is 0 - FFFFFF (16MB) ',0
string6     DC.W    'Address has been modified to enforce the even address boundary.',0
string7     DC.W    'Illegal address. End address should be greater or equal to the start address.',0
string8     DC.W    'Press <ENTER> to continue... ',0
string9     DC.W    'The memory range has been disassembled successfuly.',0
string10    DC.W    'Press <ENTER> to start over. (Press <q> to quit): ',0
newline     DC.W    '',0

reader      DS.L    100
reader2     DS.L    100

start_addr  DS.L    10
end_addr    DS.L    10
which_add   DC.L    0


buffer      DS.W        100                  *Print buffer

bad_flag    DC.W        0
jump_flag   DC.W        0
imme_flag   DC.W        0
move_flag   DC.W        0
dis_table   DC.W        0




            
***************** TEST PROGRAM - START ***********************************

        ORG     $20000
        ADDI.B      #1,D7
        LEA         start_addr,A4       *A4 will walk through the memory
        MOVEM.L     A4/D0, (A6)        *Save the working registers on stack
        CLR.L       D6            *Set the memory variable bad_addr to 0
        CLR.W       D5            *Set the memory variable intended to 0

terminator        DC.B        0                   *Null terminator

***************** TEST PROGRAM - END **************************************



         END         pgm_start           *End of program and load address












































*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
