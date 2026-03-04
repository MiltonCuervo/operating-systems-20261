#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "utils/utils.h"

void leer_cadena(const char* mensaje, char* buffer, int tamano) {
    printf("%s", mensaje);
    
    // fgets lee hasta 'tamano - 1' caracteres o hasta el salto de línea
    if (fgets(buffer, tamano, stdin) != NULL) {
        buffer[strcspn(buffer, "\n")] = '\0';
    } else {
        // Si hay error (ej. fin de archivo), limpiamos el buffer
        buffer[0] = '\0';
    }
}

int leer_entero(const char* mensaje) {
    char buffer[100];
    int valor;
    // Bucle infinito hasta que el usuario ingrese un número válido
    while (1) {
        leer_cadena(mensaje, buffer, sizeof(buffer));
        // sscanf intenta extraer un entero del texto. Devuelve 1 si tuvo éxito.
        if (sscanf(buffer, "%d", &valor) == 1) {
            return valor;
        }
        printf("Error: Debes ingresar un número válido.\n");
    }
}
