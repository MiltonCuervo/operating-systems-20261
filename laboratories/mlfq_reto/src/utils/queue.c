#include "utils/queue.h"
#include <stddef.h>

void init_queue(Queue* q) {
    q->front = 0;
    q->rear = -1;
    q->count = 0;
}

void enqueue(Queue* q, Process* p) {
    q->rear = (q->rear + 1) % 100;
    q->procs[q->rear] = p;
    q->count++;
}

Process* dequeue(Queue* q) {
    if (q->count == 0) return NULL;
    Process* p = q->procs[q->front];
    q->front = (q->front + 1) % 100;
    q->count--;
    return p;
}

bool is_empty(Queue* q) {
    return q->count == 0;
}
