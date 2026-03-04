// Guardas de inclusión exigidas para evitar redefiniciones 
#ifndef TICKET_H
#define TICKET_H

// Definición de la estructura usando typedef struct 
typedef struct {
    int identificacion;       // Identificación numérica
    char correo[100];         // Correo electrónico
    char tipo_reclamacion[50];// Tipo de reclamación 
    long radicado;            // Número de radicado 
} Ticket;

#endif // TICKET_H
