DATA SEGMENT
    ; 8086IO口
    IO2 EQU 0400H   ; 8253A
    IO4 EQU 0800H   ; 8255A 
    
    IO82530      EQU IO2      ; T0地址
    IO82531      EQU IO2 + 2  ; T1地址
    IO8253_CTR   EQU IO2 + 6  ; 8253A控制口地址
    
    IO8255A EQU IO4          ; 8255 A口地址
    IO8255B EQU IO4 + 2      ; 8255 B口地址
    IO8255C EQU IO4 + 4      ; 8255 C口地址 
    IO8255K  EQU  IO4 + 6 ; 8255 控制口地址
    
    CNTVAL EQU 1000H ; 计数初值
    
    LED DB 3FH,06H,5BH,4FH,66H,6DH,7DH,07H,7FH,6FH
    ;0--9 对应段选码，共阴极 
    
    HOU DB 00H ; 时 
    MIN DB 00H ; 分 
    SEC DB 00H ; 秒
    
DATA ENDS

STACK SEGMENT
    DW   200  DUP(0) 
STACK ENDS

CODE SEGMENT  
    ASSUME CS:CODE,DS:DATA,SS:STACK
    
START:
    ; 数据段设置
    MOV AX, DATA
    MOV DS, AX
    MOV ES, AX
    
    ; NMI中断向量初始化
    PUSH ES
    XOR AX, AX 
    MOV ES, AX
    MOV AL, 02H ; NMI中断类型号为02H
    XOR AH, AH
    SHL AX, 1   
    SHL AX, 1   
    MOV SI, AX
    MOV AX, OFFSET NMI_SERVICE 
    MOV ES: [SI], AX
    INC SI
    INC SI
    MOV BX, CS
    MOV ES: [SI], BX
    POP ES   
    
    ; 初始化8253
    MOV AL, 00110101B ; T0 读写16位 方式2 BCD计数
    MOV DX, IO8253_CTR   
    OUT DX, AL
    MOV DX, IO82530        
    MOV AX, CNTVAL    ; 1000分频
    OUT DX, AL
    
    MOV AL, AH        ; 高字节
    OUT DX, AL
    
    MOV AL, 01110111B ; T1 读写16位 方式3 BCD计数
    MOV DX, IO8253_CTR   
    OUT DX, AL
    MOV DX, IO82531   
    MOV AX, CNTVAL    ; 1000分频
    OUT DX, AL
    
    MOV AL, AH        ; 高字节
    OUT DX, AL   
    
    ; 初始化8255
    MOV AL, 81H ; A、B输出，C上部输出，下部输入
    MOV DX, IO8255K
    OUT DX, AL
    
LP:
    ; 主任务
    CALL KEY
    CALL DISP    ; 显示子程序调用
    JMP LP       ; 循环

NMI_SERVICE: 
    ; 中断服务
    PUSH AX
    MOV AL, SEC
    ADD AL, 1
    DAA          ; 校正BCD数加法    
    
    MOV SEC, AL
    CMP SEC, 60H 
    JB  EXIT      
    MOV SEC, 0
    MOV AL,  MIN
    ADD AL,  1
    DAA
    
    MOV MIN, AL
    CMP MIN, 60H
    JB  EXIT
    MOV MIN, 0
    MOV AL,  HOU
    ADD AL,  1
    DAA
    
    MOV HOU, AL
    CMP HOU, 24H
    JB  EXIT
    MOV HOU, 0
    
EXIT: 
    POP AX
    IRET       ; 中断返回
          
