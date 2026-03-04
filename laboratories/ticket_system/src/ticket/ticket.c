#include <stdio.h>   
#include <stdlib.h>  
#include <string.h>  
#include <time.h>    

#include "ticket/ticket.h"

/**
 * Función: crear_ticket
 * -------------------
 * Reserva memoria dinámica para una estructura Ticket y llena sus datos.
 * * id: Identificación del usuario.
 * correo: Correo electrónico validado.
 * tipo: Tipo de reclamación.
 */
Ticket* crear_ticket(int id, const char* correo, const char* tipo) {
    // Solicitud de memoria al sistema (Heap)
    Ticket* nuevo_ticket = (Ticket*) malloc(sizeof(Ticket));

    // Asignacion de memoria
    if (nuevo_ticket == NULL) {
        perror("Error crítico: Falló la asignación de memoria (malloc)");
        return NULL;
    }

    // Asignación de datos
    nuevo_ticket->identificacion = id;

    // Usamos strncpy para evitar desbordamientos de buffer (seguridad)
    strncpy(nuevo_ticket->correo, correo, sizeof(nuevo_ticket->correo) - 1);
    nuevo_ticket->correo[sizeof(nuevo_ticket->correo) - 1] = '\0'; 

    strncpy(nuevo_ticket->tipo_reclamacion, tipo, sizeof(nuevo_ticket->tipo_reclamacion) - 1);
    nuevo_ticket->tipo_reclamacion[sizeof(nuevo_ticket->tipo_reclamacion) - 1] = '\0';

    // Generación de radicado único
    // Usamos time(NULL) para obtener los segundos actuales + un aleatorio
    nuevo_ticket->radicado = (long)time(NULL) + (rand() % 1000);

    return nuevo_ticket;
}

/**
 * Función: guardar_ticket
 * ----------------------
 * Crea un archivo de texto en la carpeta assets/ con la información del ticket.
 * * t: Puntero al ticket que queremos guardar.
 * * Retorna: 1 si tuvo éxito, 0 si hubo error.
 */
int guardar_ticket(Ticket* t) {
    if (t == NULL) return 0;

    char nombre_archivo[100];
    
    // Construimos la ruta del archivo. Ej: assets/ticket_17085699.txt
    // Es vital que la carpeta 'assets' exista previamente.
    sprintf(nombre_archivo, "assets/ticket_%ld.txt", t->radicado);

    // Abrimos el archivo en modo escritura ("w")
    FILE* archivo = fopen(nombre_archivo, "w");

    // Validamos si el archivo se pudo crear
    if (archivo == NULL) {
        // perror imprime el error exacto del sistema (ej: "No such file or directory")
        perror("Error al intentar crear el archivo en assets/");
        return 0;
    }

    // Escribimos el contenido dentro del archivo
    fprintf(archivo, "================================\n");
    fprintf(archivo, "      TICKET DE RECLAMACIÓN     \n");
    fprintf(archivo, "================================\n");
    fprintf(archivo, "Radicado No:    %ld\n", t->radicado);
    fprintf(archivo, "Fecha registro: %ld (Unix Timestamp)\n", (long)time(NULL));
    fprintf(archivo, "--------------------------------\n");
    fprintf(archivo, "Identificación: %d\n", t->identificacion);
    fprintf(archivo, "Correo:         %s\n", t->correo);
    fprintf(archivo, "Tipo:           %s\n", t->tipo_reclamacion);
    fprintf(archivo, "Estado:         RECIBIDO\n");
    fprintf(archivo, "================================\n");

    // Cerrar el archivo para liberar el recurso y guardar cambios
    fclose(archivo);

    printf("[Sistema] Archivo generado exitosamente: %s\n", nombre_archivo);
    return 1;
}

/**
 * Función: liberar_ticket
 * ----------------------
 * Libera la memoria reservada con malloc para evitar Memory Leaks.
 */
void liberar_ticket(Ticket* t) {
    if (t != NULL) {
        free(t);
        // Opcional: imprimir para depuración
        // printf("[Debug] Memoria liberada correctamente.\n");
    }
}
