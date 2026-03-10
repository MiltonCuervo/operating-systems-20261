#ifndef QUEUE_H
#define QUEUE_H
#include <stdbool.h>

typedef struct {
    char pid[5];
    int arrival_time;
    int burst_time;
    int remaining_time;
    int start_time;
    int finish_time;
    int first_response_time;
    int current_queue;
    int quantum_used;      
    bool is_finished;
    bool has_started;
} Process;

typedef struct {
    Process* procs[100];
    int front;
    int rear;
    int count;
} Queue;

void init_queue(Queue* q);
void enqueue(Queue* q, Process* p);
Process* dequeue(Queue* q);
bool is_empty(Queue* q);

#endif
