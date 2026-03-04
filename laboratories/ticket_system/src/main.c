/* Archivo: src/main.c */

#include <stdio.h>
#include <stdlib.h>

// Incluimos nuestro contrato. El Makefile sabe buscar en la carpeta 'include/'
#include "ticket/ticket.h"

int main(void) {
    // Declaramos una variable temporal solo para probar que el compilador reconoce 'Ticket'
    Ticket prueba;
    prueba.identificacion = 0; 

    printf("==========================================\n");
    printf("   SISTEMA DE REGISTRO DE TICKETS \n");
    printf("==========================================\n");
    printf("El compilador reconoce la estructura Ticket correctamente.\n");
    printf("El programa compila y se ejecuta sin errores.\n");

    return 0;
}
