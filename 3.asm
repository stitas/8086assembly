.model small

.stack 100h

.data
	PranMOV	db "Komanda MOV, w= $"
	PranNe	db "Komanda ne MOV registras <--> registras / atmintis", 13, 10, "$"
	Mnemon  db " mov $"
	KablTarp db ", $"
	Plius db " + $"
	NewLine db 13, 10, "$"
	Testas dw 15
	
	pirmas_op dw 0
	pirmas_op_r dw 0

	antras_op dw 0
	antras_op_r dw 0
	
	trecias_op dw 0
	trecias_op_r dw 0
	
	op_ax_r dw 0
	op_bx_r dw 0
	op_cx_r dw 0
	op_dx_r dw 0
	
	op_ah_r db 0
	op_bh_r db 0
	op_ch_r db 0
	op_dh_r db 0
	
	op_al_r db 0
	op_bl_r db 0
	op_cl_r db 0
	op_dl_r db 0
	
	op_sp_r dw 0
	op_bp_r dw 0
	op_si_r dw 0
	op_di_r dw 0
	
	op_ax db "ax$"
	op_bx db "bx$"
	op_cx db "cx$"
	op_dx db "dx$"
	
	op_ah db "ah$"
	op_bh db "bh$"
	op_ch db "ch$"
	op_dh db "dh$"
	
	op_al db "al$"
	op_bl db "bl$"
	op_cl db "cl$"
	op_dl db "dl$"
	
	op_sp db "sp$"
	op_bp db "bp$"
	op_si db "si$"
	op_di db "di$"
	
	op_bx_si db "bx + si$"
	op_bx_di db "bx + di$"
	op_bp_si db "bp + si$"
	op_bp_di db "bp + di$"
	

.code
  Pradzia:
	MOV	ax, @data								;reikalinga kiekvienos programos pradžioj
	MOV	ds, ax									;reikalinga kiekvienos programos pradžioj

	MOV	ax, 0									;nėra komandos MOV es, 0 - tai reikia daryti per darbinį registrą (ax)
	MOV	es, ax									;į es įsirašome 0, nes pertraukimų vektorių lentelė yra segmente, kurio pradžios adresas yra 00000
	
	PUSH	es:[4]								; Iššisaugome tikrą pertraukimo apdorojimo procedūros adresą, kad programos gale galėtume jį atstatyti
	PUSH	es:[6]								; Iššisaugome tikrą pertraukimo apdorojimo procedūros adresą, kad programos gale galėtume jį atstatyti
	
	MOV	word ptr es:[4], offset ApdorokPertr	;į pertraukimų vektorių lentelę įrašome pertraukimo apdorojimo procedūros poslinkį nuo kodo segmento pradžios
	MOV	es:[6], cs								;į pertraukimų vektorių lentelę įrašome pertraukimo apdorojimo procedūros segmentą						
	
	PUSHF										;Išsisaugome SF reikšmę testavimo pradžioje
	PUSHF										;Išsisaugome SF kad galėtume ją išimti ir nustatyti TF
	POP ax										;Išimame SF reikšmę į TF
	OR ax, 0100h								;Nustatome TF=1
	PUSH ax										;Įdedame pakoreguotą reikšmę
	POPF										;Išimame pakoreguotą reikšmę į SF; Nuo čia TF=1
	MOV di, 0											;Pirmas pertraukimas kyla ne prieš šią komandą, o po jos; todėl tiesiog vieną komandą nieko nedarome
	
	MOV AX, [BX + SI]
	MOV AX, [BX + SI + 10h]
	MOV AX, [BX + DI]
	MOV AX, [BX + DI + 0FEh]
	MOV AX, [BP + SI]
	MOV AX, [BP + SI + 0ABCDh]
	MOV AX, [BP + DI]
	MOV AX, [BP + DI + 10h]
	MOV AX, [SI]
	MOV AX, [SI + 10h]
	MOV AX, [DI]
	MOV AX, [DI + 10h]
	MOV AX, [1234h]
	MOV AX, [BP + 10h]
	MOV AX, [BX + 10h]
	MOV al, 10
	MOV bl, 14
	MOV al, bl
	MOV ax, Testas
	
	POPF										;Ištraukiame iš steko testavimo pradžioje buvusią SF reikšmę
												;Kadangi tada TF buvo lygi 0, tai tokiu būdu numušame TF
	POP	es:[6]
	POP	es:[4]

	MOV	ah, 4Ch									;reikalinga kiekvienos programos pabaigoj
	MOV	al, 0									;reikalinga kiekvienos programos pabaigoj
	INT	21h										;reikalinga kiekvienos programos pabaigoj

