; Пример Win32 консольной программы для FASM, которая получает в строке вызова
; имя текстового файла и выводит его содержимое и размер на консоль.
; Сделано IQFun.ru, см. www.iqfun.ru/articles/fasm-primer-console-output.shtml
; Создавайте этот файл в кодировке DOS (OEM, code page 866).

format PE CONSOLE
include 'win32ax.inc'

SEEK_SET equ 0  ; Относительно начала файла, начало файла - позиция 0
SEEK_CUR equ 1  ; Относительно текущей позиции, > 0 - вперед, < 0 - назад
SEEK_END equ 2  ; Относительно конца файла (значение pos - отрицательное)
NULL     equ 0
EOF      equ -1

section '.data' data readable writeable

argc    dd ?
argv    dd ?
env     dd ?
fp      dd ?
flength dd ?
fbuf    dd ?
msg     db  '%s %s%s',0
errmsg  db "Error! You must input textfile's name.",0

section '.code' code readable executable

entry start

start:
; invoke  FreeConsole
; invoke  AllocConsole
; cinvoke printf,'%s%s',,<13,10,0>
; invoke SetConsoleOutputCP,1251
; invoke SetConsoleCP,1251

 cinvoke printf,'%s',<'Error',13,10,0>

 ; Получаем полный путь к программе и заданный ей параметр аналогично программе на C
 cinvoke __getmainargs,argc,argv,env,0
 cmp [argc],2
 jne .err
 mov esi,[argv]

; invoke CharToOemA,dword [esi],dword [esi]
; invoke CharToOemA,dword [esi+4],dword [esi+4]

 ; Выводим имя программы с путём и параметр
 cinvoke printf,msg,dword [esi],dword [esi+4],<13,10,0>

 ; Открываем заданный текстовый файл в режиме "только чтение" и "двоичный"
 cinvoke fopen,dword [esi+4],'rb'
 test eax,eax
 jz .err
 mov [fp],eax

 ; Устанавливаем указатель чтения-записи в конец файла
 cinvoke fseek,[fp],0,SEEK_END
 .if eax <> 0
  jmp .err
 .endif

 ; Узнаём значение этого указателя, который равен размеру файла
 cinvoke ftell,[fp]
 test eax,eax
 jz .err
 mov [flength],eax

 ; Запрашиваем динамическую память размером длина файла + 1 байт
 inc eax
 cinvoke malloc,eax
 test eax,eax
 jz .err
 mov [fbuf],eax

 ; Возвращаем указатель чтения-записи в начало файла
 cinvoke fseek,[fp],0,SEEK_SET
 test eax,eax
 jnz .err

 ; Читаем весь файл в динамическую память
 cinvoke fread,[fbuf],1,[flength],[fp]
 cmp eax,[flength]
 jne .err

 ; Записываем 0 за концом данных для обозначения конца строки
 mov eax,[fbuf]
 add eax,[flength]
 mov byte [eax],0

 ; Выводим файл на консоль
 cinvoke puts,[fbuf]
 cinvoke printf,'File lenght = %u%s',[flength],<13,10,0>

 ; Закрываем файл
 cinvoke fclose,[fp]
 test eax,eax
 jnz .err

 ; Освобождаем динамическую память
 cinvoke free,[fbuf]

.finish:
 cinvoke puts,'Press any key...'
 cinvoke _getch
 invoke ExitProcess,0

.err:
 cinvoke puts,errmsg
 jmp .finish

section '.idata' import data readable writeable

library kernel,'kernel32.dll',\
msvcrt,'msvcrt.dll',\
user32,'user32.dll'

import kernel,\
ExitProcess,'ExitProcess',\
GetCommandLineA,'GetCommandLineA',\
AllocConsole,'AllocConsole',\
FreeConsole,'FreeConsole',\
SetConsoleOutputCP,'SetConsoleOutputCP',\
SetConsoleCP,'SetConsoleCP'

import msvcrt,\
__getmainargs,'__getmainargs',\
fopen,'fopen',\
fseek,'fseek',\
ftell,'ftell',\
malloc,'malloc',\
free,'free',\
fread,'fread',\
fclose,'fclose',\
printf,'printf',\
_getch,'_getch',\
puts,'puts'

import user32,\
CharToOemA,'CharToOemA'