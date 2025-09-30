#!/usr/bin/env python3

import json
import os
import glob
import re
from datetime import datetime
import statistics

def parse_wrk_file(filepath):
    """Parse a wrk output file and extract metrics"""
    with open(filepath, 'r') as f:
        content = f.read()
    
    metrics = {}
    
    # Extract requests per second
    rps_match = re.search(r'Requests/sec:\s+(\d+\.?\d*)', content)
    if rps_match:
        metrics['requests_per_sec'] = float(rps_match.group(1))
    
    # Extract latency
    latency_match = re.search(r'Latency\s+(\d+\.?\d*)(us|ms|s)', content)
    if latency_match:
        latency_value = float(latency_match.group(1))
        latency_unit = latency_match.group(2)
        
        # Convert to milliseconds
        if latency_unit == 'us':
            latency_value = latency_value / 1000
        elif latency_unit == 's':
            latency_value = latency_value * 1000
        
        metrics['latency_ms'] = latency_value
    
    # Extract total requests
    requests_match = re.search(r'(\d+) requests in', content)
    if requests_match:
        metrics['total_requests'] = int(requests_match.group(1))
    
    # Extract transfer rate
    transfer_match = re.search(r'Transfer/sec:\s+(\d+\.?\d*)(KB|MB|GB)', content)
    if transfer_match:
        transfer_value = float(transfer_match.group(1))
        transfer_unit = transfer_match.group(2)
        
        # Convert to MB/s
        if transfer_unit == 'KB':
            transfer_value = transfer_value / 1024
        elif transfer_unit == 'GB':
            transfer_value = transfer_value * 1024
        
        metrics['transfer_mb_per_sec'] = transfer_value
    
    return metrics

def analyze_results():
    """Analyze all benchmark results"""
    # Find all result files
    result_files = glob.glob('*-benchmark-*.txt')
    
    if not result_files:
        print("No benchmark result files found!")
        return
    
    results = {}
    
    for filepath in result_files:
        # Extract runtime name from filename
        runtime = filepath.split('-')[0]
        
        metrics = parse_wrk_file(filepath)
        if metrics:
            results[runtime] = metrics
    
    if not results:
        print("No valid results found!")
        return
    
    # Generate comparison
    print("Benchmark Results Summary")
    print("=" * 50)
    print()
    
    # Requests per second comparison
    if all('requests_per_sec' in v for v in results.values()):
        print("Requests per Second:")
        rps_data = [(k, v['requests_per_sec']) for k, v in results.items()]
        rps_data.sort(key=lambda x: x[1], reverse=True)
        
        for i, (runtime, rps) in enumerate(rps_data):
            rank = i + 1
            print(f"  {rank}. {runtime}: {rps:,.2f} req/s")
        print()
    
    # Latency comparison
    if all('latency_ms' in v for v in results.values()):
        print("Average Latency:")
        latency_data = [(k, v['latency_ms']) for k, v in results.items()]
        latency_data.sort(key=lambda x: x[1])
        
        for i, (runtime, latency) in enumerate(latency_data):
            rank = i + 1
            print(f"  {rank}. {runtime}: {latency:.2f} ms")
        print()
    
    # Generate JSON summary
    summary = {
        'timestamp': datetime.now().isoformat(),
        'results': results,
        'analysis': {
            'best_throughput': max(results.items(), key=lambda x: x[1].get('requests_per_sec', 0))[0],
            'best_latency': min(results.items(), key=lambda x: x[1].get('latency_ms', float('inf')))[0],
        }
    }
    
    with open('analysis-summary.json', 'w') as f:
        json.dump(summary, f, indent=2)
    
    print("Detailed analysis saved to: analysis-summary.json")

if __name__ == "__main__":
    analyze_results()