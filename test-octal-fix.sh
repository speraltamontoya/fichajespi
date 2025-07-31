#!/bin/bash

# Script de prueba para verificar la corrección del problema octal

# Función corregida
time_to_minutes_fixed() {
    local time="$1"
    IFS=':' read -r hours minutes seconds <<< "$time"
    # Forzar interpretación decimal para evitar problemas con números octales (08, 09)
    echo $(((10#$hours) * 60 + (10#$minutes)))
}

# Función original (con problema)
time_to_minutes_original() {
    local time="$1"
    IFS=':' read -r hours minutes seconds <<< "$time"
    echo $((hours * 60 + minutes))
}

echo "=== PRUEBA DE CORRECCIÓN DEL PROBLEMA OCTAL ==="
echo

# Casos de prueba problemáticos
test_cases=(
    "08:30:00"
    "09:15:00" 
    "09:55:13"
    "07:08:00"
    "10:09:00"
    "15:08:30"
)

echo "Probando función CORREGIDA:"
for test_case in "${test_cases[@]}"; do
    result=$(time_to_minutes_fixed "$test_case")
    echo "  $test_case -> $result minutos"
done

echo
echo "Probando función ORIGINAL (debería dar errores):"
for test_case in "${test_cases[@]}"; do
    echo -n "  $test_case -> "
    if result=$(time_to_minutes_original "$test_case" 2>/dev/null); then
        echo "$result minutos"
    else
        echo "ERROR (problema octal)"
    fi
done

echo
echo "=== VERIFICACIÓN MANUAL ==="
echo "09:55:00 debería ser = 9*60 + 55 = 540 + 55 = 595 minutos"
echo "Resultado función corregida: $(time_to_minutes_fixed "09:55:00")"

echo
echo "Casos adicionales que deberían funcionar bien:"
other_cases=("00:00:00" "12:30:00" "23:59:59")
for test_case in "${other_cases[@]}"; do
    result=$(time_to_minutes_fixed "$test_case")
    echo "  $test_case -> $result minutos"
done
