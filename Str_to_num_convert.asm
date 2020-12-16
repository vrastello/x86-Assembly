TITLE Project 6     (Proj6_Rastellv.asm)

; Author: Vincent Rastello
; Last Modified: 12-06-20
; OSU email address: Rastellv@oregonstate.edu
; Course number/section:   CS271 Section Online
; Project Number:  6               Due Date: 12-06-20
; Description: This project uses primitive string intructions and macros to implement instructions
; already created by the Irvine Library. This is essentially the WriteDec and ReadDec intructions.
; The program reads user input as a string and converts to numeric form then saves these numbers in
; an array. It validates if the number is too large to fit in a 32 bit register and if the user enters
; non-digits other than sign at the beginning of number. Once 10 numbers are retrieved from user it
; calculates the average and sum. It then converts the numbers from numeric to string form and displays
; the list of numbers, the sum and average to the user.

; implementation note: all paramaters are passed on call stack

INCLUDE Irvine32.inc

;Macros:

mGetString MACRO prompt, count, address
	pushad
	mov		EDI, count
	mov		EDX, prompt
	call	WriteString
	mov		EDX, address
	mov		ECX, 101
	call	ReadString
	mov		[EDI], EAX
	popad
ENDM

mDisplayString MACRO address
	push	EDX
	mov		EDX, address
	call	WriteString
	pop		EDX
ENDM

;Constants:

MAXSIZE = 10

.data

intro_1		BYTE "Project 6: Designing low-level I/O procedures",13,10
			BYTE "Programmed by: Vince Rastello",13,10,13,10,0
intro_2		BYTE "Please provide 10 signed decimal integers.",13,10
			BYTE "Each number needs to be small enough to fit inside a 32 bit register.",13,10
			BYTE "After you have finished inputing raw numbers I will display a list of",13,10
			BYTE "the integers, their sum, and their average value.",13,10,13,10,0
reg_prompt	BYTE "Please enter a signed number: ",0
err_prompt	BYTE "Please try again: ",0
error_msg	BYTE "ERROR: You did not enter a signed number or your number was too big.",13,10,0
arry_prompt	BYTE "You entered the following numbers:",13,10,0
sum_prompt	BYTE "The sum of these numbers is: ",0
avg_prompt	BYTE "The rounded average is: ",0
goodbye		BYTE 13,10,13,10,"Winner winner chicken dinner!",13,10,13,10,0
comma		BYTE ", ",0
in_string	BYTE 101 DUP(?)
out_string	BYTE 11 DUP(?)
byteCount	DWORD ?
valid_array SDWORD MAXSIZE DUP(?)
sum			SDWORD ?
average		SDWORD ?

.code
main PROC

push	OFFSET intro_1
push	OFFSET intro_2
call	Intro
push	OFFSET error_msg
push	OFFSET valid_array
push	OFFSET err_prompt
push	OFFSET byteCount
push	OFFSET reg_prompt
push	OFFSET in_string
push	MAXSIZE
call	ReadVal
push	OFFSET average
push	OFFSET sum
push	OFFSET valid_array
push	LENGTHOF valid_array
call	Calculate
push	OFFSET valid_array
push	LENGTHOF valid_array
push	MAXSIZE
push	OFFSET arry_prompt
push	OFFSET comma
push	OFFSET out_string
call	WriteVal
push	OFFSET sum
push	LENGTHOF sum
push	MAXSIZE
push	OFFSET sum_prompt
push	OFFSET comma
push	OFFSET out_string
call	WriteVal
push	OFFSET average
push	LENGTHOF average
push	MAXSIZE
push	OFFSET avg_prompt
push	OFFSET comma
push	OFFSET out_string
call	WriteVal
push	OFFSET goodbye
call	Conclusion

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; --Intro-----------------------------------------------------------------------
; Procedure to introduce the program
; Preconditions: intro_1, 2 are strings that describe the program and rules.
; Postconditions: None
; Recieves: address offsets for intro_1 and intro_2
; Returns: None
Intro PROC
	push	EBP
	mov		EBP, ESP
	pushad

mDisplayString [EBP + 12]
mDisplayString [EBP + 8]

	popad
	pop		EBP
	ret		8
