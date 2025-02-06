#!/bin/bash

set -e

BACKEND_DIR="netty-http-transport-sample"
BALLERINA_DIR="ballerina/passthrough"
PAYLOADS_DIR="payloads"
REPORTS_DIR="reports"

SCENARIOS=${SCENARIOS:-("h1-h1" "h1c-h1c" "h1-h2" "h2-h1" "h1c-h2c" "h2c-h1c" "h2c-h2c" "h2-h2")}
PAYLOADS=${PAYLOADS:-("500B" "1000B" "10000B")}
CONCURRENCY=${CONCURRENCY: -(100 200 500 1000)}
LOAD_TEST_DURATION="${LOAD_TEST_DURATION:-1h}"

echo "[INFO] Kill any existing backend and Ballerina service"
pkill -f netty-http-echo-service.jar || true
pkill -f service.jar || true
sleep 5
echo ""

echo "[INFO] Clean up existing reports directory"
rm -rf "$REPORTS_DIR"
echo ""

echo "[INFO] Create reports directory"
mkdir -p "$REPORTS_DIR"
echo ""

run_backend() {
    echo "[INFO] Run the netty backend"
    local scenario=$1
    case $scenario in
        "h1c-h1c"|"h2c-h1c") java -jar "$BACKEND_DIR/target/netty-http-echo-service.jar" & ;;
        "h1c-h2c"|"h2c-h2c") java -jar "$BACKEND_DIR/target/netty-http-echo-service.jar" --http2 true & ;;
        "h1-h1"|"h2-h1") java -jar "$BACKEND_DIR/target/netty-http-echo-service.jar" --ssl true --key-store-file ballerina/resources/ballerinaKeystore.p12 --key-store-password ballerina & ;;
        "h1-h2"|"h2-h2") java -jar "$BACKEND_DIR/target/netty-http-echo-service.jar" --ssl true --http2 true --key-store-file ballerina/resources/ballerinaKeystore.p12 --key-store-password ballerina & ;;
    esac
    sleep 5
    echo ""
}

run_ballerina_service() {
    local scenario=$1
    echo "[INFO] Run the Ballerina $scenario passthrough service"
    (cd "$BALLERINA_DIR/$scenario" && java -jar target/bin/service.jar &)
    sleep 5
    echo ""
}

run_load_test() {
    local scenario=$1
    local payload=$2
    local users=$3
    
    if [[ "$scenario" == h1c-* || "$scenario" == h2c-* ]]; then
        local url="http://localhost:9090/passthrough"
    else
        local url="https://localhost:9090/passthrough"
    fi
    
    case $scenario in
        "h1-h1"|"h1c-h1c"|"h1-h2"|"h1c-h2c") H1LOAD_FLAGS="--h1" ;;
        "h2-h1"|"h2c-h1c"|"h2-h2"|"h2c-h2c") H1LOAD_FLAGS="" ;;
    esac
    
    local report_file="$REPORTS_DIR/${scenario}_${payload}_${users}.txt"
    echo "[INFO] Run load test: Scenario=$scenario, Payload=$payload, Users=$users"
    h2load $H1LOAD_FLAGS -c "$users" -d "$PAYLOADS_DIR/$payload.json" -H 'Content-Type: application/json' -D "$LOAD_TEST_DURATION" --warm-up-time=60s "$url" | tee "$report_file"
    echo ""
}

for scenario in "${SCENARIOS[@]}"; do
    for payload in "${PAYLOADS[@]}"; do
        for users in "${CONCURRENCY[@]}"; do
            run_backend "$scenario"
            run_ballerina_service "$scenario"
            run_load_test "$scenario" "$payload" "$users"
            
            echo "[INFO] Kill backend and Ballerina service"
            pkill -f netty-http-echo-service.jar || true
            pkill -f service.jar || true
            sleep 5
            echo ""
        done
    done
    echo "[INFO] Completed tests for $scenario"
    echo ""
done
