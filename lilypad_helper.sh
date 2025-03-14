#!/bin/bash

# Script to query Lilypad solver and run jobs on specific nodes

# Function to display usage information
function show_help {
  echo "Lilypad Helper Script"
  echo "---------------------"
  echo "Usage:"
  echo "  ./lilypad_helper.sh [options]"
  echo ""
  echo "Options:"
  echo "  -l, --list                List available resource providers"
  echo "  -r, --run [index]         Run a job on provider at specified index"
  echo "  -a, --run-all             Run job on all providers sequentially"
  echo "  -s, --select \"0,2,4\"      Run job only on specified provider indices"
  echo "  -d, --delay [seconds]     Delay between jobs when using run-all (default: 30s)"
  echo "  -p, --prompt TEXT         Specify prompt for the job (for SDXL)"
  echo "  -k, --key KEY             Your Web3 private key"
  echo "  -h, --help                Show this help message"
  echo ""
  echo "Example:"
  echo "  ./lilypad_helper.sh --list"
  echo "  ./lilypad_helper.sh --run 2 --prompt \"a spaceship parked on mountain\" --key 0x123..."
  echo "  ./lilypad_helper.sh --run-all --delay 60 --prompt \"roman architecture\" --key 0x123..."
  echo "  ./lilypad_helper.sh --select \"0,2,4\" --prompt \"fantasy castle\" --key 0x123..."
}

# Function to map provider addresses to names
function get_provider_name {
  local address=$1
  
  case $address in
    "0xf5AefbbcF28FC0a8c7fc8B86d2070281fBB32Ae7")
      echo "Jaco"
      ;;
    "0x102272dB860Ed4fcaC73eB0E1785441aaAF4a303")
      echo "Jaco"
      ;;
    "0xC44CB6599bEc03196fD230208aBf4AFc68514DD2")
      echo "James"
      ;;
    "0x68614eE52ba024A458369E11DC1fFd876bbcE705")
      echo "Lindsay"
      ;;
    "0xA7f9BD3837279C3776B17b952D97C619f3892BDE")
      echo "Alex"
      ;;
    "0xB971f0E067c8365AE9500B1Eca6560d9f7ED356D")
      echo "Kablarasa"
      ;;
    "0x228822581CB5A26F89a2aBBDFEb9ac1A635316a1")
      echo "Kablarasa"
      ;;
    *)
      echo "Unknown"
      ;;
  esac
}

# Function to list providers
function list_providers {
  echo "Fetching available resource providers..."
  
  # Array to store provider addresses
  providers=()
  
  # Fetch and process the provider list
  while IFS= read -r line; do
    # Remove quotes from the line
    clean_line=$(echo "$line" | tr -d '"')
    providers+=("$clean_line")
  done < <(curl -s "https://solver-testnet.lilypad.tech/api/v1/resource_offers?not_matched=true" | jq '.[] | .resource_provider')
  
  # Display the providers with indices and names
  echo "Available Resource Providers:"
  echo "---------------------------"
  for i in "${!providers[@]}"; do
    provider_name=$(get_provider_name "${providers[$i]}")
    echo "[$i] ${providers[$i]} **$provider_name**"
  done
  
  # Save providers to a temporary file for later use
  printf "%s\n" "${providers[@]}" > /tmp/lilypad_providers.txt
}

# Function to run a job on a specific provider
function run_job {
  local index=$1
  local prompt=$2
  local private_key=$3
  
  # Check if providers file exists
  if [ ! -f /tmp/lilypad_providers.txt ]; then
    echo "Error: No provider list found. Run --list first."
    exit 1
  fi
  
  # Get the provider address at the specified index
  local provider=$(sed -n "$((index+1))p" /tmp/lilypad_providers.txt)
  
  if [ -z "$provider" ]; then
    echo "Error: Invalid provider index ($index)."
    return 1
  fi
  
  # Get the provider name
  local provider_name=$(get_provider_name "$provider")
  
  echo "Running job on provider [$index]: $provider (**$provider_name**)"
  echo "Prompt: $prompt"
  
  # Create a results directory if it doesn't exist
  mkdir -p ./results
  
  # Run the lilypad command and save output
  lilypad run --target "$provider" github.com/noryev/module-sdxl-ipfs:ae17e969cadab1c53d7cabab1927bb403f02fd2a --web3-private-key "$private_key" -i prompt="$prompt" | tee ./results/job_${index}_${provider_name}_$(date +%Y%m%d%H%M%S).log
  
  # Return the status of the lilypad command
  return ${PIPESTATUS[0]}
}

