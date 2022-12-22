#define XSTR(s) STR(s)
#define STR(s) #s

.section .rodata
    .global payload
    .type   payload, @object
    .align  4
payload:
    .incbin XSTR(PAYLOAD)
payload_end:
    .global payload_size
    .type   payload_size, @object
    .align  4
payload_size:
    .int    payload_end - payload
