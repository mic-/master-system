; Written by XPMC at 15:12:37 on Monday March 30, 2009.

.DEFINE XPMP_EN2MAC_NOT_USED
xpmp_dt_mac_tbl:
xpmp_dt_mac_loop_tbl:

xpmp_v_mac_0:
.db $0A, $0A, $09, $08, $07, $06, $04, $80
xpmp_v_mac_0_loop:
.db $02, $80
xpmp_v_mac_78:
.db $0B, $0A, $09, $80
xpmp_v_mac_78_loop:
.db $04, $80
xpmp_v_mac_88:
.db $09, $09, $09, $09, $09, $09, $09, $09, $08, $80
xpmp_v_mac_88_loop:
.db $07, $80
xpmp_v_mac_89:
.db $09, $09, $09, $08, $08, $08, $08, $08, $07, $80
xpmp_v_mac_89_loop:
.db $06, $80
xpmp_v_mac_tbl:
.dw xpmp_v_mac_0
.dw xpmp_v_mac_78
.dw xpmp_v_mac_88
.dw xpmp_v_mac_89
xpmp_v_mac_loop_tbl:
.dw xpmp_v_mac_0_loop
.dw xpmp_v_mac_78_loop
.dw xpmp_v_mac_88_loop
.dw xpmp_v_mac_89_loop

xpmp_VS_mac_tbl:
xpmp_VS_mac_loop_tbl:

xpmp_EP_mac_5:
.db $06, $FE, $FE, $FF, $FF, $80
xpmp_EP_mac_5_loop:
.db $00, $80
xpmp_EP_mac_6:
.db $FA, $02, $02, $01, $01, $80
xpmp_EP_mac_6_loop:
.db $00, $80
xpmp_EP_mac_tbl:
.dw xpmp_EP_mac_5
.dw xpmp_EP_mac_6
xpmp_EP_mac_loop_tbl:
.dw xpmp_EP_mac_5_loop
.dw xpmp_EP_mac_6_loop

xpmp_EN_mac_10:
.db 0
xpmp_EN_mac_10_loop:
;.db $01, $00, $02, $00, $FD, $00, $80
.db -5,3,2,0,$80 
xpmp_EN_mac_tbl:
.dw xpmp_EN_mac_10
xpmp_EN_mac_loop_tbl:
.dw xpmp_EN_mac_10_loop

xpmp_MP_mac_2:
.db $04, $04, $05
xpmp_MP_mac_tbl:
.dw xpmp_MP_mac_2

xpmp_CS_mac_tbl:
xpmp_CS_mac_loop_tbl:

xpmp_callback_tbl:

xpmp_pattern1:
.db $FB,$02,$13,$0B,$0E,$10,$0B,$07,$08,$0B,$07,$08,$0C,$0E,$10,$0B
.db $0E,$10,$0B,$0E,$10,$42,$07,$08,$04,$07,$08,$0C,$0E,$10,$09,$07
.db $08,$0B,$07,$08,$56,$0E,$10,$46,$07,$08,$56,$07,$08,$0C,$0E,$10
.db $09,$07,$08,$0A,$07,$08,$0B,$0E,$10,$49,$07,$08,$0B,$07,$08,$0C
.db $0E,$10,$59,$07,$08,$0A,$07,$08,$FA,$02,$00,$97
xpmp_pattern2:
.db $44,$0E,$10,$04,$07,$08,$04,$07,$08,$0C,$0E,$10,$04,$0E,$10,$04
.db $0E,$10,$07,$07,$08,$09,$07,$08,$0C,$0E,$10,$42,$07,$08,$04,$07
.db $08,$14,$5B,$0E,$10,$0B,$07,$08,$0B,$07,$08,$0C,$0E,$10,$0B,$0E
.db $10,$0B,$0E,$10,$42,$07,$08,$04,$07,$08,$0C,$0E,$10,$09,$07,$08
.db $0B,$07,$08,$04,$0E,$10,$04,$07,$08,$04,$07,$08,$0C,$0E,$10,$04
.db $0E,$10,$04,$0E,$10,$07,$07,$08,$09,$07,$08,$0C,$0E,$10,$42,$07
.db $08,$04,$07,$08,$56,$0E,$10,$06,$07,$08,$06,$07,$08,$0C,$0E,$10
.db $06,$0E,$10,$06,$0E,$10,$09,$07,$08,$0B,$07,$08,$0C,$0E,$10,$44
.db $07,$08,$06,$07,$08,$97
xpmp_pattern3:
.db $FB,$02,$13,$09,$0E,$10,$09,$07,$08,$09,$07,$08,$0C,$0E,$10,$09
.db $0E,$10,$09,$0E,$10,$40,$07,$08,$02,$07,$08,$0C,$0E,$10,$07,$07
.db $08,$09,$07,$08,$5B,$0E,$10,$4B,$07,$08,$5B,$07,$08,$0C,$0E,$10
.db $0B,$0E,$10,$0B,$0E,$10,$42,$07,$08,$04,$07,$08,$0C,$0E,$10,$09
.db $07,$08,$0B,$07,$08,$13,$09,$0E,$10,$09,$07,$08,$09,$07,$08,$0C
.db $0E,$10,$09,$0E,$10,$09,$0E,$10,$40,$07,$08,$02,$07,$08,$0C,$0E
.db $10,$07,$07,$08,$09,$07,$08,$06,$0E,$10,$06,$07,$08,$06,$07,$08
.db $0C,$0E,$10,$06,$0E,$10,$06,$0E,$10,$09,$07,$08,$0B,$07,$08,$0C
.db $0E,$10,$44,$07,$08,$06,$07,$08,$FA,$02,$00,$97

