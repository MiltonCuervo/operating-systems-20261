/* Archivo: src/main.c */
#include <stdio.h>
#include <stdlib.h>
#include <time.h> 
#include <string.h>

#include "ticket/ticket.h"
#include "utils/utils.h"

int main(void) {
    // Semilla para números aleatorios
    srand(time(NULL));

    char correo[100];
    char tipo[50];
    int id;

    printf("=== REGISTRO DE RECLAMACIONES ===\n");

    // Solicitamos datos
    id = leer_entero("Ingrese su Identificación (Numérica): ");
    
    // Validación de correo: debe tener arroba
    do {
        leer_cadena("Ingrese su Correo: ", correo, sizeof(correo));
        if (strchr(correo, '@') == NULL) {
            printf("Error: El correo debe contener un '@'. Intente de nuevo.\n");
        }
    } while (strchr(correo, '@') == NULL);

    leer_cadena("Tipo de Reclamación (Queja/Peticion/Recurso): ", tipo, sizeof(tipo));

    // Creamos el ticket
    Ticket* mi_ticket = crear_ticket(id, correo, tipo);

    if (mi_ticket != NULL) {
        printf("\n>>> TICKET CREADO EN MEMORIA <<<\n");
        printf("Radicado Generado: %ld\n", mi_ticket->radicado);

        // Guardar en archivo
        if (guardar_ticket(mi_ticket)) {
            printf("¡El ticket se ha guardado permanentemente!\n");
        } else {
            fprintf(stderr, "Error grave: No se pudo guardar el archivo.\n");
        }

        // Liberar memoria
        liberar_ticket(mi_ticket);
    }

    return 0;
}
