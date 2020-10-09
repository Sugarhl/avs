format PE console
entry start

include 'win32a.inc'

;Условие 
;Разработать программу, которая вводит одномерный массив A[N],
;формирует из элементов массива A новый массив B, где поменяны местами минимальный и первый элементы, и выводит его. 
;Память под массивы может выделяться как статически, так и динамически по выбору разработчика.

;Разбить решение задачи на функции следующим образом:

;1. Ввод и вывод массивов оформить как подпрограммы.
;2. Выполнение задания по варианту оформить как процедуру
;3. Организовать вывод как исходного, так и сформированного массивов
;Указанные процедуры могут использовать данные напрямую (имитация процедур без параметров).
;Имитация работы с параметрами также допустима.

;Вариант 20 - с перестановкой местами минимального и первого элемента.

;test1: abacaba
;test2: -1
;test3: 301
;test4: 0
;test5: 7 {1, -499, 54, 43, 534, -323, 53}
;test6: 9 {2, 2, 2, 2, 2, 2, 2, 2, 2}
;test7: 6 {-1000, 29, 554, 3, 65, 32} 
;test8: массив на 50 чисел 
;test9: массив на 300 чисел 
;--------------------------------------------------------------------------------------

section '.data' data readable writable

        strArrSize     db 'Input size of array (300 >= x > 0): ', 0
        strIncorSize   db 'Incorrect size of array = %d', 10, 0
        strArrElemI    db 'arr[%d]: ', 0
        strScanInt     db '%d', 0
        strMinValue    db 'Min in array = %d', 10, 0
        strArrsElemOut db 'arr[%d] = %d     new_arr[%d] = %d', 10, 0
        strPrevOutArrs db 'Arrays:', 10, 0
        strNewLine     db 10, 0
        strNANSize     db 'The size of the array must be a positive integer', 0
        strNANElem     db 'The element of array must be a integer', 10, 0

        arr_size     dd 0
        i            dd ?
        tmpb         dd ?
        tmpd         dd ?
        tmpStack     dd ?
        arr          rd 300
        new_arr      rd 300
        min          dd ?
        min_pos      dd ?
        first        dd ?
;--------------------------------------------------------------------------------------

section '.code' code readable executable
start:
; 1) array input
        call ArrayInput
; 2) get array minimum
        call ArrayMin
; 3) crete new array
        call GetNewArray
; 4) arrays output
        push strNewLine
        call [printf]
        push strPrevOutArrs
        call [printf]
        call ArraysOutput  

finish:
        call [getch]

        push 0
        call [ExitProcess]

;--------------------------------------------------------------------------------------
ArrayInput:
        mov [tmpStack], esp
        push strArrSize
        call [printf]

        push arr_size
        push strScanInt
        call [scanf]
        cmp eax , 0
        je failGetNumberToSize

        push strNewLine
        call [printf]


        mov eax, [arr_size]
        cmp eax, 0
        jle  failSize
        cmp eax, 300
        jle getArray

failSize:
        push [arr_size]
        push strIncorSize
        call [printf]

        call [getch]

        push 0
        call [ExitProcess]
failGetNumberToSize:
        push strNANSize
        call [printf]

        call [getch]
        
        push 0
        call [ExitProcess]

getArray:
        xor ecx, ecx            
        mov ebx, arr         
getArrLoop:
        mov [tmpb], ebx
        cmp ecx, [arr_size]
        jge endInputArray       

        mov [i], ecx
        push ecx
        push strArrElemI
        call [printf]

        push ebx
        push strScanInt
        call [scanf]
        cmp eax , 0
        je failGetNumberToSize


        mov ecx, [i]
        inc ecx
        mov ebx, [tmpb]
        add ebx, 4
        jmp getArrLoop
failGetNumberToArr:
        push strNANElem
        call [printf]

        call [getch]
        
        push 0
        call [ExitProcess]

endInputArray:
        mov esp, [tmpStack]
        ret
;--------------------------------------------------------------------------------------
;search minimum
ArrayMin: 
        xor ecx, ecx            
        mov ebx, arr
        mov eax, [ebx]
        mov [min_pos], 0
        mov [min], eax
MinArrLoop:
        cmp ecx, [arr_size]
        je endMinArray      
        mov eax, [min]
        cmp eax, [ebx]      
        jl SkipChange

        mov eax, [ebx]
        mov [min], eax
        mov [min_pos], ecx

SkipChange:                     
        inc ecx
        add ebx, 4
        jmp MinArrLoop
endMinArray:
        ret
;--------------------------------------------------------------------------------------
;intialize new array
GetNewArray:
        xor ecx, ecx
        mov ebx, arr
        mov edx, new_arr
        mov eax, [ebx]
        mov [first], eax
        mov eax, [min]
        mov [edx], eax
        add ebx, 4
        add edx, 4
        inc ecx
newArrayLoop:
        cmp ecx, [arr_size]       
        je endGetNewArray
        cmp ecx, [min_pos]
        jne defaultCopy

        mov eax, [first]
        mov [edx], eax
        jmp nextStep

defaultCopy:
        mov eax, [ebx]
        mov [edx], eax
    
nextStep:
        add ebx, 4
        add edx, 4
        inc ecx
        jmp newArrayLoop
endGetNewArray:
        ret
;--------------------------------------------------------------------------------------
;output arrays
ArraysOutput:
        mov [tmpStack], esp
        xor ecx, ecx            
        mov ebx, arr 
        mov edx, new_arr 
putArrLoop:
        mov [tmpb], ebx
        mov [tmpd], edx
        cmp ecx, [arr_size]
        je endOutputArrays   
        mov [i], ecx

   
        push dword [edx]
        push ecx
        push dword [ebx]
        push ecx
        push strArrsElemOut
        call [printf]

        mov ecx, [i]
        inc ecx
        mov ebx, [tmpb]
        mov edx, [tmpd]
        add ebx, 4
        add edx, 4
        jmp putArrLoop
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