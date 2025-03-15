1. **Run on all providers sequentially** (`--run-all`):
   - Executes your job on all available providers one after another
   - Waits for a specified delay between jobs (default 30 seconds)

2. **Run on selected providers** (`--select "0,2,4"`):
   - Lets you specify exactly which providers to use (by index)
   - Great for targeting specific providers like running only on "James" and "Lindsay"

3. **Customizable delay** (`--delay 60`):
   - Set how many seconds to wait between job submissions
   - Helps prevent overwhelming the network

4. **Result logging**:
   - Creates a `./results` directory
   - Saves the output of each job to a timestamped log file
   - Includes provider index and name in the filename

### Example Usage:

```bash
# Run on all providers with 60-second delay between jobs
./lilypad_helper.sh --run-all --delay 60 --prompt "Roman architecture" --key YOUR_PRIVATE_KEY

# Run only on providers 0, 2, and 4 (Jaco, James, and Alex)
./lilypad_helper.sh --select "0,2,4" --prompt "Fantasy castle" --key YOUR_PRIVATE_KEY
```
