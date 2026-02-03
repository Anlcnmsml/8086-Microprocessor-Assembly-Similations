; Anılcan Muşmul 23011622

; 200H -> DAC
; 400H -> ADC
; 800H -> INTR Durumu

STAK	SEGMENT PARA STACK 'STACK'
        DW 20 DUP(?)
STAK	ENDS

CODE	SEGMENT PARA 'CODE'
        ASSUME CS:CODE, SS:STAK

START 	PROC FAR

BASLA:
        ; ADC donusumunu baslatiyoruz (400H adresine yazarak)
        MOV DX, 0400H
        OUT DX, AL

        ; INTR ucunu kontrol et (800H adresi)
        ; Donusum bitene kadar (D7 biti 0 olana kadar) bekler
        MOV DX, 0800H
        
KONTROL:
        IN AL, DX           ; Durumu oku
        TEST AL, 80H        ; D7 bitine bak
        JNZ KONTROL         ; Bit 1 ise (donusum bitmediyse) tekrar kontrol et

        ; Donusum bitti, veriyi ADC'den oku
        MOV DX, 0400H
        IN AL, DX

        ; --- Filtreleme Kismi ---
        ; Isik kapaliyken olusan kucuk voltaji yok etmek icin
        ; Eger okunan deger 15'ten kucukse motoru tam durdur.
        
        CMP AL, 15          ; 15 (0FH) esik degeri
        JB DURDUR           ; 15'ten kucukse DURDUR etiketine git
        JMP SUR             ; Degilse motoru surmeye git

DURDUR:
        MOV AL, 0           ; Motoru tamamen durdurmak icin 0 yapiyoruz
        JMP CIKIS           ; DAC'a gondermek icin atla

SUR:
        ; Normal calisma durumu, AL degeri degismez.

CIKIS:
        ; DAC'a veriyi gonder (200H adresi)
        MOV DX, 0200H
        OUT DX, AL
        
        JMP BASLA           ; Basa don

START 	ENDP
CODE	ENDS
        END START