#!/bin/bash

# Компиляция
nasm -f elf32 65.asm -o 65.o

# Линковка с опцией для 32-битной архитектуры
gcc -m32 65.o -o 65

echo "Сборка завершена. Для запуска программы выполните: ./65"
