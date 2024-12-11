.model small
	skBufDydis EQU 256							;Skaitymo buferio dydis
	lentBufDydis EQU 256						;Lenteles buferio dydis nes yra 256 ascii char
	raBufDydis EQU 256							;Rasymo buferio dydis

.stack 100h

.data
	duom db 128 dup(0) 							;Duomenu failo pavadinimas (bagiasi nuliniu simboliu)
	rez db 128 dup(0)  							;Rezultatu failo pavadinimas (bagiasi nuliniu simboliu)
	lent db 128 dup(0) 							;Lenteles failo pavadinimas (bagiasi nuliniu simboliu)
	duomBuf db skBufDydis dup(?)				;Buferis nuskaitytiems duomenu elementams susideti
	lentBuf db lentBufDydis dup(?)				;Buferis nuskaitytiems kodavimo lentos elementams susideti
	rasBuf db raBufDydis dup(?)					;Buferis elementams rasyti i rezultatu faila
	duomFailas dw ?								;Laiko duomenu failo deskriptoriaus numeri
	lentFailas dw ?								;Laiko kodavimo lentos failo deskriptoriaus numeri
	rezFailas dw ?								;Laiko rezultatu failo deskriptoriaus numeri
	
	nuskaitytuBaitSk dw ?
	nuskaitytuBaitSk2 dw ?
	
	klaidAtDuomFailMsg db "Ivyko klaida atidarant duomenu faila$"
	klaidAtLentFailMsg db "Ivyko klaida atidarant lenteles faila$"
	klaidAtRezFailMsg db "Ivyko klaida atidarant rezultatu faila$"
	klaidSkFailMsg db "Ivyko klaida skaitant faila$"
	klaidRaFailMsg db "Ivyko klaida rasant faila$"
	klaidParamMsg db "Veskite vienu tarpu atskirtus duomenu, rezultatu ir lenteles failu pavadinimus pvz: 3uzd duom.txt rez.txt lent.txt$"
	pabaigosMsg db "Failas sekmingai uzkoduotas$"

.code
pradzia:
	MOV ax, @data				
	MOV ds, ax									;I duomenu segmenta ikeliam data
	
	MOV al, es:[80h]							;Ekstra segmento 80h baite laikomas skaicius kiek parametru baitu irase vartotojas
	CMP al, 0									;Jei vartotojas neirase parametru rodoma klaida
	JE klaidaParametruose

	MOV di, 81h									;Nuo ekstra segmento 81h baito laikomi ivestu parametru charai

	CALL praleistiTarpus

	CALL ArPagalba								;Tikrina ar irasyta '/?'
	CMP bx, 1									;Jei taip bx = 1 ir rodoma klaida
	JE klaidaParametruose

	MOV di, 81h									;Nuo ekstra segmento 81h baito laikomi ivestu parametru charai
	
	CALL praleistiTarpus
	
	MOV si, offset duom
	CALL SkaitytiPav							;Gaunam duomenu failo pavadinima is parametru
	
	CALL praleistiTarpus
	
	MOV si, offset rez							
	CALL SkaitytiPav							;Gaunam rezultatu failo pavadinima is parametru
	
	CALL praleistiTarpus
	
	MOV si, offset lent							
	CALL SkaitytiPav							;Gaunam kodavimo leneteles failo pavadinima is parametru
	
	JMP skaitymas
	
;-------------------------------------------
;Klaidu apdorojimas
;-------------------------------------------	
klaidaParametruose:
	MOV dx, offset klaidParamMsg
	CALL IsvestiIEkrana
	JMP pabaiga

klaidaAtidarantDuomFaila:
	MOV dx, offset klaidAtDuomFailMsg
	CALL IsvestiIEkrana
	JMP pabaiga

klaidaAtidarantLentFaila:
	MOV dx, offset klaidAtLentFailMsg
	CALL IsvestiIEkrana
	JMP pabaiga

