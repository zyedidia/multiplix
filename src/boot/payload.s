#define XSTR(s) STR(s)
#define STR(s) #s

.section .payload
    .global payload
    .align  4
payload:
    .incbin XSTR(PAYLOAD)
payload_end:
    .global payload_size
    .align  4
payload_size:
    .int    payload_end - payload
