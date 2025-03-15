;==========================================
; ПРОГРАММА ПОДСЧЁТА СЛОВ С ЗАДАННОЙ ПЕРВОЙ БУКВОЙ
;==========================================
; Программа считает количество слов в предложении,
; которые начинаются с определённой буквы.
;
; Компиляция и сборка:
;   nasm -f elf32 65.asm -o 65.o
;   ld -m elf_i386 65.o -o 65
;
; Запуск: ./65

;==========================================
; ОБЪЯВЛЕНИЕ ПЕРЕМЕННЫХ И СТРУКТУР ДАННЫХ
;==========================================
section .data
    prompt_sentence db 'Введите предложение: '
    prompt_sentence_len equ $ - prompt_sentence
    
    prompt_letter db 10, 'Введите букву: '
    prompt_letter_len equ $ - prompt_letter
    
    result_msg db 10, 'Количество слов, начинающихся с указанной буквы: '
    result_msg_len equ $ - result_msg
    
    newline db 10    ; Символ новой строки
    
section .bss
    sentence resb 1024    ; Буфер для хранения предложения
    letter resb 4         ; Буфер для хранения UTF-8 символа (буквы)
    letter_len resb 4     ; Для хранения длины буквы в байтах
    count resd 1          ; Счётчик слов, начинающихся с заданной буквой
    buffer resb 10        ; Буфер для преобразования числа в строку
    
;==========================================
; ИСПОЛНЯЕМЫЙ КОД ПРОГРАММЫ
;==========================================
section .text
    global _start
    
_start:
    ;----------------------------------------
    ; БЛОК ВВОДА: Запрос предложения
    ;----------------------------------------
    mov eax, 4            ; Системный вызов 4 (write)
    mov ebx, 1            ; Файловый дескриптор 1 (stdout)
    mov ecx, prompt_sentence  ; Указатель на строку приглашения
    mov edx, prompt_sentence_len  ; Длина строки приглашения
    int 0x80              ; Вызов ядра
    
    ;----------------------------------------
    ; БЛОК ВВОДА: Чтение предложения
    ;----------------------------------------
    mov eax, 3            ; Системный вызов 3 (read)
    mov ebx, 0            ; Файловый дескриптор 0 (stdin)
    mov ecx, sentence     ; Буфер для сохранения предложения
    mov edx, 1024         ; Максимальная длина предложения
    int 0x80              ; Вызов ядра
    
    ;----------------------------------------
    ; БЛОК ОБРАБОТКИ: Завершение строки предложения
    ;----------------------------------------
    mov edi, eax          ; Сохраняем фактическую длину введённого текста
    mov [sentence+edi], byte 0  ; Добавляем нулевой символ в конец строки
    
    ;----------------------------------------
    ; БЛОК ВВОДА: Запрос буквы
    ;----------------------------------------
    mov eax, 4            ; Системный вызов 4 (write)
    mov ebx, 1            ; Файловый дескриптор 1 (stdout)
    mov ecx, prompt_letter  ; Указатель на строку приглашения
    mov edx, prompt_letter_len  ; Длина строки приглашения
    int 0x80              ; Вызов ядра
    
    ;----------------------------------------
    ; БЛОК ВВОДА: Чтение буквы
    ;----------------------------------------
    mov eax, 3            ; Системный вызов 3 (read)
    mov ebx, 0            ; Файловый дескриптор 0 (stdin)
    mov ecx, letter       ; Буфер для сохранения буквы
    mov edx, 4            ; Максимум 4 байта (поддержка UTF-8)
    int 0x80              ; Вызов ядра
    
    ;----------------------------------------
    ; БЛОК ОБРАБОТКИ: Очистка буквы от символа новой строки
    ;----------------------------------------
    mov dword [letter_len], eax  ; Сохраняем длину введённой буквы
    mov edi, letter       ; Указатель на начало буфера буквы
    add edi, eax          ; Смещаемся к концу введённого текста
    dec edi               ; На один символ назад
    cmp byte [edi], 10    ; Проверяем, является ли последний символ переводом строки
    jne no_newline        ; Если нет, пропускаем удаление
    dec dword [letter_len]  ; Уменьшаем длину буквы на 1
    
    mov byte [edi], 0     ; Заменяем перевод строки на нулевой символ
    
