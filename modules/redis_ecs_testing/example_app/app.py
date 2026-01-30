#!/usr/bin/env python3
"""
Redis ECS Testing - Example Application

This is a sample application demonstrating how to build a Redis test client
that can be deployed to ECS for scale testing. Replace this with your own
application logic while keeping the environment variable interface.

Environment Variables (automatically set by the ECS module):
    REDIS_HOST     - Redis endpoint hostname
    REDIS_PORT     - Redis endpoint port
    REDIS_PASSWORD - Redis AUTH password (optional)
    REDIS_REGION   - AWS region this task is running in
    TEST_MODE      - Test mode: ping, read, write, mixed

Custom Environment Variables (set via app_environment):
    OPERATIONS_PER_SECOND - Target ops/sec (default: 100)
    KEY_PREFIX            - Prefix for Redis keys (default: "test")
    REPORT_INTERVAL       - Stats reporting interval in seconds (default: 10)
"""

import os
import sys
import time
import random
import string
import signal
import logging
from datetime import datetime

# Configure logging for CloudWatch
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

try:
    import redis
except ImportError:
    logger.error("Redis package not installed. Run: pip install redis")
    sys.exit(1)


class RedisTestApp:
    """
    Example Redis application for scale testing.

    Customize this class with your application logic:
    - Add your data models
    - Implement your access patterns
    - Add business logic that uses Redis
    """

    def __init__(self):
        # Read configuration from environment
        self.host = os.environ.get("REDIS_HOST", "localhost")
        self.port = int(os.environ.get("REDIS_PORT", "6379"))
        self.password = os.environ.get("REDIS_PASSWORD") or None
        self.region = os.environ.get("REDIS_REGION", "local")
        self.test_mode = os.environ.get("TEST_MODE", "mixed")

        # Custom configuration
        self.ops_per_second = int(os.environ.get("OPERATIONS_PER_SECOND", "100"))
        self.key_prefix = os.environ.get("KEY_PREFIX", "test")
        self.report_interval = int(os.environ.get("REPORT_INTERVAL", "10"))

        # Statistics
        self.stats = {
            "reads": 0,
            "writes": 0,
            "errors": 0,
            "start_time": time.time()
        }

        # Graceful shutdown
        self.running = True
        signal.signal(signal.SIGTERM, self._handle_shutdown)
        signal.signal(signal.SIGINT, self._handle_shutdown)

        # Connect to Redis
        self.client = self._connect()

    def _handle_shutdown(self, signum, frame):
        """Handle graceful shutdown."""
        logger.info(f"Received signal {signum}, shutting down gracefully...")
        self.running = False

    def _connect(self) -> redis.Redis:
        """Establish Redis connection."""
        logger.info(f"Connecting to Redis at {self.host}:{self.port} (region: {self.region})")

        client = redis.Redis(
            host=self.host,
            port=self.port,
            password=self.password,
            decode_responses=True,
            socket_connect_timeout=5,
            socket_timeout=5,
            retry_on_timeout=True
        )

        # Test connection
        try:
            pong = client.ping()
            logger.info(f"Connected successfully! PING response: {pong}")
        except redis.AuthenticationError:
            logger.error("Authentication failed. Check REDIS_PASSWORD.")
            sys.exit(1)
        except redis.ConnectionError as e:
            logger.error(f"Failed to connect to Redis: {e}")
            sys.exit(1)

        return client

    def _generate_key(self) -> str:
        """Generate a random key for testing."""
        return f"{self.key_prefix}:{self.region}:{random.randint(1, 10000)}"

    def _generate_value(self) -> str:
        """Generate random data payload."""
        return ''.join(random.choices(string.ascii_letters + string.digits, k=100))

    # =========================================================================
    # EXAMPLE OPERATIONS - Replace these with your application logic
    # =========================================================================

    def do_write(self):
        """
        Example write operation.
        Replace with your write logic (e.g., cache user session, store event).
        """
        key = self._generate_key()
        value = self._generate_value()

        # Example: SET with expiration
        self.client.setex(key, 300, value)  # 5 minute TTL
        self.stats["writes"] += 1

    def do_read(self):
        """
        Example read operation.
        Replace with your read logic (e.g., fetch cached data, get session).
        """
        key = self._generate_key()

        # Example: GET operation
        value = self.client.get(key)
        self.stats["reads"] += 1
        return value

    def do_mixed_operation(self):
        """
        Example mixed workload (common pattern: read-heavy with some writes).
        Replace with your typical access pattern.
        """
        # 80% reads, 20% writes (adjust to match your workload)
        if random.random() < 0.8:
            self.do_read()
        else:
            self.do_write()

    def do_complex_operation(self):
        """
        Example of more complex Redis operations.
        Shows pipelines, transactions, data structures.
        """
        user_id = random.randint(1, 1000)

        # Use pipeline for multiple operations
        with self.client.pipeline() as pipe:
            # Increment page view counter
            pipe.incr(f"{self.key_prefix}:pageviews:{user_id}")

            # Add to sorted set (leaderboard pattern)
            pipe.zincrby(f"{self.key_prefix}:leaderboard", 1, f"user:{user_id}")

            # Add to recent activity list
            pipe.lpush(f"{self.key_prefix}:activity:{user_id}", datetime.now().isoformat())
            pipe.ltrim(f"{self.key_prefix}:activity:{user_id}", 0, 99)  # Keep last 100

            # Execute all commands
            pipe.execute()

        self.stats["writes"] += 4

    # =========================================================================
    # MAIN LOOP
    # =========================================================================

    def report_stats(self):
        """Log current statistics."""
        elapsed = time.time() - self.stats["start_time"]
        total_ops = self.stats["reads"] + self.stats["writes"]
        ops_per_sec = total_ops / elapsed if elapsed > 0 else 0

        logger.info(
            f"Stats: reads={self.stats['reads']}, writes={self.stats['writes']}, "
            f"errors={self.stats['errors']}, ops/sec={ops_per_sec:.1f}, "
            f"elapsed={elapsed:.1f}s"
        )

    def run(self):
        """Main execution loop."""
        logger.info(f"Starting test in '{self.test_mode}' mode at {self.ops_per_second} ops/sec")

        sleep_time = 1.0 / self.ops_per_second
        last_report = time.time()

        while self.running:
            try:
                # Execute operation based on mode
                if self.test_mode == "ping":
                    self.client.ping()
                    self.stats["reads"] += 1
                elif self.test_mode == "read":
                    self.do_read()
                elif self.test_mode == "write":
                    self.do_write()
                elif self.test_mode == "mixed":
                    self.do_mixed_operation()
                elif self.test_mode == "complex":
                    self.do_complex_operation()
                else:
                    self.do_mixed_operation()

            except redis.RedisError as e:
                self.stats["errors"] += 1
                logger.warning(f"Redis error: {e}")
                time.sleep(1)  # Back off on errors
                continue

            # Report stats periodically
            if time.time() - last_report >= self.report_interval:
                self.report_stats()
                last_report = time.time()

            # Rate limiting
            time.sleep(sleep_time)

        # Final stats on shutdown
        logger.info("Shutdown complete. Final stats:")
        self.report_stats()


if __name__ == "__main__":
    app = RedisTestApp()
    app.run()