klaidaAtidarantRezFaila:
	MOV dx, offset klaidAtRezFailMsg
	CALL IsvestiIEkrana
	JMP pabaiga
	
klaidaSkaitantFaila:
	MOV dx, offset klaidSkFailMsg
	CALL IsvestiIEkrana
	JMP pabaiga
	
klaidaRasantFaila:
	MOV dx, offset klaidRaFailMsg
	CALL IsvestiIEkrana
	JMP pabaiga

;-------------------------------------------
;Duomenu failo atidarymas skaitymui
;-------------------------------------------
skaitymas:
	MOV ah, 3Dh
	MOV al, 00 									;Failas atidaromas tik skaitymui
	MOV dx, offset duom							;Failo pavadinima laikantis buferis nukeliamas i dx registra
	INT 21h
	JC klaidaAtidarantDuomFaila					;Jei CF = 1, tai ivyko klaida atidarant faila, nusoka i klaidaSkaitantFaila segmenta
	MOV duomFailas, ax							;Kintamajam duomFailas priskiria failo deskriptoriu (handle)
	
;-------------------------------------------
;Lenteles failo atidarymas skaitymui
;-------------------------------------------
	MOV ah, 3Dh
	MOV al, 00 									;Failas atidaromas tik skaitymui
	MOV dx, offset lent							;Failo pavadinima laikantis buferis nukeliamas i dx registra
	INT 21h
	JC klaidaAtidarantLentFaila					;Jei CF = 1, tai ivyko klaida atidarant faila, nusoka i klaidaSkaitantFaila segmenta
	MOV lentFailas, ax							;Kintamajam lenFailas priskiria failo deskriptoriu (handle)
	
;-------------------------------------------
;Rezultatu failo sukurimas
;-------------------------------------------
	MOV ah, 3Ch
	MOV dx, offset rez							;Failo pavadinima laikantis buferis nukeliamas i dx registra
	INT 21h
	JC klaidaAtidarantRezFaila					;Jei CF = 1, tai ivyko klaida atidarant faila, nusoka i klaidaSkaitantFaila segmenta
	MOV rezFailas, ax							;Kintamajam rezFailas priskiria failo deskriptoriu (handle)	

;-------------------------------------------
;Duomenu skaitymas ir susidejimas i buferi
;-------------------------------------------
	MOV bx, duomFailas							;BX priskiriam lentos failo deskriptoriu
	MOV cx, skBufDydis							;CX priskiriam kiek baitu reikia nuskaityti
	MOV dx, offset duomBuf						;DX priskiriam skaitymo buferio adresa
	CALL SkaitytiFaila							;Iskvieciam funkcija failui nuskaityti
	CMP ax, -1									;Jei ax = -1 ivyko klaida skaityme
	JE klaidaSkaitantFaila						;Jei nuskaitytu baitu skaicius nelygus buferio dydziui ivyko klaida skaityme
	MOV nuskaitytuBaitSk, ax					;Isidedam nuskaitytu baitu skaciu i kintamaji

;-------------------------------------------
;Lenteles skaitymas ir susidejimas i buferi
;-------------------------------------------
	MOV bx, lentFailas							;BX priskiriam lentos failo deskriptoriu
	MOV cx, lentBufDydis						;CX priskiriam skaitymo buferio dydis
	MOV dx, offset lentBuf						;DX priskiriam skaitymo buferio adresa
	CALL SkaitytiFaila							;Iskvieciam funkcija failui nuskaityti
	CMP ax, -1									;Jei ax = -1 ivyko klaida skaityme
	JE klaidaSkaitantFaila						;Jei nuskaitytu baitu skaicius nelygus buferio dydziui ivyko klaida skaityme
	
;-------------------------------------------
;Duomenu skaitymas is failo, uzkodavimas pagal lentele ir rasymas i rezultatu faila po charaketeri
;-------------------------------------------
	MOV si, offset duomBuf
	MOV di, offset rasBuf
	MOV cx, nuskaitytuBaitSk
	MOV bx, 0