Intro ENDP
; --ReadVal-----------------------------------------------------------------------
; Procedure that reads user input, validates it (size and syntax) and saves inputs in a DWORD array called valid_array
; Preconditions: error_msg, err_prompt and reg_prompt are strings, valid_array set to 10 DWORDS
; byteCount is unknown and MAXSIZE constant is 10.
; Postconditions: 10 validated numbers saved to array, numbers converted from string to numeric
; Recieves: address offsets for strings, valid_array address, Maxsize constant, byteCount address
; Returns: valid_array
; Local variables: numInt to for conversion algorithm, sign to store sign of number
ReadVal PROC
	LOCAL numInt: SDWORD, sign: SDWORD
	pushad
	;sets ECX to MAXSIZE = 10 and EDI to valid_array address
	mov		ECX, [EBP + 8]
	mov		EDI, [EBP + 28]

	;outerloop begins with Macro to collect string from user and save to in_string
	; pushes ECX so innerLoop can use built in LOOP intruction
	_outerLoop:
	push	ECX
	mGetString [EBP + 16], [EBP + 20], [EBP + 12]
	jmp		_validate

	;error message and Macro to collect string with different message to user
	_error:
	mDisplayString [EBP + 32]
	mGetString [EBP + 24], [EBP + 20], [EBP + 12]

	;sets in_string to ESI, byteCount of in_string to ECX, zeroes out EAX and EDX
	;sets local variables numInt to 0 and sign to +1
	;inner loop iterates through in_string validating as it goes
	_validate:
	CLD
	mov		sign, 1
	mov		numInt, 0
	mov		ESI, [EBP + 20]
	mov		ECX, [ESI]
	mov		ESI, [EBP + 12]
	xor		EAX, EAX
	xor		EDX, EDX

	;Loads string byte and checks for negative or positive sign, skips if none.
	LODSB
	cmp		AL, 43
	JE		_positive
	cmp		AL, 45
	JE		_negative
	jmp		_noSign

	;if negative sets local variable to -1, decrements ECX and loads next string BYTE
	;from here it will only validate for numbers, no other non-digits accepted
	_negative:
		mov		sign, -1
	_positive:
		dec		ECX
	_innerLoop:
		LODSB
		;validates value is within 48-57 ASCII code for numbers
		;alrgorithm: numInt = 10 * numInt + (numChar - 48)
		_noSign:
			cmp		AL, 48
			JL		_error
			cmp		AL, 57
			JG		_error
			sub		AL, 48
			movzx	EBX, AL
			mov		EAX, numInt
			MUL	DWORD PTR [EBP + 8]		;uses MAXSIZE = 10
			jc		_error				;if carry flag or overflow flag too big: ERROR
			add		EAX, EBX
			jo		_error
			mov		numInt, EAX
			LOOP	_innerLoop			; goes to next character, numInt will be increased by 
										;order of 10 with next numChar in next digit
			
			;This section validates size if carry and overflow flags not set, checks for EDX
			;value after IMUL, if EDX is different than FFFFFFFF for negaive or 00000000 for positive
			;then it will trigger ERROR.
			mov		EBX, sign
			CDQ
			IMUL	EBX			;sets sign of number to save it after algebra is completed

			cmp		sign, -1
			JNE		_check_edx
			cmp		EDX, 4294967295
			JNE		_error
			jmp		_size_validated
		_check_edx:
			cmp		EDX, 0
			JNE		_error
		
		;After size validated, saves signed integer, indexes to next point of destination array, 
		;goes to outerloop popping ECX count for 10 numbers
		_size_validated:
			mov		[EDI], EAX
			add		EDI, 4
			pop		ECX
			dec		ECX
			jnz		_outerLoop

		popad
		ret		28

