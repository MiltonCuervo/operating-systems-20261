#include <stdio.h>
#include <stdlib.h>
#include "mlfq/mlfq.h"
#include "utils/queue.h"

int quantums[3] = {2, 4, 8}; 

void write_csv(Process processes[]) {
    FILE *fp = fopen("assets/results.csv", "w");
    if (fp != NULL) {
        fprintf(fp, "PID,Arrival,Burst,Start,Finish,Response,Turnaround,Waiting\n");
        printf("\n--- Resultados Finales ---\n");
        for (int i = 0; i < NUM_PROCESSES; i++) {
            int response = processes[i].first_response_time - processes[i].arrival_time;
            int turnaround = processes[i].finish_time - processes[i].arrival_time;
            int waiting = turnaround - processes[i].burst_time;
            fprintf(fp, "%s,%d,%d,%d,%d,%d,%d,%d\n", 
                processes[i].pid, processes[i].arrival_time, processes[i].burst_time,
                processes[i].start_time, processes[i].finish_time, response, turnaround, waiting);
            printf("PID: %s | Resp: %d | Turn: %d | Wait: %d\n", processes[i].pid, response, turnaround, waiting);
        }
        fclose(fp);
        printf("\nResultados exportados a assets/results.csv exitosamente.\n");
    }
}

void run_scheduler() {
    Process processes[NUM_PROCESSES] = {
        {"P1", 0, 8, 8, -1, -1, -1, 0, 0, false, false},
        {"P2", 1, 4, 4, -1, -1, -1, 0, 0, false, false},
        {"P3", 2, 9, 9, -1, -1, -1, 0, 0, false, false},
        {"P4", 3, 5, 5, -1, -1, -1, 0, 0, false, false}
    };

    Queue queues[3];
    for (int i = 0; i < 3; i++) init_queue(&queues[i]);

    int current_time = 0;
    int completed_processes = 0;
    Process* active_process = NULL;

    printf("--- Iniciando Simulación MLFQ ---\n");

    while (completed_processes < NUM_PROCESSES) {
        for (int i = 0; i < NUM_PROCESSES; i++) {
            if (processes[i].arrival_time == current_time) {
                printf("[Tick %d] Proceso %s llega y entra a Q0.\n", current_time, processes[i].pid);
                enqueue(&queues[0], &processes[i]);
            }
        }

        if (current_time > 0 && current_time % BOOST_CYCLES == 0) {
            printf("[Tick %d] *** PRIORITY BOOST *** Moviendo procesos a Q0.\n", current_time);
            for (int i = 1; i <= 2; i++) {
                while (!is_empty(&queues[i])) {
                    Process* p = dequeue(&queues[i]);
                    p->current_queue = 0;
                    p->quantum_used = 0;
                    enqueue(&queues[0], p);
                }
            }
            if (active_process != NULL) {
                active_process->current_queue = 0;
                active_process->quantum_used = 0;
                enqueue(&queues[0], active_process);
                active_process = NULL;
            }
        }

        if (active_process != NULL) {
            bool higher_priority_exists = false;
            for (int i = 0; i < active_process->current_queue; i++) {
                if (!is_empty(&queues[i])) higher_priority_exists = true;
            }
            if (higher_priority_exists) {
                printf("[Tick %d] Proceso %s preemptado.\n", current_time, active_process->pid);
                enqueue(&queues[active_process->current_queue], active_process);
                active_process = NULL;
            }
        }

        if (active_process == NULL) {
            for (int i = 0; i < 3; i++) {
                if (!is_empty(&queues[i])) {
                    active_process = dequeue(&queues[i]);
                    break;
                }
            }
        }

        if (active_process != NULL) {
            if (!active_process->has_started) {
                active_process->start_time = current_time;
                active_process->first_response_time = current_time;
                active_process->has_started = true;
            }

            active_process->remaining_time--;
            active_process->quantum_used++;
            
            if (active_process->remaining_time == 0) {
                active_process->finish_time = current_time + 1;
                active_process->is_finished = true;
                printf("[Tick %d] Proceso %s finaliza.\n", current_time + 1, active_process->pid);
                completed_processes++;
                active_process = NULL;
            } else if (active_process->quantum_used == quantums[active_process->current_queue]) {
                int next_queue = (active_process->current_queue < 2) ? active_process->current_queue + 1 : 2;
                printf("[Tick %d] Proceso %s agota quantum. Baja a Q%d.\n", current_time + 1, active_process->pid, next_queue);
                active_process->current_queue = next_queue;
                active_process->quantum_used = 0;
                enqueue(&queues[next_queue], active_process);
                active_process = NULL;
            }
        }
        current_time++;
    }
    write_csv(processes);
}