PROC ApdorokPertr
	MOV trecias_op, 0	

	MOV op_ax_r, ax
	MOV op_bx_r, bx
	MOV op_cx_r, cx
	MOV op_dx_r, dx
	
	MOV op_ah_r, ah
	MOV op_bh_r, bh
	MOV op_ch_r, ch
	MOV op_dh_r, dh
	
	MOV op_al_r, al
	MOV op_bl_r, bl
	MOV op_cl_r, cl
	MOV op_dl_r, dl
	
	MOV op_sp_r, sp
	MOV op_bp_r, bp
	MOV op_si_r, si
	MOV op_di_r, di
	
	;Įdedame registrų reikšmes į steką
	PUSH	ax
	PUSH	bx
	PUSH	dx
	PUSH	bp
	PUSH	es
	PUSH	ds

	;Nustatome DS reikšmę, jei pertraukimą iškviestų kita programa
	MOV	ax, @data
	MOV	ds, ax
	
	XOR cx, cx

	;Į registrą DL įsirašom komandos, prieš kurią buvo iškviestas INT, operacijos kodą
	MOV bp, sp									;Darbui su steku patogiausia naudoti registrq BP
	ADD bp, 12									;Nes i steka idejom 12 baitu registru
	MOV bx, [bp]								;Į bx įdedame grįžimo adreso poslinkį nuo segmento pradžios (IP)
	MOV es, [bp+2]								;Į es įdedame grįžimo adreso segmentą (CS)
	MOV dx, [es:bx]								;Išimame pirmus 2 baitus, dl - OPK; dh - adresavimo baitas
	
	;Tikriname, ar INT buvo iškviestas prieš komandą MOV
	MOV al, dl
	AND al, 0FCh								;Tikriname pagal pirmus 6 OPK bitus
	CMP al, 88h									;Ar tai MOV registras <--> registras / atmintis - 1000 10dw
	JE  mov1
	
	;Jei INT buvo iškviestas ne prieš komandą MOV, tai išvedame pranešimą
	MOV ah, 9
	MOV dx, offset PranNe
	INT 21h
	JMP pabaiga

	;Jei INT buvo iškviestas prieš komandą MOV, tai tada dl registre suformuojame bito w reikšmę
mov1:
	;Išvedame pranešimą ir bito w reikšmę
	PUSH dx			;DX saugoma opk ir mod r/m baitas dl - opk dh - mod r/m
	PUSH bx

	SHR dh, 6
	AND dh, 00000011b
	CMP dh, 00000010b
	JNE mod01apdr
	MOV cx, 1
	JMP toliau
	
mod01apdr:
	CMP dh, 00000001b
	JNE toliau
	MOV cx, 2
	
toliau:
	MOV bx, es
	CALL IsvestiHexZodi
	
	MOV ah, 02h
	MOV dl, ':'
	INT 21h
	
	POP bx
	POP dx
	PUSH bx
	PUSH dx
	CALL IsvestiHexZodi
	
	MOV ah, 02h
	MOV dl, ' '
	INT 21h
	
	POP dx
	MOV bh, dl		;Reikia apkeisti vietom pirma ir paskutini baita
	MOV bl, dh
	PUSH dx
	CALL IsvestiHexZodi
	
	POP dx
	POP bx
	PUSH bx
	PUSH dx
	
	CMP cx, 1
	JNE baitoPoslinkis
	MOV bx, [es:bx + 2]
	MOV dx, bx
	MOV bh, dl
	MOV bl, dh
	CALL IsvestiHexZodi
	
