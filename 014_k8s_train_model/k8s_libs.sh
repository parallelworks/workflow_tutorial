#!/bin/bash

get_pod_name_from_job_name() {
  local NAMESPACE="$1"
  local TRAIN_JOB_NAME="$2"
  
  # Set timeout to 10 minutes (600 seconds)
  local TIMEOUT=600
  local SLEEP_INTERVAL=5  # Sleep 5 seconds between retries
  local pod_name=""
  local iteration=0  # Counter for periodic logging

  # Reset SECONDS to 0 to start timing
  SECONDS=0

  # Log start of the process to stderr
  echo "Starting to wait for pod of job '$TRAIN_JOB_NAME' in namespace '$NAMESPACE'" >&2

  # Loop until pod name is found or timeout is reached
  while true; do
    pod_name=$(kubectl get pod -n "$NAMESPACE" -l job-name="$TRAIN_JOB_NAME" -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
    
    # If pod_name is not empty, log success and output it to stdout
    if [ -n "$pod_name" ]; then
      echo "Pod name found: $pod_name" >&2  # Log to stderr
      echo "$pod_name"  # Output only the pod name to stdout
      return 0
    fi
    
    # Log progress periodically (e.g., every 30 seconds)
    if [ $((SECONDS % 30)) -eq 0 ]; then
      echo "Still waiting for pod after $SECONDS seconds..." >&2
    fi
    
    # Check if timeout is exceeded
    if [ "$SECONDS" -ge "$TIMEOUT" ]; then
      echo "Error: Pod name not found after 10 minutes" >&2
      return 1
    fi
    
    # Wait before the next retry
    sleep "$SLEEP_INTERVAL"
    iteration=$((iteration + 1))
  done
}


wait_for_pod() {
  local NAMESPACE="$1"
  local POD_NAME="$2"
  
  # Set timeout to 10 minutes (600 seconds)
  local TIMEOUT=600
  local SLEEP_INTERVAL=5  # Sleep 5 seconds between retries
  local phase=""
  local iteration=0  # Counter for periodic logging

  
  # Reset SECONDS to 0 to start timing
  SECONDS=0

  # Log start of the process to stderr
  echo "Starting to wait for pod '$POD_NAME' in namespace '$NAMESPACE' to reach Running state" >&2

  # Loop until pod is Running, Succeeded, Failed, or timeout
  while true; do
    phase=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath="{.status.phase}" 2>/dev/null)
    
    # Handle pod phase
    if [ "$phase" = "Running" ]; then
      echo "Pod '$POD_NAME' is now Running" >&2
      echo "$phase"  # Output phase to stdout
      return 0
    elif [ "$phase" = "Succeeded" ]; then
      echo "Pod '$POD_NAME' has Succeeded" >&2
      echo "$phase"  # Output phase to stdout
      return 0
    elif [ "$phase" = "Failed" ]; then
      echo "Error: Pod '$POD_NAME' has Failed" >&2
      kubectl describe pod "$POD_NAME" -n "$NAMESPACE" >&2  # Log pod details for debugging
      return 1
    fi
    
    # Log current state periodically (every 30 seconds) or on change
    if [ $((iteration % 6)) -eq 0 ] || [ "$phase" != "$last_phase" ]; then
      if [ -z "$phase" ]; then
        echo "Pod '$POD_NAME' not found yet after $SECONDS seconds..." >&2
      else
        echo "Pod '$POD_NAME' is in phase '$phase' after $SECONDS seconds..." >&2
      fi
      last_phase="$phase"  # Track last phase to detect changes
    fi
    
    # Check for timeout
    if [ "$SECONDS" -ge "$TIMEOUT" ]; then
      if [ -z "$phase" ]; then
        echo "Error: Pod '$POD_NAME' not found after ${TIMEOUT} seconds" >&2
      else
        echo "Error: Pod '$POD_NAME' did not reach Running or Succeeded state after ${TIMEOUT} seconds (current phase: $phase)" >&2
        kubectl describe pod "$POD_NAME" -n "$NAMESPACE" >&2  # Log pod details for debugging
      fi
      return 1
    fi
    
    # Wait before the next retry (only if not already in a terminal state)
    sleep "$SLEEP_INTERVAL"
    iteration=$((iteration + 1))
  done
}

wait_for_job_completion() {
  local NAMESPACE="$1"
  local TRAIN_JOB_NAME="$2"
  
  # Set timeout to 10 minutes (600 seconds)
  local TIMEOUT=600
  local SLEEP_DURATION=5
  local status=""
  local iteration=0  # Counter for periodic logging
  
  # Reset SECONDS to 0 to start timing
  SECONDS=0

  # Log start of the process to stderr
  echo "Starting to wait for job '$TRAIN_JOB_NAME' in namespace '$NAMESPACE' to finish" >&2

  # Loop until job completes, fails, or times out
  while true; do
    # Check if job is Complete
    if kubectl -n "$NAMESPACE" get job/"$TRAIN_JOB_NAME" -o jsonpath="{.status.conditions[?(@.type==\"Complete\")].status}" 2>/dev/null | grep -q "True"; then
      echo "Job '$TRAIN_JOB_NAME' completed successfully" >&2
      echo "Complete"  # Output status to stdout
      return 0
    # Check if job is Failed
    elif kubectl -n "$NAMESPACE" get job/"$TRAIN_JOB_NAME" -o jsonpath="{.status.conditions[?(@.type==\"Failed\")].status}" 2>/dev/null | grep -q "True"; then
      echo "Job '$TRAIN_JOB_NAME' has failed" >&2
      echo "Failed"  # Output status to stdout
      return 1
    fi
    
    # Log progress periodically (every 30 seconds)
    if [ $((iteration % 6)) -eq 0 ]; then
      echo "Waiting for job '$TRAIN_JOB_NAME' to finish ($SECONDS seconds elapsed)..." >&2
    fi
    
    # Check for timeout
    if [ "$SECONDS" -ge "$TIMEOUT" ]; then
      echo "Job '$TRAIN_JOB_NAME' neither completed nor explicitly failed within 10 minutes" >&2
      kubectl describe job "$TRAIN_JOB_NAME" -n "$NAMESPACE" >&2  # Log job details for debugging
      echo "Timeout"  # Output status to stdout
      return 1
    fi
    
    # Wait before the next retry
    sleep "$SLEEP_DURATION"
    iteration=$((iteration + 1))
  done
}