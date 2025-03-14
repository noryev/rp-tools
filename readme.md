Run on all providers sequentially (--run-all):

Executes your job on all available providers one after another
Waits for a specified delay between jobs (default 30 seconds)


Run on selected providers (--select "0,2,4"):

Lets you specify exactly which providers to use (by index)
Great for targeting specific providers like running only on "James" and "Lindsay"


Customizable delay (--delay 60):

Set how many seconds to wait between job submissions
Helps prevent overwhelming the network


Result logging:

Creates a ./results directory
Saves the output of each job to a timestamped log file
Includes provider index and name in the filename