;Koduoja kol cx nera lygu 0
koduoti:
	MOV bl, [si]								;Gaunam char is duomenu buferio ir isidedam i bl
	MOV al, [lentBuf + bx]						;Randam lenteleje esanti atitinkama char pagal bx reiksme ir isidedam i al
	MOV [di], al								;I rasymo buferi idedam kodavimo lenteleje rasta chara
	INC si										;Padidinam si ir di kad skaityti ir rasyti kita atitinkamu buferiu pozicija
	INC di
	LOOP koduoti								;Jei cx nelygu 0 kartojam
	
	CALL RasytIFaila							;Rasom uzkuoduota teksta i faila
	CMP ax, -1									;Jei ax = -1 ivyko klaida rasyme
	JE klaidaRasantFaila
	
	MOV dx, offset pabaigosMsg
	CALL IsvestiIEkrana
	JMP pabaiga

;-------------------------------------------
;Funkcija patikrinanti ar prasoma pagalbos
;-------------------------------------------	
PROC ArPagalba
	MOV ax, es:[di]								;I ax nuskaitomi 2 baitai i al pirmas char i ah antras char is param eilutes
	CMP al, 2Fh									;Patikrina ar al = '/'
	JNE nePagalba						
	CMP ah, 3Fh									;Patikrina ar ah = '?'
	JNE nePagalba
	MOV bx, 1									;Nustatom bx=1, kad zinotume, jog reikia pagalbos
	RET
	
nePagalba:
	RET
	
ArPagalba ENDP

;-------------------------------------------
;Funkcija isvedanti klaidos zinute i ekrana
;-------------------------------------------	
PROC IsvestiIEkrana	
	MOV ah, 9
	INT 21h
	RET
	
IsvestiIEkrana ENDP

;-------------------------------------------
;Funkcija praleidzianti tarpus 
;-------------------------------------------	
PROC PraleistiTarpus
praleistiTarpus:	
	MOV al, es:[di]								;Gauna baita is ekstra segmento 
	
	CMP al, 20h									;Jei al = tarpas veikia toliau kol tarpu nebera
	JE padidintiDI
	RET

padidintiDI:
	INC di
	JMP praleistiTarpus
	
PraleistiTarpus ENDP

;-------------------------------------------
;Funkcija failo pavadinimui is argumentu eilutes skaityti
;-------------------------------------------	
PROC SkaitytiPav
skaitytiPav:	
	MOV al, es:[di]								;Gauna baita is ekstra segmento 
	INC di
	
	CMP al, 13									;Jei al = enter arba al = tarpas baigiam skaityti
	JE skaitPavPab
	CMP al, 20h
	JE skaitPavPab

	
	MOV [si], al								;I failo pavadinimo buferi irasom gauta baita
	INC si
	JMP skaitytiPav
	
skaitPavPab:
	RET
	
SkaitytiPav ENDP

;-------------------------------------------
;Funkcija failui skaityti
;-------------------------------------------	
PROC SkaitytiFaila
	MOV ah, 3Fh
	INT 21h
	JC klaidaSk									;Jei skaitant faila ivyko klaida 
	RET
	
klaidaSk:
	MOV ax, -1
	RET
	
SkaitytiFaila ENDP

;-------------------------------------------
;Funkcija rezultatu buferiui irasyti i faila
;-------------------------------------------	
PROC RasytIFaila
	MOV ah, 40h
	MOV bx, rezFailas
	MOV cx, nuskaitytuBaitSk
	MOV dx, offset rasBuf
	INT 21h
	JC klaidaRasant								;Jei rasant faila ivyko klaida 
	RET
	
klaidaRasant:
	MOV ax, -1
	RET
	
RasytIFaila ENDP
	
pabaiga:
	MOV ah, 4Ch
	MOV al, 0
	INT 21h
	
END pradzia