no_newline:
    ;==========================================
    ; БЛОК ПОДСЧЁТА СЛОВ
    ;==========================================
    
    ;----------------------------------------
    ; Подблок: Инициализация счётчика
    ;----------------------------------------
    mov dword [count], 0  ; Обнуляем счётчик слов
    
    ;----------------------------------------
    ; Подблок: Настройка процесса обработки предложения
    ;----------------------------------------
    mov esi, sentence     ; Указатель на начало предложения
    mov bl, 0             ; Флаг состояния: 0 - не в слове, 1 - в слове
    
    ;----------------------------------------
    ; Подблок: Цикл обработки символов предложения
    ;----------------------------------------
process_loop:
    movzx eax, byte [esi]  ; Загружаем текущий символ с расширением нулями
    cmp al, 0             ; Проверяем на конец строки
    je print_result       ; Если конец строки, переходим к выводу результата
    cmp al, 10            ; Проверяем на символ новой строки
    je print_result       ; Если символ новой строки, переходим к выводу результата
    
    ;----------------------------------------
    ; Подблок: Проверка символа-разделителя
    ;----------------------------------------
    cmp al, ' '           ; Пробел
    je space_found
    cmp al, ','           ; Запятая
    je space_found
    cmp al, '.'           ; Точка
    je space_found
    cmp al, ';'           ; Точка с запятой
    je space_found
    cmp al, ':'           ; Двоеточие
    je space_found
    cmp al, '?'           ; Вопросительный знак
    je space_found
    cmp al, '!'           ; Восклицательный знак
    je space_found
    cmp al, 9             ; Табуляция
    je space_found
    
    ;----------------------------------------
    ; Подблок: Обработка символа, не являющегося разделителем
    ;----------------------------------------
    cmp bl, 0             ; Проверяем, не находимся ли в слове
    jne continue_word     ; Если уже в слове, продолжаем обработку
    
    ;----------------------------------------
    ; Подблок: Обработка начала слова
    ;----------------------------------------
    mov bl, 1             ; Устанавливаем флаг "в слове"
    
    ;----------------------------------------
    ; Подблок: Проверка первой буквы слова
    ;----------------------------------------
    mov ecx, dword [letter_len]  ; Получаем длину искомой буквы
    cmp ecx, 0            ; Проверяем, не пустая ли буква
    je continue_word      ; Если пустая, пропускаем проверку
    
    ;----------------------------------------
    ; Подблок: Сохранение контекста для сравнения
    ;----------------------------------------
    push esi              ; Сохраняем позицию в предложении
    push edi              ; Сохраняем регистр EDI
    
    ;----------------------------------------
    ; Подблок: Сравнение байтов буквы со словом
    ;----------------------------------------
    mov edi, letter       ; Указатель на искомую букву
    xor edx, edx          ; Инициализируем счётчик байтов
    
compare_bytes:
    cmp edx, ecx          ; Проверяем, все ли байты проверены
    je letter_matched     ; Если все байты совпали - буква найдена
    
    movzx eax, byte [esi+edx]  ; Берём байт из слова
    movzx ebx, byte [edi+edx]  ; Берём байт из искомой буквы
    cmp al, bl            ; Сравниваем байты
    jne not_matched       ; Если не совпадают - буква не найдена
    
    inc edx               ; Увеличиваем счётчик проверенных байтов
    jmp compare_bytes     ; Переходим к проверке следующего байта
    
    ;----------------------------------------
    ; Подблок: Обработка совпадения буквы
    ;----------------------------------------
letter_matched:
    inc dword [count]     ; Увеличиваем счётчик слов с нужной буквой
    
    ;----------------------------------------
    ; Подблок: Восстановление контекста после сравнения
    ;----------------------------------------
