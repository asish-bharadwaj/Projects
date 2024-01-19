[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-24ddc0f5d75046c5622901739e7c5dd533143b0c8e959d652212380cedb1ea36.svg)](https://classroom.github.com/a/DLipn7os)

[Project Description](https://karthikv1392.github.io/cs3301_osn/mini-projects/mp2)
# Intro to Xv6
OSN Monsoon 2023 mini project 2

## Some pointers
- main xv6 source code is present inside `initial_xv6/src` directory. This is where you will be making all the additions/modifications necessary for the first 3 specifications. 
- work inside the `networks/` directory for the Specification 4 as mentioned in the assignment.
- Instructions to test the xv6 implementations are given in the `initial_xv6/README.md` file. 

- You are free to delete these instructions and add your report before submitting. 

## REPORT

## Explanation of Round Robin Scheduling Algorithm
- The basic policy used in RR is : Run jobs for a time slice, switch to next process, repeat 
- Here, we use the notion of time slice, considering timer interrupts
- We should take into consideration the overhead of Context Switch, as too small time slice can result in an overhead of too much context switch
- In terms of metrics, RR has pretty good response time, but it has the worst turnaround time
- Detailed implementation: To schedule processes fairly [which results in less response time], RR scheduler employs time-sharing, giving each job a time slot/slice, and interrupting the job if it is not completed by then. The job is resumed the next time a time slot is assigned to that process. If the process terminates or changes its state to waiting during its attributed time quantum, the scheduler selects the first process in the ready queue to execute. In the absence of time-sharing, or if the quanta were large relative to the sizes of the jobs, a process that produced large jobs would be favored over other processes. Round-robin algorithm is a pre-emptive algorithm as the scheduler forces the process out of the CPU once the time quota expires. 
- In xv6, the implementation is as follows: firstly in the scheduler function [which contains an infinite loop], we turn interrupts on, so as to avoid deadlocks. Then we iterate over all the processes in the proc array, see if a process is in RUNNABLE state. If so, we switch to that processes. [swtch returns after completion of 1 timer interrupt, which means the process runs for 1 timer interrupt].

## Explanation of First Come First Serve Scheduling Algorithm
- This is the most basic algorithm that a scheduler can implement. The basic policy is: whichever process arrives first, give access to that process. 
- FCFS is not a that great, as the waiting time for other processes [processes other than the currently scheduled process] can go very high, resulting in convoy effect.
- Since context switches only occur upon process termination, and no reorganization of the process queue is required, scheduling overhead is minimal.
- Throughput can be low, because long processes can be holding the CPU, causing the short processes to wait for a long time (known as the convoy effect).
- No starvation, because each process gets chance to be executed after a definite time.
- Turnaround time, waiting time and response time depend on the order of their arrival and can be high for the same reasons above.
- The lack of prioritization means that as long as every process eventually completes, there is no starvation. In an environment where some processes might not complete, there can be starvation.
- In xv6, the implementation is as follows: firstly we iterate over all the processes in the proc array and find the process with the least ctime [the tick number when the process was created] and is in RUNNABLE state. We switch to this process, and this process will run until it no longer needs CPU time [this is achieved by disabling preemption of the process after the clock interrupts - which is attained by NOT calling yield function when timer interrupt occurs]

## Explanation for Multi-Level Feedback Queue Scheduling Algorithm
- The main features of MLFQ among other algorithms are to reduce turnaround times [by running shortest jobs first] and to reduce response time, with no apriori knowledge of the job length
- We use n number of distinct queues, each having a different priority level, which are used to decide which job should run at a given time [A job with a higher priority => job on a higher queue]. The key idea is that scheduler sets priority to different jobs, and keeps updating the priority based on observed behaviour
- High priority queues: Interactive jobs with shorter time slices, Low priority queues: CPU bound jobs with longer time slices 
- Jobs that keep giving back the CPU - interactive jobs (higher priority), jobs that uses CPU for more time - Reduce priority. So the basic rules are If priority (A) > Priority (B), A runs; If priority (A) = Priority (B), A&B run in Round Robin.
- However, there is a possibility of too many interactive jobs to keep consuming CPU, which results in long running jobs to never get CPU access, resulting in Starvation. There is another possibility where the process can trick the scheduler into giving more fair share, by giving an I/O request and relinquish the CPU before time slice is over, so that priority does not change - know as Gaming of Scheduler.
- To prevent starvation, we periodically boost the priority of all jobs. In ideal case, we can also prevent gaming of scheduler, by reducing the priority of the process irrespective of whether it restores CPU access before time slice or not. [as in sometime in the future the process gets a priority boost]
- Determining the value of time interval for priority boost is tricky, because is it is very small, interactive jobs may not get proper share of CPU and if it is too high, long running jobs could starve
- In xv6, the implementation is as follows: 4 priority queues/arrays PQ0, PQ1, PQ2, PQ3 are used [with time slices 1, 3, 9, 15 timer ticks respectively]. When a process is initialized, it is added to PQ0 [in allocproc function]. The process in the highest non-empty priority queue is run first [with the help of if(pq[0]){}else_if(pq[1]){}else_if(pq[2]){}else_if(pq[3]){}]. In the cases of PQ[1], PQ[2], PQ[3] being executed in RR, we check if the values of (pq[0]), (pq[0], pq[1]), (pq[0], pq[1], pq[2]) respectively are non-zero or not. If any one of them is non-zero, we preempt the process in lower priority, in order to run the process in higher priority.
- If the process uses complete time slice, [detected by the state of the process. If p->state == RUNNABLE, it has not completed yet], we insert it to the end of the next lower priority queue.
- If a process voluntarily relinquishes control of the CPU [detected by the state of the process. If p->state != RUNNABLE, it has given up CPU access], it leaves the queeing network, and when it becomes ready again, it is inserted to the end of the same queue [stored in priority field in struct proc]. Note that, using this scheme, we cannot prevent gaming of scheduler, as a process can exploit the above scheduler algorithm by doing a redundent I/O just before its time slice of a particular queue is getting over. The CPU would think that it is a I/O bound or interactive process but in reality the process could be an intensive CPU bound process. Still the process can ensure that it gets more priority and remain in a higher priority queue.
- To prevent starvation, if the wait time of a process in a priority queue exceeds a given limit [taken as 50 timer ticks in this case], its priority is increased and wait time is reset to 0.

## PERFORMANCE COMPARISION
- Running schedulertest.c on different schedulers, we get the following output:
for RR: Average rtime 10, wtime 142
for FCFS: Average rtime 11, wtime 122
for MLFQ: Average rtime 11, wtime 136

