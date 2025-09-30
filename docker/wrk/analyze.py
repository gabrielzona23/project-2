#!/usr/bin/env python3

import json
import re
import os
import sys
import glob
from datetime import datetime

def parse_wrk_output(content):
    """Parse wrk output and extract metrics"""
    results = {}
    
    # Parse requests per second
    rps_match = re.search(r'Requests/sec:\s+(\d+\.?\d*)', content)
    if rps_match:
        results['requests_per_sec'] = float(rps_match.group(1))
    
    # Parse latency
    latency_match = re.search(r'Latency\s+(\d+\.?\d*)(us|ms|s)', content)
    if latency_match:
        latency_value = float(latency_match.group(1))
        latency_unit = latency_match.group(2)
        
        # Convert to milliseconds
        if latency_unit == 'us':
            latency_value = latency_value / 1000
        elif latency_unit == 's':
            latency_value = latency_value * 1000
        
        results['latency_ms'] = latency_value
    
    # Parse transfer rate
    transfer_match = re.search(r'Transfer/sec:\s+(\d+\.?\d*)(KB|MB|GB)', content)
    if transfer_match:
        transfer_value = float(transfer_match.group(1))
        transfer_unit = transfer_match.group(2)
        
        # Convert to MB/s
        if transfer_unit == 'KB':
            transfer_value = transfer_value / 1024
        elif transfer_unit == 'GB':
            transfer_value = transfer_value * 1024
        
        results['transfer_mb_per_sec'] = transfer_value
    
    # Parse total requests
    requests_match = re.search(r'(\d+) requests in', content)
    if requests_match:
        results['total_requests'] = int(requests_match.group(1))
    
    return results

def analyze_benchmark_file(filepath):
    """Analyze a single benchmark file"""
    with open(filepath, 'r') as f:
        content = f.read()
    
    runtime_name = os.path.basename(filepath).split('-')[0]
    
    # Split content by endpoints
    sections = content.split('Endpoint: ')
    results = {
        'runtime': runtime_name,
        'endpoints': {}
    }
    
    for section in sections[1:]:  # Skip first empty section
        lines = section.split('\n')
        endpoint_name = lines[0].strip()
        
        results['endpoints'][endpoint_name] = {}
        
        # Find connection sections
        conn_sections = section.split('Connections: ')
        for conn_section in conn_sections[1:]:
            conn_lines = conn_section.split('\n')
            connections = conn_lines[0].strip()
            
            # Find wrk output
            wrk_start = False
            wrk_content = ""
            for line in conn_lines:
                if 'Running' in line and 'wrk' in line:
                    wrk_start = True
                elif wrk_start and line.strip() == '---':
                    break
                elif wrk_start:
                    wrk_content += line + "\n"
            
            if wrk_content:
                metrics = parse_wrk_output(wrk_content)
                results['endpoints'][endpoint_name][connections] = metrics
    
    return results

def generate_summary(results_dir, timestamp):
    """Generate summary analysis"""
    pattern = os.path.join(results_dir, f"*-benchmark-{timestamp}.txt")
    benchmark_files = glob.glob(pattern)
    
    if not benchmark_files:
        print(f"No benchmark files found for timestamp {timestamp}")
        return
    
    summary = {
        'timestamp': timestamp,
        'runtimes': {},
        'comparisons': {}
    }
    
    # Analyze each runtime
    for filepath in benchmark_files:
        result = analyze_benchmark_file(filepath)
        runtime = result['runtime']
        summary['runtimes'][runtime] = result
    
    # Generate comparisons
    if len(summary['runtimes']) > 1:
        runtimes = list(summary['runtimes'].keys())
        
        for endpoint in ['health', 'database', 'cache', 'file-read', 'file-write', 'api-external']:
            summary['comparisons'][endpoint] = {}
            
            for connections in ['100', '200', '400', '800']:
                runtime_metrics = {}
                
                for runtime in runtimes:
                    try:
                        metrics = summary['runtimes'][runtime]['endpoints'][endpoint][connections]
                        runtime_metrics[runtime] = metrics
                    except KeyError:
                        continue
                
                if runtime_metrics:
                    # Find best performing runtime for each metric
                    best_rps = max(runtime_metrics.items(), 
                                 key=lambda x: x[1].get('requests_per_sec', 0))
                    best_latency = min(runtime_metrics.items(), 
                                     key=lambda x: x[1].get('latency_ms', float('inf')))
                    
                    summary['comparisons'][endpoint][connections] = {
                        'metrics': runtime_metrics,
                        'best_rps': best_rps[0],
                        'best_latency': best_latency[0]
                    }
    
    # Save summary
    summary_file = os.path.join(results_dir, f"summary-{timestamp}.json")
    with open(summary_file, 'w') as f:
        json.dump(summary, f, indent=2)
    
    print(f"Summary analysis saved to: {summary_file}")
    
    # Print quick overview
    print("\nQuick Performance Overview:")
    print("==========================")
    
    for endpoint in ['health', 'database', 'cache']:
        if endpoint in summary['comparisons']:
            conn_400 = summary['comparisons'][endpoint].get('400', {})
            if conn_400:
                best_rps = conn_400.get('best_rps', 'N/A')
                best_latency = conn_400.get('best_latency', 'N/A')
                print(f"{endpoint.upper()} (400 connections):")
                print(f"  Best RPS: {best_rps}")
                print(f"  Best Latency: {best_latency}")
                print()

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 analyze.py <results_dir> <timestamp>")
        sys.exit(1)
    
    results_dir = sys.argv[1]
    timestamp = sys.argv[2]
    
    generate_summary(results_dir, timestamp)