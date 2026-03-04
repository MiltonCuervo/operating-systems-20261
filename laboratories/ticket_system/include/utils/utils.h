#ifndef UTILS_H
#define UTILS_H

#include <stdio.h>

// Función para leer texto de forma segura
// buffer: Donde guardaremos el texto
// tamano: Tamaño máximo del buffer
void leer_cadena(const char* mensaje, char* buffer, int tamano);

// Función para leer un número entero validado
int leer_entero(const char* mensaje);

#endif
