.include "m8def.inc"

;Значения для бод рейт регистра
.equ UBBRVALUEV = 0x0033;из учета того, что 8мгц, кварц и мы расчитываем на передачу со скоростью 9600бод, то пишем такое число, есть формула, но я воспользовался калькулятором.
;Настройка интревалов Таймеров
.equ TIMER1_INTERVAL = 222;таймер может считать только от 0 до 255, чтобы он быстро не переполнялся(ну и говно же таймеры в восьмибитных МК)
.equ TIMER2_INTERVAL = 250;выставляем значение побольше и делаем так, чтобы сначала у нас был пинг, а потом понг поэтому пинг должен переполняться раньше, чем понг

.cseg                               ;Программный сегмент
.org 0x000                          ;Установить положение в сегменте
rjmp MAIN                           ;переход в мейн
.org $009                         ;Установить положение в сегменте   
rjmp TIM0_OVF                       ;обработчик прерывания по таймеру1(который на самом деле 0) 
.org $004                          ;Установить положение в сегменте  
rjmp TIM2_OVF                       ;обработчик прерывания по таймеру2(который на самом деле 2,((СТРАННО))) 

RESET: ; инициализация стека
    ldi r16, HIGH(RAMEND)
    out SPH, r16
    ldi r16, LOW(RAMEND)
    out SPL, r16


;по хорошему каждый таймер инициализируется самостоятельно
TIMER1_SETUP:
    ldi r16, TIMER1_INTERVAL;пишем в регистр общего назначения константу, а можно и не константу
    out TCNT0, r16          ;выставляем до какого значения будет шлепать таймер
    ldi r16, 0b111           ;по хорошему так делать не надо тк параметры остальные можно сбить в регистре TCCR2 и 0 соотв, но похрену, сбилдилось и нормально
    out TCCR0, r16          ;выставляем предделитель частоты равный 1024, чтобы 8мгц поделиось на 8 и получилось 7812гц, соответственно таймер будет тикать 1 раз в 1/7812 секунд
    ldi r16, 0b101          ;выставление предделителя у каждого таймера разный, поэтому пишем и туда и сюда свое число
    out TIMSK, r16
    ret

TIMER2_SETUP:
    ldi r16, TIMER2_INTERVAL;был бы 1 таймер не было бы геморроя с пересчетом этой херни, но что есть то есть
    out TCNT2, r16
    ldi r16, 0b101          ;выставление предделителя у каждого таймера разный, поэтому пишем и туда и сюда свое число
    out TCCR2, r16          ;тут такая же штука
    ldi r16, 0x41
    out TIMSK, r16
    ret

UART_INIT: ;все пишут, что настройка усарт это, а это нихрена не усарт, а уарт, тк у нас нету клокового сигнала в подключении!!!!
    ldi r16, high(UBBRVALUEV);посчитанное значение для числа 9200бод пишем в брр регистр сначала в старшие биты, потом в младшие
    out UBRRH, r16
    ldi r16, low(UBBRVALUEV)
    out UBRRL, r16

    ldi r16, 0x18
    out UCSRB, r16
    ldi r16, 0x86
    out UCSRC, r16
    ret
 
;собственно слова
ping: ;метка слова пинг
    .db "ping\r\n", 0 ,0
pong: ;метка слова понг, заюзается в дальнейшем выводе
    .db "pong\r\n", 0 ,0
    
;PING
START_SEND_PING:
    ldi r18, TIMER1_INTERVAL;как только мы пришли в начало отправки слова пинг, то сбрасываем таймер, чтобы опять он считал по новой
    out TCNT0, r18

    ldi ZH, high(2*ping);тут так делаем для того, чтобы пихнуть слово
    ldi ZL, low(2*ping)
NEW_BYTE_ping:
    lpm r17, Z+
    cpi r17, 0
    breq END_SEND_ping 
    rcall TRANSMIT_BYTE 
    rjmp NEW_BYTE_ping
END_SEND_ping:
    ret

;PONG(удивительно)
START_SEND_pong:
    ldi r19, TIMER2_INTERVAL;ресетим регистр для того, чтобы по новой начал шлепать
    out TCNT2, r19

    ldi ZH, high(2*pong);с этим трудно разбираться, но вот тут из двух восьмибитных регистров получается 1 16битный и называется он Z, так делается отправка в уарт
    ldi ZL, low(2*pong)
NEW_BYTE_pong:
    lpm r17, Z+
    cpi r17, 0
    breq END_SEND_pong 
    rcall TRANSMIT_BYTE 
    rjmp NEW_BYTE_pong
END_SEND_pong:
    ret

TRANSMIT_BYTE:;пихаем то говно, что лежит в датарегистре на выход
    sbis UCSRA, UDRE
    rjmp TRANSMIT_BYTE 
    out UDR, r17
    ret 
    
MAIN:;вызов всяких функций
    rcall RESET
    rcall UART_INIT
    rcall TIMER1_SETUP
    rcall TIMER2_SETUP
    sei;смена флага прерывания, т.е. разрешили их
LOOP:
    rjmp LOOP

;це обработчики прерываний, как только таймер 0 дошлепал, хреначим пинг и идем дальше считать, та же самая штука и с понгом, только он попозже
TIM0_OVF:;называються они должны ВСЕГДА так, тк это прописано в референс мануале.
    sei
    rcall START_SEND_PING
    reti

TIM2_OVF:
    sei
    rcall START_SEND_pong
    reti
