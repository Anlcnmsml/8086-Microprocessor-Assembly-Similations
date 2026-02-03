; Anılcan MUŞMUL - 23011622

; SEGMENT TANIMLAMALARI

STACK_SEG SEGMENT PARA STACK 'STACK'
    DB 64 DUP(?)    ; 64 bytelık boş stack alanı
STACK_SEG ENDS

; SABİT VE PORT TANIMLAMALARI

; 8255 PPI çipinin port adresleri (Proteus devresindeki bağlantıya göre)
PORTA    EQU 00H    ; Port A: Çıkış (7-Segment Display bağlı)
PORTB    EQU 02H    ; Port B: Giriş (Buton grubu bağlı)
PORTC    EQU 04H    ; Port C: Kullanılmıyor
PORT_CON EQU 06H    ; Kontrol Yazmacı (Control Register) Adresi

CODE    SEGMENT PUBLIC 'CODE'
    ; Segmentlerin tanımlanması: CS (Code), DS (Data), SS (Stack)
    ASSUME CS:CODE, DS:CODE, SS:STACK_SEG 
    ORG 100H        ; .COM formatı için başlangıç ofseti

; PROGRAM BAŞLANGICI VE KURULUM (INITIALIZATION)

START_INIT:
    ; 1. 8255 KONTROL KELİMESİNİN AYARLANMASI
    ; Amaç: Port A'yı çıkış, Port B'yi giriş olarak ayarlamak.
    MOV DX, PORT_CON    ; DX yazmacına Kontrol Portu adresini (06H) yükle
    
    ; Kontrol Kelimesi (Control Word): 10000010B (82H) analizi:
    ; Bit 7 = 1 (I/O Modu aktif)
    ; Bit 6-5 = 00 (Mod 0 seçimi)
    ; Bit 4 = 0 (Port A -> ÇIKIŞ)
    ; Bit 3 = 0 (Port C Üst -> ÇIKIŞ)
    ; Bit 2 = 0 (Mod 0 seçimi)
    ; Bit 1 = 1 (Port B -> GİRİŞ)
    ; Bit 0 = 0 (Port C Alt -> ÇIKIŞ)
    MOV AL, 10000010B   
    OUT DX, AL          ; Ayarları 8255 çipine gönder

    ; 2. BAŞLANGIÇ DURUMU (RESET)
    ; Devreye enerji verildiğinde ekranda saçma semboller yerine '0' görünsün.
    MOV AL, 11000000B   ; Ortak Anot için '0' rakamının kodu
    MOV DX, PORTA       ; DX'e Port A adresini yükle
    OUT DX, AL          ; Veriyi gönder (Display'i sıfırla)

; ANA DÖNGÜ (MAIN LOOP)
; Sürekli olarak butonları tarar ve ilgili işlemi yapar.
MAIN_LOOP:
    ; 3. BUTONLARI OKUMA (POLLING)
    MOV DX, PORTB       ; DX'e Port B (Giriş) adresini yükle
    IN AL, DX           ; Port B'deki 8 butonun durumunu AL'ye oku

    MOV DX, PORTA       ; Çıkış için DX'i şimdiden Port A'ya ayarla

    ; 4. KARAR YAPISI VE KARŞILAŞTIRMA
    ; Devrede Pull-Up direnci olduğu için butona basılınca ilgili bit '0' olur.
    ; (Active Low Mantığı: 1=Basılı Değil, 0=Basılı)

    CMP AL, 11111110B   ; Bit 0 (En üstteki buton) basılı mı?
    JZ SAYI_0           ; Eşitse (Zero Flag=1), '0' göstermeye git
    
    CMP AL, 11111101B   ; Bit 1 basılı mı?
    JZ SAYI_1           ; Eşitse, '1' göstermeye git
    
    CMP AL, 11111011B   ; Bit 2 basılı mı?
    JZ SAYI_2           ; Eşitse, '2' göstermeye git
    
    CMP AL, 11110111B   ; Bit 3 basılı mı?
    JZ SAYI_3           ; Eşitse, '3' göstermeye git
    
    CMP AL, 11101111B   ; Bit 4 basılı mı?
    JZ SAYI_4           ; Eşitse, '4' göstermeye git
    
    CMP AL, 11011111B   ; Bit 5 basılı mı?
    JZ SAYI_5           ; Eşitse, '5' göstermeye git
    
    CMP AL, 10111111B   ; Bit 6 basılı mı?
    JZ SAYI_6           ; Eşitse, '6' göstermeye git
    
    CMP AL, 01111111B   ; Bit 7 (En alttaki buton) basılı mı?
    JZ SAYI_7           ; Eşitse, '7' göstermeye git

    JMP MAIN_LOOP       ; Hiçbir butona basılmazsa başa dön ve taramaya devam et

; GÖSTERGE GÜNCELLEME RUTİNİ
; Belirlenen hex kodunu Port A'ya yazar.

DISPLAY_OUT:
    OUT DX, AL          ; AL'deki kodu 7-Segment Display'e gönder
    JMP MAIN_LOOP       ; İşlem bitti, tekrar buton dinlemeye dön

; 7-SEGMENT KOD TABLOSU (LOOKUP LOGIC)
; Ortak Anot (Common Anode) Display Mantığı:
; Segmentler: dp g f e d c b a (Bit 7 -> Bit 0)
; Logic 0 = LED YANAR, Logic 1 = LED SÖNER

SAYI_0:
    MOV AL, 11000000B   ; a,b,c,d,e,f YANAR (000000), g ve dp SÖNER (11) -> '0'
    JMP DISPLAY_OUT

SAYI_1:
    MOV AL, 11111001B   ; b,c YANAR (00), diğerleri SÖNER -> '1'
    JMP DISPLAY_OUT

SAYI_2:
    MOV AL, 10100100B   ; a,b,d,e,g YANAR -> '2'
    JMP DISPLAY_OUT

SAYI_3:
    MOV AL, 10110000B   ; a,b,c,d,g YANAR -> '3'
    JMP DISPLAY_OUT

SAYI_4:
    MOV AL, 10011001B   ; b,c,f,g YANAR -> '4'
    JMP DISPLAY_OUT

SAYI_5:
    MOV AL, 10010010B   ; a,c,d,f,g YANAR -> '5'
    JMP DISPLAY_OUT

SAYI_6:
    MOV AL, 10000010B   ; a,c,d,e,f,g YANAR -> '6'
    JMP DISPLAY_OUT

SAYI_7:
    MOV AL, 11111000B   ; a,b,c YANAR -> '7'
    JMP DISPLAY_OUT

CODE ENDS

; PROGRAM SONU
; Linker'a programın başlangıç noktasını (START_INIT) bildirir.
END START_INIT