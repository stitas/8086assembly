.model small
					
.stack 100h

.data

	startHintMsg db "Iveskite skaciu nuo 0 iki 65535: $"
	endHintMsg db "Ivestas skaicius sesioliktainiu pavidalu: $"

.code
start:

	MOV ax, @data		;reikalinga kiekvienos programos pradžioj
	MOV ds, ax			;reikalinga kiekvienos programos pradžioj
	
	MOV cx, 10			;cx 10 nes dauginsim is 10
	MOV bx, 0			;bx bus galutinis skaicius
	
	MOV ah, 9
	MOV DX, offset startHintMsg
	int 21h
                           
input:
	MOV ah, 1			;Praso ivest chara
	INT 21h				
	CMP al, 13 			;Patikrina ar ivestas enter
	JE end_input		;Jei enter soka i end_input
	SUB al, 48			;Pavercia is char i skaciu
	MOV ah, 0			;Nes ah yra 1, todel ax nebutu ivestas skaicius
	PUSH ax				;ax ideda i stacka
	MOV ax, bx			;ax priskiria dabartini skaiciu
	MUL cx				;ax padaugina is 10 kad prie jo galo butu galima pridet skaiciu
	MOV bx, ax			;bx priskiria skaiciu padauginta is 10
	POP ax				;is stacko gauna ivesta skaiciu
	ADD bx, ax			;prie dabartinio skaiciaus galo prideda ivesta skaiciu
	JMP input			;Kartoja input per naujo
	

end_input:
	MOV ax, bx
	MOV cx, 16			;Nes dalinsim is 16
	MOV bx, 0			;Kiek skaciu yra ideta i stacka
	
divide:
	DIV cx				;Padalina ax is 16
	PUSH dx				;Ideda liekana i stacka
	MOV dx, 0
	INC bl				;Padidinam skaiciu stacke skaiciu
	CMP ax, 0
	JNE divide			;Jei ax ne lygu 0 kartojam cikla
	
	MOV ah, 9			
	MOV DX, offset endHintMsg
	int 21h
	
output:
	POP ax				;Is stacko paimam paskutine ideta liekana
	INC bh				;Padidinam is stacko paimtu skaiciu skaiciu
	CMP al, 9			
	JG output_hex		;Jei liekana didesne uz 9 tada i ekrana reikia isvesti raide
	
output_dec:
	ADD al, 48
	MOV ah, 2			;Char isvedimo i ekrana funkcija
	MOV dl, al 
	INT 21h
	CMP bh, bl			;Patikrinam ar is stacko paimtu skaiciu kiekis lygus i stacka idetu skaiciu kiekiui
	JE stop				;Jei lygus stabdom programa
	JMP output

output_hex:
	ADD al, 55			;Pridedam ascii koda kad gauti raide
	MOV ah, 2			;Char isvedimo i ekrana funkcija
	MOV dl, al
	INT 21h
	CMP bh, bl			;Patikrinam ar is stacko paimtu skaiciu kiekis lygus i stacka idetu skaiciu kiekiui
	JNE output			;Jei ne lygus kartoja cikla
	
stop:
	MOV	ah, 4Ch			;reikalinga kiekvienos programos pabaigoj
	MOV	al, 0			;reikalinga kiekvienos programos pabaigoj
	INT	21h				;reikalinga kiekvienos programos pabaigoj

END	start