# Function to run jobs on all providers
function run_all_jobs {
  local prompt=$1
  local private_key=$2
  local delay=$3
  
  # Check if providers file exists
  if [ ! -f /tmp/lilypad_providers.txt ]; then
    echo "No provider list found. Fetching providers now..."
    list_providers
  fi
  
  # Count the number of providers
  local provider_count=$(wc -l < /tmp/lilypad_providers.txt)
  
  echo "Running jobs on all $provider_count providers with a ${delay}s delay between jobs."
  echo "Prompt: $prompt"
  echo "---------------------------------------------"
  
  # Run job on each provider
  for i in $(seq 0 $((provider_count-1))); do
    # Run the job
    run_job $i "$prompt" "$private_key"
    job_status=$?
    
    # Check if this is the last provider
    if [ $i -lt $((provider_count-1)) ]; then
      # If job was successful and there are more providers, wait before the next one
      if [ $job_status -eq 0 ]; then
        echo "Waiting ${delay}s before next job..."
        sleep $delay
      else
        echo "Job failed. Continuing to next provider..."
      fi
    fi
  done
  
  echo "---------------------------------------------"
  echo "All jobs completed."
}

# Function to run jobs on selected providers
function run_selected_jobs {
  local indices=$1
  local prompt=$2
  local private_key=$3
  local delay=$4
  
  # Convert indices string to array
  IFS=',' read -r -a index_array <<< "$indices"
  
  echo "Running jobs on selected providers with a ${delay}s delay between jobs."
  echo "Prompt: $prompt"
  echo "---------------------------------------------"
  
  # Run job on each selected provider
  for i in "${!index_array[@]}"; do
    # Get the index
    local index=${index_array[$i]}
    
    # Run the job
    run_job $index "$prompt" "$private_key"
    job_status=$?
    
    # Check if this is the last provider in the selection
    if [ $i -lt $((${#index_array[@]}-1)) ]; then
      # If job was successful and there are more providers, wait before the next one
      if [ $job_status -eq 0 ]; then
        echo "Waiting ${delay}s before next job..."
        sleep $delay
      else
        echo "Job failed. Continuing to next provider..."
      fi
    fi
  done
  
  echo "---------------------------------------------"
  echo "All selected jobs completed."
}

# Default delay between jobs (in seconds)
DELAY=5

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  
  case $key in
    -l|--list)
      list_providers
      exit 0
      ;;
    -r|--run)
      RUN_INDEX="$2"
      shift
      shift
      ;;
    -a|--run-all)
      RUN_ALL=true
      shift
      ;;
    -s|--select)
      SELECTED_INDICES="$2"
      shift
      shift
      ;;
    -d|--delay)
      DELAY="$2"
      shift
      shift
      ;;
    -p|--prompt)
      PROMPT="$2"
      shift
      shift
      ;;
    -k|--key)
      PRIVATE_KEY="$2"
      shift
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Check for required parameters for all job operations
if [ ! -z "$RUN_INDEX" ] || [ "$RUN_ALL" = true ] || [ ! -z "$SELECTED_INDICES" ]; then
  if [ -z "$PROMPT" ]; then
    echo "Error: Prompt is required for running jobs."
    show_help
    exit 1
  fi
  
  if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: Private key is required for running jobs."
    show_help
    exit 1
  fi
fi

# Execute the appropriate action based on parameters
if [ "$RUN_ALL" = true ]; then
  run_all_jobs "$PROMPT" "$PRIVATE_KEY" "$DELAY"
  exit 0
elif [ ! -z "$SELECTED_INDICES" ]; then
  run_selected_jobs "$SELECTED_INDICES" "$PROMPT" "$PRIVATE_KEY" "$DELAY"
  exit 0
elif [ ! -z "$RUN_INDEX" ]; then
  run_job "$RUN_INDEX" "$PROMPT" "$PRIVATE_KEY"
  exit 0
fi

# If no specific action was requested, show help
if [ -z "$RUN_INDEX" ] && [ -z "$RUN_ALL" ] && [ -z "$SELECTED_INDICES" ]; then
  show_help
  exit 0
fi