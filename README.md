# Laravel Benchmark (Custom Fork)

This is a fork of the [`thecaliskan/laravel-benchmark`](https://github.com/thecaliskan/laravel-benchmark) project, updated to benchmark **Laravel 12** on **PHP 8.4**.

This fork includes several enhancements:
* Support for the **ARM64 architecture (Apple Silicon)**.
* A **PHP-FPM + Nginx** service for performance comparison.
* An **automation script** to run all benchmarks at once.

## 🛠️ Stack

This benchmark runs on the following stack:

* **PHP:** 8.4
* **Laravel Framework:** 12
* **Application Servers:** Swoole, FrankenPHP
* **Traditional Server:** Nginx + PHP-FPM

---

## 🚀 Setup and Execution

Unlike the original project, this setup requires building the Docker images locally to ensure compatibility with your CPU architecture.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/stephenroque/laravel-benchmark.git
    cd laravel-benchmark
    ```

2.  **Build and run the containers:**
    ```bash
    docker compose up -d --build
    ```
    The `--build` flag is essential on the first run to build the custom images.

---

## 📊 Benchmark

You can run the tests in two ways:

### 1. Automated Benchmark (Recommended)

Use the provided script to run all tests in sequence and save the results to a `benchmark.txt` file.

1.  **Make the script executable (only needed once):**
    ```bash
    chmod +x run_benchmark.sh
    ```

2.  **Run the tests:**
    ```bash
    ./run_benchmark.sh
    ```

### 2. Manual Benchmark

If you prefer to test each service individually, use the `wrk` commands below.

#### Swoole

```bash
wrk -t16 -c100 -d30s --latency  http://127.0.0.1:9802/api/health-check
wrk -t16 -c100 -d30s --latency  http://127.0.0.1:9802/api/static
wrk -t16 -c100 -d30s --latency  http://127.0.0.1:9802/api/http-request
```

#### FrankenPHP

```bash
wrk -t16 -c100 -d30s --latency  http://127.0.0.1:9804/api/health-check
wrk -t16 -c100 -d30s --latency  http://127.0.0.1:9804/api/static
wrk -t16 -c100 -d30s --latency  http://127.0.0.1:9804/api/http-request
```

#### PHP-FPM

```bash
wrk -t16 -c100 -d30s --latency  http://127.0.0.1:9805/api/health-check
wrk -t16 -c100 -d30s --latency  http://127.0.0.1:9805/api/static
wrk -t16 -c100 -d30s --latency  http://127.0.0.1:9805/api/http-request
```