xpmp_pattern_tbl:
.dw xpmp_pattern1
.dw xpmp_pattern2
.dw xpmp_pattern3

xpmp_s1_channel_A:
.db $F1,$03,$F5,$01,$96,$00,$96,$01,$96,$02,$96,$00,$96,$01,$96,$00
.db $96,$02,$96,$00,$96,$01,$F9,$04,$00
xpmp_s1_channel_B:
.db $0C,$70,$80,$0C,$70,$80,$0C,$70,$80,$0C,$70,$80,$0C,$0E,$10,$13
.db $F1,$02,$F8,$01,$F6,$01,$FB,$04,$FB,$02,$4B,$07,$08,$5B,$07,$08
.db $5B,$0E,$10,$4B,$07,$08,$4B,$07,$08,$0C,$0E,$10,$0B,$07,$08,$5B
.db $07,$08,$5B,$0E,$10,$13,$4B,$07,$08,$5B,$07,$08,$0C,$0E,$10,$FA
.db $1A,$00,$FA,$18,$00,$F9,$0F,$00
xpmp_s1_channel_C:
.db $0C,$03,$84,$F1,$04,$F6,$02,$96,$00,$96,$01,$96,$02,$96,$00,$96
.db $01,$96,$00,$96,$02,$96,$00,$96,$01,$F9,$07,$00
xpmp_s1_channel_D:
.db $16,$F1,$01,$20,$FB,$08,$02,$1C,$20,$0C,$1C,$20,$FA,$06,$00,$FB
.db $10,$02,$1C,$20,$FA,$11,$00,$FB,$08,$02,$1C,$20,$00,$1C,$20,$FA
.db $19,$00,$FB,$03,$02,$1C,$20,$00,$15,$18,$02,$07,$08,$02,$0E,$10
.db $02,$0E,$10,$00,$1C,$20,$FA,$24,$00,$02,$1C,$20,$00,$15,$18,$02
.db $07,$08,$02,$0E,$10,$02,$0E,$10,$00,$07,$08,$00,$07,$08,$00,$07
.db $08,$00,$07,$08,$FB,$02,$02,$1C,$20,$00,$1C,$20,$02,$1C,$20,$00
.db $1C,$20,$02,$1C,$20,$00,$15,$18,$02,$07,$08,$02,$0E,$10,$02,$0E
.db $10,$00,$07,$08,$00,$07,$08,$00,$07,$08,$00,$07,$08,$FA,$56,$00
.db $F9,$22,$00

xpmp_song_tbl:
.dw xpmp_s1_channel_A
.dw xpmp_s1_channel_B
.dw xpmp_s1_channel_C
.dw xpmp_s1_channel_D
