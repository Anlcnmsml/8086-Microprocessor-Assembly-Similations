;====================================================================
; Anılcan MUŞMUL  23011622
;====================================================================

STACKSG SEGMENT PARA STACK 'STACK'
        DW 128 DUP(?)
STACKSG ENDS

DATASG  SEGMENT PARA 'DATA'
    TAMPON      DB 5 DUP(0) ; ADC verilerini tutacak dizi
    ADC_SAYAC   DW 0        ; Okunan veri sayisi
    TX_SAYAC    DW 0        ; Gonderilen veri sayisi
    SON_VERI    DB 0FFH     ; Degisim kontrolu icin son deger
    
    ; --- DONANIM ADRESLERI ---
    ADRES_8259_L EQU 0000H   
    ADRES_8259_H EQU 0002H   
    ADRES_8251_D EQU 0004H   ; Data register
    ADRES_8251_C EQU 0006H   ; Control register
    ADRES_ADC    EQU 0008H   
DATASG ENDS

CODESG  SEGMENT PARA 'CODE'
        ASSUME CS:CODESG, DS:DATASG, SS:STACKSG

;====================================================================
; GECIKME PROSEDURU
; Islemciyi mesgul ederek simulasyonun donmasini engeller.
;====================================================================
BEKLEME_YAP PROC NEAR
        PUSH CX
        MOV CX, 02FFFH  ; Bekleme suresi
DONGU_1:
        LOOP DONGU_1
        POP CX
        RET
BEKLEME_YAP ENDP

;====================================================================
; SERI_KESME: 8251 Gonderim Kesmesi (IR1 -> INT 51H)
; 5 adet veriyi sirayla terminale basar.
;====================================================================
SERI_KESME PROC FAR
        PUSH BP
        MOV BP, SP
        PUSH AX
        PUSH DX
        PUSH SI
        PUSH DS

        MOV AX, DATASG
        MOV DS, AX

        ; Siradaki veriyi al ve gonder
        MOV SI, TX_SAYAC
        MOV AL, TAMPON[SI]
        MOV DX, ADRES_8251_D
        OUT DX, AL
        
        ; Sayaci bir artir
        INC TX_SAYAC
        
        ; 5 veri bitti mi kontrol et
        CMP TX_SAYAC, 5
        JNE CIKIS_TX         ; Bitmediyse cik

        ; --- PAKET BITTI ---
        MOV TX_SAYAC, 0      ; Sayaci sifirla
        
        ; IR1'i tekrar maskele (Kapat)
        MOV DX, ADRES_8259_H
        IN AL, DX
        OR AL, 00000010B
        OUT DX, AL

        ; ADC indeksini basa al
        MOV ADC_SAYAC, 0
        
        ; Terminal sismesin diye biraz bekle
        CALL BEKLEME_YAP
        
        ; Yeni okuma icin ADC'yi baslat
        MOV DX, ADRES_ADC
        OUT DX, AL

CIKIS_TX:
        POP DS
        POP SI
        POP DX
        POP AX
        POP BP
        IRET
SERI_KESME ENDP

;====================================================================
; ADC_KESME: ADC Okuma Kesmesi (IR2 -> INT 52H)
; Potansiyometre degeri degistiyse kaydeder.
;====================================================================
ADC_KESME PROC FAR
        PUSH BP
        MOV BP, SP
        PUSH AX
        PUSH DX
        PUSH SI
        PUSH DS

        MOV AX, DATASG
        MOV DS, AX

        ; ADC'den veriyi oku
        MOV DX, ADRES_ADC
        IN AL, DX
        
        ; --- DEGISIM KONTROLU ---
        CMP AL, SON_VERI    ; Onceki veriyle ayni mi?
        JE PAS_GEC          ; Ayniysa kaydetme, atla
        
        ; --- FARKLIYSA KAYDET ---
        MOV SON_VERI, AL    ; Yeni degeri sakla
        
        MOV SI, ADC_SAYAC
        MOV TAMPON[SI], AL  ; Diziye at
        
        INC ADC_SAYAC
        CMP ADC_SAYAC, 5
        JNE SONRAKI_CEVRIM  ; 5 olmadiysa devam et

        ; --- 5 VERI TOPLANDI ---
        
        ; 1. IR1 Maskesini Kaldir (Gonderimi Ac)
        MOV DX, ADRES_8259_H
        IN AL, DX
        AND AL, 11111101B
        OUT DX, AL
        
        ; 2. TETIKLEME (Kickstart)
        ; Kenar tetikleme sorunu icin ilk veriyi manuel gonder
        INT 51H             
        
        JMP CIKIS_ADC

PAS_GEC:
        ; Veri degismedi, islemciyi biraz oyala
        CALL BEKLEME_YAP

SONRAKI_CEVRIM:
        ; Bir sonraki ADC donusumunu baslat
        MOV DX, ADRES_ADC
        OUT DX, AL

CIKIS_ADC:
        POP DS
        POP SI
        POP DX
        POP AX
        POP BP
        IRET
ADC_KESME ENDP

;====================================================================
; ANA PROGRAM
;====================================================================
BASLA   PROC FAR
        MOV AX, DATASG
        MOV DS, AX
        CLI                 ; Ayarlar yapilirken kesmeleri kapat

        ;--- 1. IVT (Kesme Vektor Tablosu) Ayarlari ---
        XOR AX, AX
        MOV ES, AX          
        
        ; INT 51H (TX Kesmesi)
        MOV AL, 51H
        MOV AH, 4
        MUL AH              
        MOV BX, AX
        LEA AX, SERI_KESME
        MOV WORD PTR ES:[BX], AX
        MOV AX, CS
        MOV WORD PTR ES:[BX+2], AX

        ; INT 52H (ADC Kesmesi)
        MOV AL, 52H
        MOV AH, 4
        MUL AH              
        MOV BX, AX
        LEA AX, ADC_KESME
        MOV WORD PTR ES:[BX], AX
        MOV AX, CS
        MOV WORD PTR ES:[BX+2], AX

        ;--- 2. 8251A Kurulumu ---
        MOV DX, ADRES_8251_C
        MOV AL, 4DH
        OUT DX, AL
        MOV AL, 40H         ; Reset
        OUT DX, AL
        NOP
        MOV AL, 4DH         ; Mode: 9600 Baud, 8 Data, No Parity
        OUT DX, AL
        MOV AL, 15H         ; Cmd: Tx/Rx Enable
        OUT DX, AL

        MOV DX, ADRES_8251_D
        IN AL, DX
        SHR AL, 1           

        ;--- 3. 8259 PIC Kurulumu ---
        MOV DX, ADRES_8259_L
        MOV AL, 13H         ; Kenar Tetikleme (Edge Trigger)
        OUT DX, AL
        MOV DX, ADRES_8259_H
        MOV AL, 50H         ; Base Vector
        OUT DX, AL
        MOV AL, 03H         ; Auto-EOI
        OUT DX, AL

        ; Sadece IR2 (ADC) acik baslasin
        MOV AL, 0FBH        
        OUT DX, AL

        STI                 ; Kesmeleri aktif et

        ;--- 4. Ilk Baslatma ---
        MOV DX, ADRES_ADC
        OUT DX, AL          

SONSUZ_DONGU:
        NOP
        JMP SONSUZ_DONGU    

        RETF
BASLA   ENDP

CODESG  ENDS
        END BASLA