baitoPoslinkis:
	CMP cx, 2
	JNE IsvestiMnemon
	MOV bx, [es:bx + 2]
	CALL IsvestiHexBaita

IsvestiMnemon:
	MOV ah, 9
	MOV dx, offset Mnemon
	INT 21h
	
	POP dx
	PUSH dx
	
	;Pirmas reg
	MOV cx, 0
	CALL IsvestiReg
	
	MOV dx, offset KablTarp
	CALL IsvestiEkrana
	
	;Antras reg
	MOV cx, 1
	POP dx
	POP bx
	MOV bx, [es:bx + 2]
	CALL IsvestiReg
	
	MOV dl, ';'
	CALL IsvestiEkranaChar
	
	MOV dl, ' '
	CALL IsvestiEkranaChar
	
	MOV dx, pirmas_op
	CALL IsvestiEkrana
	
	MOV dl, '='
	CALL IsvestiEkranaChar
	
	MOV bx, pirmas_op_r
	CALL IsvestiHexZodi
	
	MOV dx, offset KablTarp
	CALL IsvestiEkrana
	
	MOV dx, antras_op
	CALL IsvestiEkrana
	
	MOV dl, '='
	CALL IsvestiEkranaChar
	
	MOV bx, antras_op_r
	CALL IsvestiHexZodi
	
	CMP trecias_op, 0
	JE nLine
	
	MOV dx, offset KablTarp
	CALL IsvestiEkrana
	
	MOV dx, trecias_op
	CALL IsvestiEkrana
	
	MOV dl, '='
	CALL IsvestiEkranaChar
	
	MOV bx, trecias_op_r
	CALL IsvestiHexZodi
	
	nLine:
		MOV dx, offset NewLine
		CALL IsvestiEkrana
	

	;Atstatome registrų reikšmes ir išeiname iš pertraukimo apdorojimo procedūros
pabaiga:
	POP ds
	POP es
	POP bp
	POP	dx
	POP bx
	POP	ax
	IRET			;pabaigoje būtina naudoti grįžimo iš pertraukimo apdorojimo procedūros komandą IRET
						;paprastas RET netinka, nes per mažai informacijos išima iš steko
ApdorokPertr ENDP

PROC IsvestiHex
	CMP dl, 9
	JLE sk0_9
	ADD dl, 7
	
sk0_9:
	ADD dl, 30h
	MOV ah, 02h
	INT 21h
	RET
	
IsvestiHex ENDP


PROC IsvestiHexZodi
	XOR dx, dx

	MOV dl, bh
	SHR dl, 4
	CALL IsvestiHex
	
	MOV dl, bh
	AND dl, 0Fh
	CALL IsvestiHex
	
	MOV dl, bl
	SHR dl, 4
	CALL IsvestiHex
	
	MOV dl, bl
	AND dl, 0Fh
	CALL IsvestiHex

	RET
	
IsvestiHexZodi ENDP

PROC IsvestiHexBaita
	XOR dx, dx
	
	MOV dl, bl
	SHR dl, 4
	CALL IsvestiHex
	
	MOV dl, bl
	AND dl, 0Fh
	CALL IsvestiHex

	RET
	
IsvestiHexBaita ENDP

PROC IsvestiEkrana
	MOV ah, 09h
	INT 21h
	RET
IsvestiEkrana ENDP 

PROC IsvestiEkranaChar
	MOV ah, 02h
	INT 21h
	RET
IsvestiEkranaChar ENDP 

