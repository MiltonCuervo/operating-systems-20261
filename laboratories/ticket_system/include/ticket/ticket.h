#ifndef TICKET_H
#define TICKET_H

typedef struct {
    int identificacion;
    char correo[100];
    char tipo_reclamacion[50];
    long radicado;
} Ticket;

// Crea un ticket en memoria dinámica
Ticket* crear_ticket(int id, const char* correo, const char* tipo);

// Libera la memoria del ticket
void liberar_ticket(Ticket* t);

// Guarda el ticket en un archivo 
int guardar_ticket(Ticket* t);

#endif 