DISP PROC 
     ; 数码管显示子程序  
     MOV AL, 0FFH   ; 不显示
     MOV DX, IO8255B
     OUT DX, AL     ; 位选信号接到8255A的PB口
     
     ; 秒个位
     MOV AL, 0FEH    ;先选最低位 AL=1111 1110
     MOV DX, IO8255B          
     OUT DX, AL     ; 位选  
     
     MOV BL, SEC    
     AND BX, 000FH   ; 低4位秒数为秒个位
     MOV SI, BX 
     MOV AL, LED[SI]  ;段码为LED字段第SI个
     MOV DX, IO8255A  
     OUT DX, AL       ; 段选
     CALL DELAY            
   
     MOV AL, 0FFH   ; 为防止重叠，每次显示之前要清零
     MOV DX, IO8255B
     OUT DX, AL       
     
     MOV BL, SEC       ;同理取秒十位放入SI
     AND BX, 00F0H
     MOV CL, 4
     SHR BX, CL      
     MOV SI, BX
 
     MOV AL, 0FDH   ; 秒十位，AL=1111 1101
     MOV DX, IO8255B          
     OUT DX, AL
             
     MOV AL, LED[SI]  ; 段码
     MOV DX, IO8255A
     OUT DX, AL
     CALL DELAY          
     
     MOV AL, 0FFH   ; 不显示
     MOV DX, IO8255B
     OUT DX, AL  
                
     MOV AL, 40H    ; "-"段码  
     MOV DX, IO8255A
     OUT DX, AL
     
     MOV AL, 0FBH   ; "-"位,AL=1111 1011
     MOV DX, IO8255B
     OUT DX, AL
     CALL DELAY   
     
     MOV AL, 0FFH   ; 不显示
     MOV DX, IO8255B
     OUT DX, AL    
     
     MOV BL, MIN
     AND BX, 000FH
     MOV SI, BX
     MOV AL, LED[SI]  ; 段码
     MOV DX, IO8255A
     OUT DX, AL
     
     MOV AL, 0F7H     ; 分个位，AL=1111 0111
     MOV DX, IO8255B
     OUT DX, AL
     CALL DELAY  
                      
     MOV AL, 0FFH     ; 不显示
     MOV DX, IO8255B
     OUT DX, AL  
     
     MOV BL, MIN
     AND BX, 00F0H
     MOV CL, 4
     SHR BX, CL       
     MOV SI, BX
     MOV AL, LED[SI]  ; 段码 
     MOV DX, IO8255A
     OUT DX, AL
     
     MOV AL, 0EFH   ; 分十位,AL=1110 1111
     MOV DX, IO8255B          
     OUT DX, AL
     CALL DELAY  
     
     MOV AL, 0FFH   ; 不显示
     MOV DX, IO8255B
     OUT DX, AL   
     
     MOV AL, 40H    ; 段码“-”  
     AND DX, IO8255A
     OUT DX, AL
     
     MOV AL, 0DFH   ; "-"位,AL=1101 1111
     MOV DX, IO8255B
     OUT DX, AL
     CALL DELAY 
     
     MOV AL, 0FFH   ; 不显示
     MOV DX, IO8255B
     OUT DX, AL    

     MOV BL, HOU
     AND BX, 000FH
     MOV SI, BX
     MOV AL, LED[SI]  ; 段码
     MOV DX, IO8255A
     OUT DX, AL
     
     MOV AL, 0BFH     ; 时个位,AL=1011 1111
     MOV DX, IO8255B
     OUT DX, AL
     CALL DELAY               
     
     MOV AL, 0FFH     ; 不显示
     MOV DX, IO8255B
     OUT DX, AL  
     
     MOV BL, HOU
     AND BX, 00F0H
     MOV CL, 4
     SHR BX, CL       
     MOV SI, BX
     MOV AL, LED[SI]  ; 段码 
     MOV DX, IO8255A
     OUT DX, AL  
     
     MOV AL, 07FH     ; 时十位,AL=0111 1111
     MOV DX, IO8255B
     OUT DX, AL
     CALL DELAY
     
     RET              ; 子程序返回
DISP ENDP
          
KEY   PROC
    MOV DX, IO8255C     
    IN AL, DX
    TEST AL, 8H       ;第一次检测
    JZ NEXTHOU 
    TEST AL, 4H     
    JZ NEXTMIN
    TEST AL, 2H      
    JZ NEXTSEC
    TEST AL, 1H
    JZ RESET
    CALL DISP       ; 消抖
    CALL DISP 
    CALL DISP
    MOV DX, IO8255C
    IN AL, DX
    TEST AL, 8H       ;第二次检测
    JZ NEXTHOU 
    TEST AL, 4H
    JZ NEXTMIN
    TEST AL, 2H
    JZ NEXTSEC
    TEST AL, 1H
    JZ RESET

NEXTHOU: 
    ; 时+1
    MOV DX, IO8255C
    IN AL, DX
    TEST AL, 8H         ;第三次检测
    JNZ EXITKEY  
    CALL DISP           ;日常消抖
    CALL DISP
    CALL DISP
    MOV DX, IO8255C
    IN AL, DX
    TEST AL, 8H          ;第四次检测
    JNZ EXITKEY
    MOV AL, HOU
    ADD AL, 1     
    DAA 
    CALL DELAY   
    
    MOV HOU, AL
    CMP HOU, 24H
    JB NEXTHOU
    MOV HOU, 0

NEXTMIN: 
    ; 分+1
    MOV DX, IO8255C
    IN AL, DX
    TEST AL, 4H         ;第三次检测
    JNZ EXITKEY  
    CALL DISP           ;日常消抖
    CALL DISP
    CALL DISP
    MOV DX, IO8255C
    IN AL, DX
    TEST AL, 4H          ;第四次检测
    JNZ EXITKEY
    MOV AL, MIN
    ADD AL, 1
    DAA      
    CALL DELAY 
    
    MOV MIN, AL
    CMP MIN, 60H
    JB NEXTMIN
    MOV MIN, 0    

NEXTSEC: 
    ; 秒+1
    MOV DX, IO8255C
    IN AL, DX
    TEST AL, 2H          ;第三次检测
    JNZ EXITKEY  
    CALL DISP            ;日常消抖
    CALL DISP
    CALL DISP
    MOV DX, IO8255C
    IN AL, DX
    TEST AL, 2H
    JNZ EXITKEY          ;第四次检测
    MOV AL, SEC
    ADD AL, 1
    DAA         
    CALL DELAY        
    MOV SEC, AL
    CMP SEC, 60H
    JB NEXTSEC
    MOV SEC, 0

RESET: 
    ; 清零
    MOV DX, IO8255C
    IN AL, DX
    TEST AL, 1H          ;第三次检测
    JNZ EXITKEY  
    CALL DISP           ;日常消抖
    CALL DISP
    CALL DISP
    MOV DX, IO8255C
    IN AL, DX
    TEST AL, 1H          ;第四次检测
    JNZ EXITKEY    
    MOV HOU, 0
    MOV MIN, 0
    MOV SEC, 0
    CALL DELAY
    
EXITKEY:
    RET
    
KEY ENDP

DELAY PROC
      ; 延时子程序 
      PUSH BX
      PUSH CX
      MOV BX, 1
LP1:  MOV CX, 1000
LP2:  LOOP LP2
      DEC BX
      JNZ LP1
      POP CX
      POP BX   
      RET    
DELAY ENDP
               
CODE ENDS

    END START 