PROC IsvestiReg
	AND dl, 1 ; w bitas

	CMP cx, 0
	JNE reg2

	;Jei pirmas registras
	MOV al, dh
	SHR al, 3
	AND al, 00000111b
	JMP mod11JMP
	
	reg2:
		MOV ah, dh 
		SHR ah, 6
		AND ah, 00000011b	;MOD bitai
		
		MOV al, dh
		AND al, 00000111b	;R/M bitai
		
		CMP ah, 00000000b
		JE mod00
		
		CMP ah, 00000001b
		JE mod01mod10JMPJMP
		
		CMP ah, 00000010b
		JE mod01mod10JMPJMP
		
		CMP ah, 00000011b
		JE mod11JMPJMP
	
	mod01mod10JMPJMP:
		JMP mod01mod10JMP
	mod11JMPJMP:
		JMP mod11JMP
	
	mod00:
		PUSH ax
	
		MOV dl, '['
		CALL IsvestiEkranaChar
		
		POP ax
		
		CMP al, 00000000b
		JE bxsi
		CMP al, 00000001b
		JE bxdi
		CMP al, 00000010b
		JE bpsi	
		CMP al, 00000011b
		JE bpdiJMP
		CMP al, 00000100b
		JE _siJMP
		CMP al, 00000101b
		JE _diJMP
		;CMP al, 00000110b
		;JE adr
		CMP al, 00000111b
		JE _bx0JMP
		
		bxsi:
			MOV antras_op, offset op_bx
			MOV trecias_op, offset op_si
			MOV dx, op_bx_r
			MOV antras_op_r, dx
			MOV dx, op_si_r
			MOV trecias_op_r, dx
			MOV dx, offset op_bx_si
			CALL IsvestiEkrana
			JMP mod00isv
		bxdi:
			MOV antras_op, offset op_bx
			MOV trecias_op, offset op_di
			MOV dx, op_bx_r
			MOV antras_op_r, dx
			MOV dx, op_di_r
			MOV trecias_op_r, dx
			MOV dx, offset op_bx_di
			CALL IsvestiEkrana
			JMP mod00isv
		bpsi:
			MOV antras_op, offset op_bp
			MOV trecias_op, offset op_si
			MOV dx, op_bp_r
			MOV antras_op_r, dx
			MOV dx, op_si_r
			MOV trecias_op_r, dx
			MOV dx, offset op_bp_si
			CALL IsvestiEkrana
			JMP mod00isv
			
		bpdiJMP:
			JMP bpdi
		_siJMP:
			JMP _si
		_diJMP:
			JMP _di
		_bx0JMP:
			JMP _bx0
			
		bpdi:
			MOV antras_op, offset op_bp
			MOV trecias_op, offset op_di
			MOV dx, op_bp_r
			MOV antras_op_r, dx
			MOV dx, op_di_r
			MOV trecias_op_r, dx
			MOV dx, offset op_bp_di
			CALL IsvestiEkrana
			JMP mod00isv
		_si:
			MOV antras_op, offset op_si
			MOV dx, op_si_r
			MOV antras_op_r, dx
			MOV dx, offset op_si
			CALL IsvestiEkrana
			JMP mod00isv
		_di:
			MOV antras_op, offset op_di
			MOV dx, op_di_r
			MOV antras_op_r, dx
			MOV dx, offset op_di
			CALL IsvestiEkrana
			JMP mod00isv
		;adr:
			;MOV antras_op, offset op_bx_si
			;MOV bx, [es:bx+1]
			;CALL IsvestiHexZodi
			;JMP mod00isv
		_bx0:
			MOV antras_op, offset op_bx
			MOV dx, op_bx_r
			MOV antras_op_r, dx
			MOV dx, offset op_bx
			CALL IsvestiEkrana
			
		mod00isv:
			MOV dl, ']'
			CALL IsvestiEkranaChar
			RET
	
	mod01mod10JMP:
		JMP mod10
			
	mod11JMP:
		JMP mod11
	
	mod01:
	mod10:
		PUSH ax
	
		MOV dl, '['
		CALL IsvestiEkranaChar
		
		POP ax
		PUSH ax
	
		CMP al, 00000000b
		JE bxsip
		CMP al, 00000001b
		JE bxdip
		CMP al, 00000010b
		JE bpsip	
		CMP al, 00000011b
		JE bpdipJMP
		CMP al, 00000100b
		JE _sipJMP
		CMP al, 00000101b
		JE _dipJMP
		CMP al, 00000110b
		JE bppJMP
		CMP al, 00000111b
		JE _bxpJMP
		
		
		bxsip:
			MOV antras_op, offset op_bx
			MOV trecias_op, offset op_si
			MOV dx, op_bx_r
			MOV antras_op_r, dx
			MOV dx, op_si_r
			MOV trecias_op_r, dx
			MOV dx, offset op_bx_si
			CALL IsvestiEkrana
			JMP mod10mod01isv
			
		bxdip:
			MOV antras_op, offset op_bx
			MOV trecias_op, offset op_di
			MOV dx, op_bx_r
			MOV antras_op_r, dx
			MOV dx, op_di_r
			MOV trecias_op_r, dx
			MOV dx, offset op_bx_di
			CALL IsvestiEkrana
			JMP mod10mod01isv
		
		bpsip:
			MOV antras_op, offset op_bp
			MOV trecias_op, offset op_si
			MOV dx, op_bp_r
			MOV antras_op_r, dx
			MOV dx, op_si_r
			MOV trecias_op_r, dx
			MOV dx, offset op_bp_si
			CALL IsvestiEkrana
			JMP mod10mod01isv
			
		bpdipJMP:
			JMP bpdip
		_sipJMP:
			JMP _sip
		_dipJMP:
			JMP _dip
		bppJMP:
			JMP bpp
		_bxpJMP:
			JMP _bxp
		
		bpdip:
			MOV antras_op, offset op_bp
			MOV trecias_op, offset op_di
			MOV dx, op_bp_r
			MOV antras_op_r, dx
			MOV dx, op_di_r
			MOV trecias_op_r, dx
			MOV dx, offset op_bp_di
			CALL IsvestiEkrana
			JMP mod10mod01isv
			
		_sip:
			MOV antras_op, offset op_si
			MOV dx, op_si_r
			MOV antras_op_r, dx
			MOV dx, offset op_si
			CALL IsvestiEkrana
			JMP mod10mod01isv
			
		_dip:
			MOV antras_op, offset op_di
			MOV dx, op_di_r
			MOV antras_op_r, dx
			MOV dx, offset op_di
			CALL IsvestiEkrana
			JMP mod10mod01isv
			
		bpp:
			MOV antras_op, offset op_bp
			MOV dx, op_bp_r
			MOV antras_op_r, dx
			MOV dx, offset op_bp
			CALL IsvestiEkrana
			JMP mod10mod01isv
			
		_bxp:
			MOV antras_op, offset op_bx
			MOV dx, op_bx_r
			MOV antras_op_r, dx
			MOV dx, offset op_bx
			CALL IsvestiEkrana
			
		mod10mod01isv:
			MOV dx, offset Plius
			CALL IsvestiEkrana
			
			POP ax
			
			CMP ah, 00000001b
			JNE mod10isv
			
			CALL IsvestiHexBaita
			JMP mod10mod01end
			
			mod10isv:
				CALL IsvestiHexZodi
				
			
			mod10mod01end:
				MOV dl, ']'
				CALL IsvestiEkranaChar
				RET
		
	mod11:
		CMP dl, 0
		JNE w1JMP
		
		CMP al, 00000000b
		JE _al	
		CMP al, 00000001b
		JE _cl
		CMP al, 00000010b
		JE _dlJMP	
		CMP al, 00000011b
		JE _blJMP
		CMP al, 00000100b
		JE _ahJMP
		CMP al, 00000101b
		JE _chJMP
		CMP al, 00000110b
		JE _dhJMP
		CMP al, 00000111b
		JE _bhJMP
		
		_al:
			CMP cx, 0
			JNE antras_al
			MOV pirmas_op, offset op_al
			XOR dx, dx
			MOV dl, op_al_r
			MOV pirmas_op_r, dx
			JMP al_isvedimas
			
			antras_al:
				MOV antras_op, offset op_al
				XOR dx, dx
				MOV dl, op_al_r
				MOV antras_op_r, dx
			
			al_isvedimas:
				MOV dx, offset op_al
				CALL IsvestiEkrana
				RET
		_cl:
			CMP cx, 0
			JNE antras_cl
			MOV pirmas_op, offset op_cl
			XOR dx, dx
			MOV dl, op_cl_r
			MOV pirmas_op_r, dx
			JMP cl_isvedimas
			
			antras_cl:
				MOV antras_op, offset op_cl
				XOR dx, dx
				MOV dl, op_cl_r
				MOV antras_op_r, dx
			
			cl_isvedimas:
				MOV dx, offset op_cl
				CALL IsvestiEkrana
				RET
				
		w1JMP:
			JMP w1
		_blJMP:
			JMP _bl
		_dlJMP:
			JMP _dl
		_ahJMP:
			JMP _ah
		_chJMP:
			JMP _ch
		_dhJMP:
			JMP _dh
		_bhJMP:
			JMP _bh
			
		_dl:
			CMP cx, 0
			JNE antras_dl
			MOV pirmas_op, offset op_dl
			XOR dx, dx
			MOV dl, op_dl_r
			MOV pirmas_op_r, dx
			JMP dl_isvedimas
			
			antras_dl:
				MOV antras_op, offset op_dl
				XOR dx, dx
				MOV dl, op_dl_r
				MOV antras_op_r, dx
			
			dl_isvedimas:
				MOV dx, offset op_dl
				CALL IsvestiEkrana
				RET
		
		_bl:
			CMP cx, 0
			JNE antras_bl
			MOV pirmas_op, offset op_bl
			XOR dx, dx
			MOV dl, op_bl_r
			MOV pirmas_op_r, dx
			JMP bl_isvedimas
			
			antras_bl:
				MOV antras_op, offset op_bl
				XOR dx, dx
				MOV dl, op_bl_r
				MOV antras_op_r, dx
			
			bl_isvedimas:
				MOV dx, offset op_bl
				CALL IsvestiEkrana
				RET
		_ah:
			CMP cx, 0
			JNE antras_ah
			MOV pirmas_op, offset op_ah
			XOR dx, dx
			MOV dl, op_ah_r
			MOV pirmas_op_r, dx
			JMP ah_isvedimas
			
			antras_ah:
				MOV antras_op, offset op_ah
				XOR dx, dx
				MOV dl, op_ah_r
				MOV antras_op_r, dx
			
			ah_isvedimas:
				MOV dx, offset op_ah
				CALL IsvestiEkrana
				RET
		_ch:
			CMP cx, 0
			JNE antras_ch
			MOV pirmas_op, offset op_ch
			XOR dx, dx
			MOV dl, op_ch_r
			MOV pirmas_op_r, dx
			JMP ch_isvedimas
			
			antras_ch:
				MOV antras_op, offset op_ch
				XOR dx, dx
				MOV dl, op_ch_r
				MOV antras_op_r, dx
			
			ch_isvedimas:
				MOV dx, offset op_ch
				CALL IsvestiEkrana
				RET
		_dh:
			CMP cx, 0
			JNE antras_dh
			MOV pirmas_op, offset op_dh
			XOR dx, dx
			MOV dl, op_dh_r
			MOV pirmas_op_r, dx
			JMP dh_isvedimas
			
			antras_dh:
				MOV antras_op, offset op_dh
				XOR dx, dx
				MOV dl, op_dh_r
				MOV antras_op_r, dx
			
			dh_isvedimas:
				MOV dx, offset op_dh
				CALL IsvestiEkrana
				RET
		_bh:
			CMP cx, 0
			JNE antras_bh
			MOV pirmas_op, offset op_bh
			XOR dx, dx
			MOV dl, op_bh_r
			MOV pirmas_op_r, dx
			JMP bh_isvedimas
			
			antras_bh:
				MOV antras_op, offset op_bh
				XOR dx, dx
				MOV dl, op_bh_r
				MOV antras_op_r, dx
			
			bh_isvedimas:
				MOV dx, offset op_bh
				CALL IsvestiEkrana
				RET
		
	w1:
		CMP al, 00000000b
		JE _ax	
		CMP al, 00000001b
		JE _cx
		CMP al, 00000010b
		JE _dx	
		CMP al, 00000011b
		JE _bxJMP
		CMP al, 00000100b
		JE _spJMP
		CMP al, 00000101b
		JE _bpJMP
		CMP al, 00000110b
		JE _siw1JMP
		CMP al, 00000111b
		JE _diw1JMP
		
		_ax:
			CMP cx, 0
			JNE antras_ax
			MOV pirmas_op, offset op_ax
			MOV dx, op_ax_r
			MOV pirmas_op_r, dx
			JMP ax_isvedimas
			
			antras_ax:
				MOV antras_op, offset op_ax
				MOV dx, op_ax_r
				MOV antras_op_r, dx
			
			ax_isvedimas:
				MOV dx, offset op_ax
				CALL IsvestiEkrana
				RET
		_cx:
			CMP cx, 0
			JNE antras_cx
			MOV pirmas_op, offset op_cx
			MOV dx, op_cx_r
			MOV pirmas_op_r, dx
			JMP cx_isvedimas
			
			antras_cx:
				MOV antras_op, offset op_cx
				MOV dx, op_cx_r
				MOV antras_op_r, dx
			
			cx_isvedimas:
				MOV dx, offset op_cx
				CALL IsvestiEkrana
				RET
				
		_bxJMP:
			JMP _bx
		_spJMP:
			JMP _sp
		_bpJMP:
			JMP _bp
		_siw1JMP:
			JMP _siw1
		_diw1JMP:
			JMP _diw1		
		
		_dx:
			CMP cx, 0
			JNE antras_dx
			MOV pirmas_op, offset op_dx
			MOV dx, op_dx_r
			MOV pirmas_op_r, dx
			JMP dx_isvedimas
			
			antras_dx:
				MOV antras_op, offset op_dx
				MOV dx, op_dx_r
				MOV antras_op_r, dx
			
			dx_isvedimas:
				MOV dx, offset op_dx
				CALL IsvestiEkrana
				RET
			
		_bx:
			CMP cx, 0
			JNE antras_bx
			MOV pirmas_op, offset op_bx
			MOV dx, op_bx_r
			MOV pirmas_op_r, dx
			JMP bx_isvedimas
			
			antras_bx:
				MOV antras_op, offset op_bx
				MOV dx, op_bx_r
				MOV antras_op_r, dx
			
			bx_isvedimas:
				MOV dx, offset op_bx
				CALL IsvestiEkrana
				RET
		_sp:
			CMP cx, 0
			JNE antras_sp
			MOV pirmas_op, offset op_sp
			MOV dx, op_sp_r
			MOV pirmas_op_r, dx
			JMP sp_isvedimas
			
			antras_sp:
				MOV antras_op, offset op_sp
				MOV dx, op_sp_r
				MOV antras_op_r, dx
			
			sp_isvedimas:
				MOV dx, offset op_sp
				CALL IsvestiEkrana
				RET
		_bp:
			CMP cx, 0
			JNE antras_bp
			MOV pirmas_op, offset op_bp
			MOV dx, op_bp_r
			MOV pirmas_op_r, dx
			JMP bp_isvedimas
			
			antras_bp:
				MOV antras_op, offset op_bp
				MOV dx, op_bp_r
				MOV antras_op_r, dx
			
			bp_isvedimas:
				MOV dx, offset op_bp
				CALL IsvestiEkrana
				RET
		_siw1:
			CMP cx, 0
			JNE antras_si
			MOV pirmas_op, offset op_si
			MOV dx, op_si_r
			MOV pirmas_op_r, dx
			JMP si_isvedimas
			
			antras_si:
				MOV antras_op, offset op_si
				MOV dx, op_si_r
				MOV antras_op_r, dx
			
			si_isvedimas:
				MOV dx, offset op_si
				CALL IsvestiEkrana
				RET
		_diw1:
			CMP cx, 0
			JNE antras_di
			MOV pirmas_op, offset op_di
			MOV dx, op_di_r
			MOV pirmas_op_r, dx
			JMP di_isvedimas
			
			antras_di:
				MOV antras_op, offset op_di
				MOV dx, op_di_r
				MOV antras_op_r, dx
			
			di_isvedimas:
				MOV dx, offset op_di
				CALL IsvestiEkrana
				RET
	
IsvestiReg ENDP

END Pradzia
