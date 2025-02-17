#!/bin/bash

REPORTS_DIR="reports"
OUTPUT_FILE="report.md"

echo "# Load Test Results" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "| Scenario | Payload size | Concurrent users | Requests/s | Error rate |" >> "$OUTPUT_FILE"
echo "|----------|-------------|------------------|------------| ----------- |" >> "$OUTPUT_FILE"

for report in "$REPORTS_DIR"/*.txt; do
    if [[ -f "$report" ]]; then
        filename=$(basename -- "$report")
        scenario=$(echo "$filename" | cut -d'_' -f1)
        payload=$(echo "$filename" | cut -d'_' -f2)
        users=$(echo "$filename" | cut -d'_' -f3 | cut -d'.' -f1)
        
        requests_per_sec=$(grep "finished in" "$report" | awk '{print $(NF-2)}')
        total_requests=$(grep "requests:" | awk '{print $6}')
        success_requests=$(grep "requests:" | awk '{print $8}')
        error_rate=$(awk "BEGIN {printf \"%.2f\", (1 - ($success_requests/$total_requests))*100}")
        
        echo "| $scenario | $payload | $users | $requests_per_sec | $error_rate |" >> "$OUTPUT_FILE"
    fi
done

echo "[INFO] Results saved to $OUTPUT_FILE"