not_matched:
    pop edi               ; Восстанавливаем EDI
    pop esi               ; Восстанавливаем позицию в предложении
    
    ;----------------------------------------
    ; Подблок: Продолжение обработки слова
    ;----------------------------------------
continue_word:
    inc esi               ; Переходим к следующему символу
    jmp process_loop      ; Возврат к началу цикла обработки
    
    ;----------------------------------------
    ; Подблок: Обработка найденного разделителя
    ;----------------------------------------
space_found:
    mov bl, 0             ; Сбрасываем флаг "в слове"
    inc esi               ; Переходим к следующему символу
    jmp process_loop      ; Возврат к началу цикла обработки
    
    ;==========================================
    ; БЛОК ВЫВОДА РЕЗУЛЬТАТА
    ;==========================================
print_result:
    ;----------------------------------------
    ; Подблок: Вывод сообщения о результате
    ;----------------------------------------
    mov eax, 4            ; Системный вызов 4 (write)
    mov ebx, 1            ; Файловый дескриптор 1 (stdout)
    mov ecx, result_msg   ; Указатель на сообщение о результате
    mov edx, result_msg_len ; Длина сообщения
    int 0x80              ; Вызов ядра
    
    ;----------------------------------------
    ; Подблок: Конвертация числа в строку
    ;----------------------------------------
    mov eax, [count]      ; Загружаем счётчик слов
    mov ebx, 10           ; Основание системы счисления (10)
    mov edi, buffer + 9   ; Указатель на конец буфера
    mov byte [edi], 0     ; Устанавливаем завершающий ноль
    
    ;----------------------------------------
    ; Подблок: Цикл преобразования числа в строку
    ;----------------------------------------
convert_loop:
    dec edi               ; Смещаем указатель влево
    xor edx, edx          ; Обнуляем EDX перед делением
    div ebx               ; Делим EAX на 10, остаток в EDX
    add dl, '0'           ; Преобразуем остаток в символ ASCII
    mov [edi], dl         ; Сохраняем символ в буфер
    test eax, eax         ; Проверяем, есть ли ещё цифры
    jnz convert_loop      ; Если есть, продолжаем цикл
    
    ;----------------------------------------
    ; Подблок: Обработка случая нулевого результата
    ;----------------------------------------
    cmp edi, buffer + 9   ; Проверяем, преобразовали ли мы хоть одну цифру
    jne print_count       ; Если да, переходим к выводу
    dec edi               ; Если нет, смещаем указатель
    mov byte [edi], '0'   ; Записываем символ '0'
    
    ;----------------------------------------
    ; Подблок: Вывод числового результата
    ;----------------------------------------
print_count:
    mov eax, 4            ; Системный вызов 4 (write)
    mov ebx, 1            ; Файловый дескриптор 1 (stdout)
    mov ecx, edi          ; Указатель на начало числа
    mov edx, buffer + 9   ; Вычисляем длину строки
    sub edx, edi          ; Длина = конец - начало
    int 0x80              ; Вызов ядра
    
    ;----------------------------------------
    ; Подблок: Вывод символа новой строки
    ;----------------------------------------
    mov eax, 4            ; Системный вызов 4 (write)
    mov ebx, 1            ; Файловый дескриптор 1 (stdout)
    mov ecx, newline      ; Указатель на символ новой строки
    mov edx, 1            ; Длина - 1 байт
    int 0x80              ; Вызов ядра
    
    ;==========================================
    ; БЛОК ЗАВЕРШЕНИЯ ПРОГРАММЫ
    ;==========================================
    mov eax, 1            ; Системный вызов 1 (exit)
    xor ebx, ebx          ; Код возврата 0 (успешное завершение)
    int 0x80              ; Вызов ядра

;==========================================
; МЕТКА GNU-STACK
;==========================================
section .note.GNU-stack noexec  ; Указание на неисполняемый стек