ReadVal ENDP
; --Calculate-----------------------------------------------------------------------
; Procedure to calculate sum and average
; Preconditions: valid_array filled
; Postconditions: Sum and average calculated and output to memory
; Recieves: address offsets for valid_array, sum and average
; Returns: Sum and Average
Calculate PROC
	push	EBP
	mov		EBP, ESP
	pushad

	;Calculate Sum, ECX = Length of array, ESI = valid_array, EDI = sum address 
	xor		EAX, EAX
	mov		ECX, [EBP + 8]
	mov		ESI, [EBP + 12]
	mov		EDI, [EBP + 16]
	_loop:
	add		EAX, [ESI]
	add		ESI, 4
	LOOP	_loop
	mov		[EDI], EAX


	;Calculate Average, EDI = average address, EAX = sum of array, EBX set to MAXSIZE = 10
	mov		EDI, [EBP + 20]
	mov		EBX, [EBP + 8]
	CDQ
	IDIV	EBX
	mov		[EDI], EAX


	popad
	pop		EBP
	ret		16

Calculate ENDP

; --WriteVal-----------------------------------------------------------------------
; Procedure that writes any saved array with given prompts and array addresses and size. Procedure
; coverts from numeric DWORD to BYTE string and can handle any size array, adding commas. Utilizes
; stack to offload converted numbers from array then pops them into string in correct order. Due to
; little Endian architecture this prevents string from reversing. 
; Preconditions: string addresses and array address and size set.
; Postconditions: Numbers converted and displayed to user 
; Recieves: address offsets for strings, array, array size and MAXSIZE = 10 constant
; Local Variables: counter--used as convenient seperate counter so count of strings added to stack
; is stored then values popped into out_string and printed. Sign to hold sign of number.
; Returns: None
WriteVal PROC
		LOCAL counter: DWORD, sign: DWORD
		pushad
		call	Crlf

;displays introductory prompt
mDisplayString [EBP + 16]

		;moves source address into ESI and array size to ECX
		mov		ESI, [EBP + 28]
		mov		ECX, [EBP + 24]
		_outerLoop:
				
				;At outer loop this section clears the array, setting out_string address to EDI
				; preserves ECX counter in order to use LOOP for clear_array
				push	ECX
				mov		ECX, 11
				xor		EAX, EAX
				mov		EDI, [EBP + 8]
				push	EDI
			_clear_array:
				mov		[EDI], EAX
				add		EDI, 1
				loop	_clear_array
				pop		EDI
				pop		ECX

			;initializes values for innerLoop: counter = 0, EAX = value of source array
			;EBX = 10, if value in array is negative sets sign = -1
			mov		counter, 0
			mov		EAX, [ESI]
			mov		EBX, [EBP + 20]
			cmp		EAX, -1
			JG		_innerLoop
			mov		sign, -1

			;Divides value by 10, if negative converts to positive, adds 48 to remainder (ASCII code offset)
			;this yields value from 48-57(ASCII code for numeric string characers)
			;Adding 48 to remainder because each division by 10 cuts number short one digit.
			;pushes 48 + remainder onto stack
			;increments counter, when quotient (EAX) is 0 you have reached the first digit
		_innerLoop:
			CDQ
			IDIV	EBX
			cmp		EDX, -1
			JG		_positive
			neg		EDX
			_positive:
			add		EDX, 48
			push	EDX
			inc		counter
			cmp		EAX, 0
			JNE		_innerLoop

		; uses counter to pop values off stack and store into out_string address as BYTE string
		; if negative adds negative symbol in front. Once counter is zero ends loop.
		_storeLoop:
			cmp		sign, -1
			JNE		_no_sign
			mov		sign, 1
			mov		AL, 45
			STOSB
			_no_sign:
			pop		EAX
			STOSB
			dec		counter
			JNZ		_storeLoop

;displays string with prompts adding commas if necessary, loops back if multiple values 
mDisplayString [EBP + 8]

		cmp		ECX, 1
		JLE		_no_comma

mDisplayString [EBP + 12]

		_no_comma:
		add		ESI, 4
		dec		ECX
		JNZ		_outerLoop

		popad
		ret		24
		
WriteVal ENDP
; --Conclusion-----------------------------------------------------------------------
; Procedure to conclude program
; Preconditions: goodbye string in memory, program completed
; Postconditions: User heads on down the ol' dusty trail. 
; Recieves: address offset for string
; Returns: None
Conclusion PROC
	push	EBP
	mov		EBP, ESP
	pushad

mDisplayString [EBP + 8]

	popad
	pop		EBP
	ret		4
Conclusion ENDP

END main
