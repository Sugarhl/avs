format PE console
entry start

include 'win32a.inc'

;Условие 
;Разработать программу, которая попараметрам N>3  
;отрезков (задаются какдекартовы координаты концов отрезков  ввиде целых чисел) решает,
;могут ли этиотрезки являться сторонамимногоугольника
;(Я подходил к вам после семинара и мы с Вами решили, что проверить математический критерий достаточно. 
;Для этого я включил в свою работу взаимодействие с FPU)
;Вариант: 20 
;Студент: Сахаров Никита 
;Группа: БПИ196
;--------------------------------------------------------------------------------------

section '.data' data readable writable

        strArrSize     db 'Input count of line segments  (400 >= x > 3): ', 0
        strLineFormat  db 'Format of input: ', 10 , 13, '  Line[i]: x1 y1 x2 y2',10 , 0
        strIncorSize   db 'Incorrect count of lines = %d', 10, 0
        strScanInt     db '%d', 0
        strLineElemI   db 'Line [%d]: ', 0
        strScanLine    db '%d %d %d %d', 0
        strNewLine     db 10, 0
        strdouble      db ' %f', 10, 0
        strNANSize     db 'The size of the line count must be a positive integer', 0
        strNANElem     db 'The ends of line segment must be integer between -1000 and 1000', 10, 0
        strANS         db 'MAX = %f  Summ of all segments length = %f', 10, 0
        strSuccsess    db 'You can create a polygon from these line segments', 10, 0
        strFail        db 'You can not create a polygon from these line segments,',\
        ' because max legnth of line segments less than sum of others', 10, 0
        strOutLen      db 'Line[%d] legnth: %f', 10, 0
        strSeparrator  db 10, '-----------------------------------------------------', 10, 10, 0
        strInfo        db 'Lines legnth info:', 10, 10, 0
        strLines       db 'Your lines:', 10, 0

        line_count   dd 0
        arrOfLen     rq 10000
        i            dd ?
        tmpb         dd ?
        x1           dd ?
        x2           dd ?
        y1           dd ?
        y2           dd ?
        sqx          dd ?
        sqy          dd ?
        lenLine      dd ?
        tmpStack     dd ?
        summOfLines  dq ? 
        max          dq ?
        currLen      dq ?
;--------------------------------------------------------------------------------------

section '.code' code readable executable
start:
        FINIT ;intialization of FPU

        FLDZ 
        FSTP [summOfLines]       ; set sum 0
        FLDZ
        FSTP [max]               ; set max 0

                                
        call LinesInput          ; array input
         
        call CanConstuctPolygon  ; get verdict

        call LenLinesOutput      ; print info about lines


finish:
        call [getch]

        push 0
        call [ExitProcess]

;--------------------------------------------------------------------------------------
LinesInput:
        mov [tmpStack], esp
        cinvoke printf, strArrSize      ; input size

        push line_count
        push strScanInt                 
        call [scanf]
        cmp  eax , 0                    ; сheck scan succsess 
        je failGetLineToSize

        mov eax, [line_count]
        
        cmp eax, 3
        jle failSize

        cmp eax, 400
        jle getLines

failSize:                               ; branch for incorrect size of array
        push [line_count]
        push strIncorSize
        call [printf]

        call [getch]

        push 0
        call [ExitProcess]
failGetLineToSize:                      ;  branch for incorrect size of array
        push strNANSize
        call [printf]

        call [getch]
        
        push 0
        call [ExitProcess]

getLines:
        cinvoke printf, strSeparrator
        cinvoke printf, strLineFormat   ; print info about format input
        cinvoke printf, strSeparrator
        cinvoke printf, strLines
        xor ecx, ecx            
        mov ebx, arrOfLen
        mov ecx, [line_count]
getLinesLoop: 
        push ecx
        mov  [tmpb], ebx                  
        
        mov eax, [line_count]
        sub eax, ecx
        mov [i], eax
        cinvoke printf, strLineElemI, [i] ;
        call InputLine


        FILD [lenLine]      
        FSQRT                             ; get srtr from length of line segmet
        FST  [currLen]

        FCOM  [max]                       ; compare to max
        fstsw AX
        sahf
        jb Skip                           ; skip update max
        FST  [max]                        ; update max

