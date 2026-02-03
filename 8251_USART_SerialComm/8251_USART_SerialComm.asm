; Anılcan MUŞMUL - 23011622

STACKSG SEGMENT PARA STACK 'STACK'
        DW 128 DUP(?)
STACKSG ENDS

DATASG  SEGMENT PARA 'DATA'
    ; Gelen verileri saklamak icin 100 byte'lik buffer
    BUFFER  DB 100 DUP(?) 
    COUNT   DW 0000H        ; Gecerli karakter sayaci
DATASG  ENDS

CODE    SEGMENT PUBLIC 'CODE'
        ASSUME CS:CODE, SS:STACKSG, DS:DATASG

START:
    ; --- SEGMENT AYARLARI ---
    PUSH DS
    XOR AX, AX
    PUSH AX
    MOV AX, DATASG
    MOV DS, AX
    
    ; --- 8251 USART INIT ---
    ; Adresler: Control=015AH, Data=0158H
    MOV DX, 015AH   
    
    ; Resetleme Dizisi
    XOR AL, AL      
    OUT DX, AL
    NOP
    OUT DX, AL
    NOP
    OUT DX, AL
    
    MOV AL, 40H             ; INTERNAL RESET
    OUT DX, AL
    NOP
    
    ; MODE WORD: 0100 1101B = 4DH
    ; 1 Stop, No Parity, 8 Data, x1 Factor (9600Hz Clock icin)
    MOV AL, 4DH             
    OUT DX, AL
    
    ; COMMAND WORD: 0001 0101B = 15H
    ; RTS=0, ER=1, RxE=1, TxE=1
    MOV AL, 15H             
    OUT DX, AL

    ; Buffer indeksini sifirla (SI kullanacagiz)
    XOR SI, SI

; --- VERI ALMA DONGUSU (TERMINAL 1) ---
ENDLESS:
    MOV DX, 015AH           ; Control Port
TEKRAR:
    IN AL, DX
    TEST AL, 02H            ; RxRDY kontrolu (Bit 1)
    JZ TEKRAR               ; Veri yoksa bekle
    
    MOV DX, 0158H           ; Data Port
    IN AL, DX               ; Veriyi oku
    
    SHR AL, 1               

    ; --- KONTROLLER ---
    
    ; 1. Bitirme Kontrolu: '0' mi?
    CMP AL, '0'
    JE START_OUTPUT         ; '0' ise cikisa git

    ; 2. Filtreleme: A-Z arasi mi?
    CMP AL, 'A'
    JB ENDLESS              ; 'A'dan kucukse yoksay (basa don)
    CMP AL, 'Z'
    JA ENDLESS              ; 'Z'den buyukse yoksay (basa don)

    ; --- KAYIT ---
    ; Gecerli karakteri buffer'a kaydet
    MOV BUFFER[SI], AL      ; Buffer'a yaz
    INC SI                  ; Sayaci artir
    JMP ENDLESS             ; Yeni veri bekle

; --- CIKIS ISLEMI (TERMINAL 2) ---
START_OUTPUT:
    ; SI su an toplam karakter sayisini tutuyor
    MOV CX, SI              ; Toplam sayiyi CX'e al
    CMP CX, 0
    JE FINISH               ; Hic veri yoksa bitir

    ; Son 3 karakter mantigi
    ; Eger karakter sayisi > 3 ise, baslangic indeksini (SI) son 3'e ayarla
    ; Eger <= 3 ise, bastan basla (SI=0)
    
    CMP CX, 3
    JBE SET_PRINT_ALL       ; 3 veya daha azsa hepsini yaz
    
    ; 3'ten fazla karakter var
    SUB SI, 3               ; SI pointer'ini son 3 karakterin basina cek
    MOV CX, 3               ; Sadece 3 karakter yazilacak
    JMP PRINT_LOOP

SET_PRINT_ALL:
    XOR SI, SI              ; Bastan basla

PRINT_LOOP:
    MOV AL, BUFFER[SI]      ; Siradaki karakteri al
    
    ; --- SIFRELEME ---
    ADD AL, 3               ; ASCII degerini 3 artir

    ; --- TX READY KONTROLU ---
    PUSH AX                 ; Veriyi sakla
    
    MOV DX, 015AH           ; Control Port
CHECK_TX:
    IN AL, DX               ; Status oku
    TEST AL, 01H            ; TxRDY kontrolu
    JZ CHECK_TX             ; Mesgulse bekle
    
    ; --- GONDERME ---
    POP AX                  ; Veriyi geri yukle
    
    MOV DX, 0158H           ; Data Port
    OUT DX, AL              ; Karakteri gonder (Terminal 2'ye)

    INC SI                  ; Sonraki karakter
    LOOP PRINT_LOOP         ; CX bitene kadar don

FINISH:
    HLT                 ; İşlem biter ve işlemci durur
    JMP FINISH         

CODE    ENDS
        END START