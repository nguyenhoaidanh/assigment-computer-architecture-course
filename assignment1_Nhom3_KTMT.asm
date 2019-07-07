##### 		Danh sach bien 			#####
####################################################
#	Tham so ham $a1, $a2
#	Ket qua ham $f12
#	$t4, $t5 chua sign a, sign b
#       $t6, $8 chua exponent a, exponent b
#       $t7, $t9 chua fraction a, fraction b
#	$s1 luu sign cua result
#	$t6 chua exponent result
#	$t7 chua fraction result
#	$a1 luu float ket qua sau do gan return $f12
# 	Va su dung nhieu thanh tam khac
# 	Trong code co su dung lai cac bien da dung ($a1,$t6,$t7)
#	Trong qua trinh tinh toan cung co sai so
####################################################
.data
text1 : .asciiz "Enter first float: "
text2 : .asciiz "Enter second float: "
text3 : .asciiz "Result: "
numa : .word       0
numb : .word       0
.text
.globl input
input :
	#print
	la  $a0, text1
	li  $v0, 4
	syscall
	# saving input into num1
	li  $v0, 6
	syscall
	swc1    $f0, numa
	#print
	la  $a0, text2
	li  $v0, 4
	syscall
	# saving input into num2
	li  $v0, 6
	syscall
	swc1    $f0, numb
	# loading data to registers
	lw  $a1, numa   
	lw  $a2, numb
	#call funtion
	jal addfloat

	li  $v0, 2
	syscall
	#exit
	li  $v0, 10         
	syscall


#########################################################
addfloat:   #tham so a1, a2 ket qua f12
#begin funct

sign : #Tach sign ra
move    $t4, $a1
andi    $t4, $t4, 0x80000000    #giu nguyen phan sign, phan con lai zero
move    $t5, $a2
andi    $t5, $t5, 0x80000000     #giu nguyen phan sign, phan con lai zero
bne     $t4, $t5, next   	# khac dau di den next (buoc tiep theo)
j       extract 		#cùng dau thi di tách exponent, fraction luôn

next : #2 so a b dang co sign khac nhau
move    $t2, $a1
move    $t3, $a2
andi    $t2, $t2, 0x7FFFFFFF  #giu nguyen phan exponent, fraction , phan sign=0
andi    $t3, $t3, 0x7FFFFFFF
beq      $t2, $t3, zero  # dang khác dau mà cùng phan con lai nên -> tong = 0

extract : 
or $s0, $a1, $a2       
beqz $s0, zero # neu ca 2 bang 00000... het thi tong = 0
andi $s1, $a1, 0x7FFFFFFF #giu nguyen phan exponent, fraction , phan sign=0
andi $s2, $a2, 0x7FFFFFFF
beqz $s1, first_zero  # neu a=0 --> sum = b
beqz $s2, second_zero # neu b=0 --> sum = a

#Tach exponent and fraction
move    $t6, $a1
andi    $t6, $t6, 0x7F800000    # $t6 chua exponent a
move    $t7, $a1
andi    $t7, $t7, 0x007FFFFF   # $t7 chua fraction a
ori     $t7, $t7, 0x00800000    #adding 1 to fraction

move    $t8, $a2
andi    $t8, $t8, 0x7F800000     # $t8 chua exponent b
move    $t9, $a2
andi    $t9, $t9, 0x007FFFFF    # $t9 chua fraction b
ori     $t9, $t9, 0x00800000    #adding 1 to fraction

#Kiem tra exponent
exp_check:
bgt    $t6, $t8, exp1 # neu exponent $t8 < $t6 jum den exp1
bgt    $t8, $t6, exp2 # neu exponent $t8 > $t6 jum den exp2
#else
#mu = nhau thi so sanh sign
bgt     $t4, $t5, sub_first  # a âm 
blt     $t4, $t5, sub_second # b âm
#else
#dau = nhau(cung am, cung duong) thi cong
Add :
addu   $t7, $t7, $t9 #add 2 fraction va luu vao $t7
move   $s1, $t4      #sign cua result
j      shift

sub_first : #a âm, b duong
bgt    $t9, $t7, sub_second #if fraction a < b thi jum sub_second
subu   $t7, $t7, $t9 	 #fraction result = frac a- frac b $t7
move   $s1, $t4		 #sign cua result= sign a
j      shift2
	
sub_second :
bgt    $t7, $t9, sub_first #if fraction a > b thi jum sub_first
subu   $t7, $t9, $t7 	#sub first parts of mantissas
move   $s1, $t5     	#sign cua result= sign b
j      shift2

exp1 :
sll    $s4, $t9, 31 #copy lsb of fraction a
srl    $t9, $t9, 1 #shift first part of fraction a
or $t9, $t9, $s4  #put lsb in fraction a
addiu  $t8, $t8, 0x00800000 #increase exponent $t8
j      exp_check

exp2 :
sll    $s4, $t7, 31 #copy lsb of fraction b
srl    $t7, $t7, 1 #shift first part of fraction b
or $t7, $t7, $s4 #put lsb in fraction b
addiu  $t6, $t6, 0x00800000 #increase exponent $t6
j      exp_check

#sau khi thuc hien phep cong, neu co carry thi dich phai 1 bit va tang exponent len 1
shift : 
andi     $t4, $t7, 0x01000000 #kiem tra xem co carry khong
beqz     $t4, result 		#neu khong thi in ket qua , else dich bit
srl    $t7, $t7, 1 #shift right
add    $t6, $t6, 0x00800000 #increase exp
j result

#sau khi thuc hien phep tru, neu cac bit dau cua fraction = 0
# thi dich bit sang trai den khi bit dau tien cua fraction = 1
shift2 : 
andi     $t4, $t7, 0x00800000 #t7 bay gio là fraction result
bnez    $t4, result #neu bit dau cua fraction = 1 thi in ket qua luon va ket thuc
#else lap dich bit sang trai
loop :
sll    $t7, $t7, 1 #shift left
sub    $t6, $t6, 0x00800000 #decrease exp

#andi va check tiep
andi     $t4, $t7, 0x00800000 
bnez    $t4, result
j loop


result :
andi   $t7, $t7, 0x007FFFFF    
move   $a1, $s1       #copy sign result
or $a1, $a1, $t6      #add exponent result
or $a1, $a1, $t7       #add fraction result
j      output


first_zero :#a=0 , sum=b
move  $a1, $a2
j     output


second_zero :#b=0, sum=a
j     output


zero :#sum=0
li  $a1, 0x00000000

output :
	sw  $a1, numa
	#print "Result: "
	la  $a0, text3
	li  $v0, 4
	syscall
	lwc1    $f12, numa	
	jr $ra #return result
#end funt
