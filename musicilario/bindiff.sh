#!/bin/bash

# Verifica che siano stati forniti due argomenti
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <file1> <file2>"
    exit 1
fi

file1="$1"
file2="$2"

# Verifica che i file esistano
if [ ! -e "$file1" ] || [ ! -e "$file2" ]; then
    echo "I due file devono esistere."
    exit 1
fi

# Legge il contenuto binario dei due file
binary1=$(xxd -p "$file1" | tr -d '\n')
binary2=$(xxd -p "$file2" | tr -d '\n')

# Trova l'offset del binario di file1 in file2
offset=$(echo "$binary2" | grep -b -o "$binary1" | cut -d ":" -f 1)

# Stampa l'offset, indirizzo di inizio e fine
if [ -n "$offset" ]; then
    start_address=$((16#$offset))
    end_address=$((start_address + ${#binary1} / 2 - 1))
    echo "Il binario di $file1 è presente in $file2 all'offset $offset (indirizzo: $start_address - $end_address)."
else
    echo "Il binario di $file1 non è presente in $file2."
fi