Skip:                                      
        FSTP [currLen]
        FLD  [summOfLines]
        FADD [currLen]                    ; add current length to sum 
        FSTP [summOfLines]                ; update sum      

        mov ebx, [tmpb]

        mov eax, dword[currLen]           ; send value of length to array     
        mov edx, dword[currLen + 4]
        mov [ebx], eax
        mov [ebx + 4], edx

        add  ebx, 8
        pop  ecx
        loop getLinesLoop


        jmp endInputLines
failGetLineToArr:                         ; branch for fail get line 
        push strNANElem
        call [printf]

        call [getch]
        
        push 0
        call [ExitProcess]

endInputLines:
        mov esp, [tmpStack]
        ret

;--------------------------------------------------------------------------------------
InputLine:

        cinvoke scanf, strScanLine, x1, y1, x2, y2   ; input ends of lint segment 
        cmp eax , 4
        jl failGetLineToSize 
        mov edx, [x1]
        cmp edx, 1000
        jg  failGetLineToArr
        cmp edx, -1000                               ; check  bounds
        jl  failGetLineToArr        

        mov edx, [y1]
        cmp edx, 1000
        jg  failGetLineToArr
        cmp edx, -1000                               ; check  bounds
        jl  failGetLineToArr

        mov edx, [x2]
        cmp edx, 1000
        jg  failGetLineToArr
        cmp edx, -1000                               ; check  bounds
        jl  failGetLineToArr

        mov edx, [y2]
        cmp edx, 1000
        jg  failGetLineToArr
        cmp edx, -1000                               ; check  bounds
        jl  failGetLineToArr

        mov  eax, [x1]
        sub  eax, [x2]
        imul eax
        mov  [sqx], eax                              ; get squre for OX axis

        mov  eax, [y1]
        sub  eax, [y2]
        imul eax                                  
        mov  [sqy], eax                              ; get squre for OY axis

        add  eax, [sqx]                              ; get squre of length

        mov  [lenLine], eax                                  

        ret
;--------------------------------------------------------------------------------------
CanConstuctPolygon:
        cinvoke printf, strSeparrator                 
        FLD   [summOfLines]                  ;
        FSUB  [max]                          ;  get su, without max 
        FST   [currLen]
        FCOMP [max]                          ;  check criterion
        fstsw AX
        sahf
        jnb SuccessConsturt
FailConstruct:
        cinvoke printf, strFail
        jmp endCanConstruct                  ; print fail verdict 
SuccessConsturt:
        cinvoke printf, strSuccsess          ; print succsess verdict 
endCanConstruct:
        ret
;--------------------------------------------------------------------------------------
LenLinesOutput:
        mov [tmpStack], esp

        cinvoke printf, strSeparrator
        cinvoke printf, strInfo
        cinvoke printf, strANS, dword[max], dword[max+4], dword[summOfLines], dword[summOfLines + 4]
        cinvoke printf, strNewLine

        xor ecx, ecx            
        mov ebx, arrOfLen 
OutputLoop:
        mov [tmpb], ebx
        cmp ecx, [line_count]
        je endOutputArrays   
        mov [i], ecx

        cinvoke printf, strOutLen, [i], dword[ebx], dword[ebx + 4]
                                             ; print current line segmet length
        mov ecx, [i]
        inc ecx

        mov ebx, [tmpb]
        add ebx, 8
        jmp OutputLoop
endOutputArrays:
        mov esp, [tmpStack]
        ret
;--------------------------------------------------------------------------------------

section '.idata' import data readable
    library kernel, 'kernel32.dll',\
            msvcrt, 'msvcrt.dll',\
            user32,'USER32.DLL'

include 'api\user32.inc'
include 'api\kernel32.inc'
    import kernel,\
           ExitProcess, 'ExitProcess',\
           HeapCreate,'HeapCreate',\
           HeapAlloc,'HeapAlloc'
  include 'api\kernel32.inc'
    import msvcrt,\
           printf, 'printf',\
           scanf, 'scanf',\
           getch, '_getch'