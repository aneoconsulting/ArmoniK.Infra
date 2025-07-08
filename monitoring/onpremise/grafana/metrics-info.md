## Dashboards : 
- Task Handler Analytics : Aggregates ArmoniK.Core metrics relevant to task execution in your deployment. 
- Node disk monitoring : Aggregates disk metrics, specifically interesting for looking into how well your database is performing.

## Task Handler Analytics

The Task Handler dashboard is made up of three sections:

### Overview :

This section includes a general overview of the task execution pipeline. 
(Number of tasks executed in the current window, number of tasks dispatched, processing, queued and submitted in the last scrape). These metrics are for the whole deployment, and as such aren't affected by the selected pods. Then there is task throughput, which is calculated as the rate of task executions, and a graph that combines all of the different TaskHandler operations for the selected pods, along with the mean and total time spent in each operation for the selected time range. 


### Operation Metrics

This section gives the duration of each task handler operation as a function of time. The durations are acquired by taking the 95th percentile of the time taken by the operation. You can select the relevant pods that you want to display. 

### Operation Metrics by Instance

Breaks down the previous operation metrics by instance. This doesn't serve as a replacement to the filtering by pod name, but more so gives a general overview of all of the metrics.

## Node disk monitoring

This has general disk metrics such as the number of reads and write operations per second, the disk IOPS. Which provide a general overview over the utilisation of the disk in a machine, and in particular can be linked with that of the database. The Disk IOPS is a direct sum of the last two metrics. 

Along with this is the average time spent per read or write operation, along with the overall flow of data read/writes. (Bytes read or written per second) and the sum of the latter. This can prove useful to look into in combination with the previous two metrics to perhaps explain the times spent per read, or the increase in data reads/writes in relation to the number of said operations. 

Additionally, an overview of node and CPU usage is also provided, which might aid in pinpointing the limiting factor.


## Things to keep in mind: 

You may need to refresh the durations to update the pod selection variable.




