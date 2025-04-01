#!/bin/bash

# Компиляция
nasm -f elf32 228.asm -o 228.o

# Линковка с опцией для 32-битной архитектуры
gcc -m32 228.o -o 228

./228

echo "Сборка завершена. Для запуска программы выполните: ./228"
