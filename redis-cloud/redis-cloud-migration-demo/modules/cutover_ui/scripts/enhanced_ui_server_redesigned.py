#!/usr/bin/env python3
"""
Redis Migration Control Panel - Final Optimized Version
Clean, organized layout with simplified functions and improved maintainability
"""
from flask import Flask, jsonify, render_template
import logging
import subprocess
import os
import time
from datetime import datetime
from typing import Dict, Optional, Tuple, Any, List
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv('/opt/cutover-ui/.env')

app = Flask(__name__, template_folder="templates")
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# =============================================================================
# CORE UTILITY FUNCTIONS
# =============================================================================

def execute_subprocess_with_timeout(cmd: List[str], timeout: int = 30) -> Tuple[bool, str, str]:
    """
    Execute a subprocess command with proper error handling and timeout.
    
    Args:
        cmd: List of command arguments
        timeout: Command timeout in seconds
        
    Returns:
        Tuple of (success: bool, stdout: str, stderr: str)
    """
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
    except subprocess.TimeoutExpired:
        return False, "", f"Command timed out after {timeout} seconds"
    except Exception as e:
        return False, "", str(e)

def read_env_file(file_path: str) -> Dict[str, str]:
    """
    Parse environment file and return key-value pairs.
    
    Args:
        file_path: Path to the environment file
        
    Returns:
        Dict of environment variables
    """
    env_vars = {}
    if os.path.exists(file_path):
        try:
            with open(file_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and '=' in line and not line.startswith('#'):
                        key, value = line.split('=', 1)
                        env_vars[key.strip()] = value.strip()
        except Exception as e:
            logger.error(f"Error reading env file {file_path}: {e}")
    return env_vars

def create_json_response(success: bool, message: str, **kwargs) -> Dict[str, Any]:
    """
    Create a standardized JSON response.
    
    Args:
        success: Whether the operation was successful
        message: Response message
        **kwargs: Additional data to include in response
        
    Returns:
        Dict containing the response
    """
    response = {"success": success, "message": message}
    response.update(kwargs)
    return response

def execute_ssh_command(host: str, command: str, timeout: int = 10) -> Tuple[bool, str, str]:
    """
    Execute SSH command on remote host with proper error handling.
    
    Args:
        host: Target host (e.g., 'ubuntu@ec2-host.amazonaws.com')
        command: Command to execute
        timeout: Command timeout in seconds
        
    Returns:
        Tuple of (success: bool, stdout: str, stderr: str)
    """
    ssh_key_path = os.getenv("SSH_KEY_PATH", "/home/ubuntu/bamos-aws-us-west-2.pem")
    cmd = [
        "ssh", "-i", ssh_key_path,
        "-o", "StrictHostKeyChecking=no",
        host, command
    ]
    return execute_subprocess_with_timeout(cmd, timeout)

# =============================================================================
# REDIS UTILITY FUNCTIONS
# =============================================================================

def get_redis_connection_config(database_type: str) -> Dict[str, str]:
    """
    Get Redis connection configuration for a specific database type.
    
    Args:
        database_type: Either 'elasticache' or 'redis_cloud'
        
    Returns:
        Dict containing host, port, and password (if applicable)
    """
    configs = {
        'elasticache': {
            'host': os.getenv("ELASTICACHE_HOST", "elasticache-example.cache.amazonaws.com"),
            'port': os.getenv("ELASTICACHE_PORT", "6379"),
            'password': os.getenv("ELASTICACHE_PASSWORD", "")
        },
        'redis_cloud': {
            'host': os.getenv("REDIS_CLOUD_HOST", ""),
            'port': os.getenv("REDIS_CLOUD_PORT", ""),
            'password': os.getenv("REDIS_CLOUD_PASSWORD", "")
        }
    }
    
    if database_type not in configs:
        raise ValueError(f"Unknown database type: {database_type}")
    
    return configs[database_type]

def build_redis_cli_command(database_type: str, redis_command: List[str]) -> List[str]:
    """
    Build redis-cli command with proper authentication.
    
    Args:
        database_type: Either 'elasticache' or 'redis_cloud'
        redis_command: Redis command to execute
        
    Returns:
        Complete command list for subprocess
    """
    config = get_redis_connection_config(database_type)
    
    cmd = ["redis-cli", "-h", config['host'], "-p", config['port']]
    
    if config['password']:
        cmd.extend(["-a", config['password']])
    
    cmd.extend(redis_command)
    return cmd

def execute_redis_command(database_type: str, command: List[str], timeout: int = 30) -> Tuple[bool, str, str]:
    """
    Execute a Redis command with proper error handling and connection setup.
    
    Args:
        database_type: Either 'elasticache' or 'redis_cloud'
        command: List of command arguments (e.g., ['dbsize'] or ['flushdb'])
        timeout: Command timeout in seconds
        
    Returns:
        Tuple of (success: bool, stdout: str, stderr: str)
    """
    try:
        config = get_redis_connection_config(database_type)
        
        # Validate configuration for Redis Cloud
        if database_type == 'redis_cloud' and not all([config['host'], config['port'], config['password']]):
            return False, "", "Incomplete Redis Cloud configuration"
        
        cmd = build_redis_cli_command(database_type, command)
        return execute_subprocess_with_timeout(cmd, timeout)
        
    except Exception as e:
        return False, "", str(e)

def get_redis_key_count(database_type: str) -> Tuple[bool, int, str]:
    """
    Get the number of keys in a Redis database.
    
    Args:
        database_type: Either 'elasticache' or 'redis_cloud'
        
    Returns:
        Tuple of (success: bool, key_count: int, error_message: str)
    """
    success, stdout, stderr = execute_redis_command(database_type, ['dbsize'], timeout=5)
    if success and stdout.isdigit():
        return True, int(stdout), ""
    return False, 0, stderr or "Connection failed"

def get_redis_demo_counter(database_type: str) -> str:
    """
    Get the demo counter value with formatted display.
    
    Args:
        database_type: Either 'elasticache' or 'redis_cloud'
        
    Returns:
        Formatted string showing the counter value
    """
    success, stdout, stderr = execute_redis_command(database_type, ['get', 'migration:demo:counter'], timeout=3)
    if success:
        if stdout and stdout != "(nil)":
            return f"🔢 migration:demo:counter = {stdout}"
        else:
            return "🔢 migration:demo:counter = (not set)"
    else:
        return "🔢 migration:demo:counter = (error reading)"

def get_redis_stats(database_type: str) -> Dict[str, Any]:
    """
    Get comprehensive statistics for a Redis database.
    
    Args:
        database_type: Either 'elasticache' or 'redis_cloud'
        
    Returns:
        Dict containing key_count, demo_counter, host, and status information
    """
    config = get_redis_connection_config(database_type)
    
    # Initialize default values
    stats = {
        'key_count': 0,
        'demo_counter': "❌ Unable to connect",
        'host': config['host'],
        'status': 'disconnected'
    }
    
    # Get key count
    success, key_count, error_msg = get_redis_key_count(database_type)
    if success:
        stats['key_count'] = key_count
        stats['status'] = 'connected'
        stats['demo_counter'] = get_redis_demo_counter(database_type)
    else:
        # Handle specific error cases
        if database_type == 'redis_cloud' and "Incomplete Redis Cloud configuration" in error_msg:
            stats['demo_counter'] = "⚠️ Configuration not found"
        else:
            stats['demo_counter'] = f"❌ Error: {error_msg}"
    
    return stats

def flush_redis_database(database_type: str) -> Tuple[bool, str]:
    """
    Flush all keys from a Redis database.
    
    Args:
        database_type: Either 'elasticache' or 'redis_cloud'
        
    Returns:
        Tuple of (success: bool, message: str)
    """
    database_name = database_type.replace('_', ' ').title()
    logger.info(f"Flushing {database_name} database...")
    
    success, stdout, stderr = execute_redis_command(database_type, ['flushdb'], timeout=30)
    
    if success and "OK" in stdout:
        logger.info(f"{database_name} flushed successfully")
        return True, f"{database_name} database flushed successfully! All keys have been deleted."
    else:
        error_msg = stderr or "FLUSHDB command failed"
        logger.error(f"{database_name} flush failed: {error_msg}")
        return False, f"Failed to flush {database_name}: {error_msg}"

# =============================================================================
# CONFIGURATION UTILITY FUNCTIONS
# =============================================================================

def parse_redis_config_from_env(env_content: str) -> Dict[str, str]:
    """
    Parse Redis configuration from environment content.
    
    Args:
        env_content: Content of the environment file
        
    Returns:
        Dict with Redis host, port, and password
    """
    config = {"host": "", "port": "", "password": ""}
    
    for line in env_content.split('\n'):
        line = line.strip()
        if line.startswith('REDIS_HOST='):
            config["host"] = line.split('=', 1)[1].strip()
        elif line.startswith('REDIS_PORT='):
            config["port"] = line.split('=', 1)[1].strip()
        elif line.startswith('REDIS_PASSWORD='):
            config["password"] = line.split('=', 1)[1].strip()
    
    return config

def determine_backend_type(redis_host: str) -> str:
    """
    Determine the backend type based on Redis host.
    
    Args:
        redis_host: Redis host address
        
    Returns:
        Formatted backend type string
    """
    if "cache.amazonaws.com" in redis_host:
        return "🏠 AWS ElastiCache"
    elif "cloud.rlrcp.com" in redis_host:
        return "☁️ Redis Cloud"
    else:
        return "❓ Unknown Backend"

def create_config_summary(redis_config: Dict[str, str], backend_type: str) -> str:
    """
    Create formatted configuration summary.
    
    Args:
        redis_config: Dict with Redis configuration
        backend_type: Backend type string
        
    Returns:
        Formatted configuration summary
    """
    return f"""
{backend_type}
🔗 Host: {redis_config["host"]}
🚪 Port: {redis_config["port"]}
🔐 Auth: {'Yes (password protected)' if redis_config["password"] else 'No (open access)'}

⏰ Last Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"""

def create_app_connection_code(redis_config: Dict[str, str], backend_type: str) -> str:
    """
    Create application connection code display.
    
    Args:
        redis_config: Dict with Redis configuration
        backend_type: Backend type string
        
    Returns:
        Formatted application connection code
    """
    return f"""📁 Application File: /opt/redisarena/redis_arena.py (line ~1069)

🔗 Redis Connection Code:
# RedisArena application connection setup
redis_client = redis.Redis(
    host=os.environ.get("REDIS_HOST", "localhost"),
    port=int(os.environ.get("REDIS_PORT", 6379)),
    password=os.environ.get("REDIS_PASSWORD", None),
    db=int(os.environ.get("REDIS_DB", 0)),
    decode_responses=True,
    max_connections=int(os.environ.get("REDIS_POOL_MAX_CONNECTIONS", 20))
)

🔄 Environment Variable Mapping:
• REDIS_HOST     → host="{redis_config["host"]}"
• REDIS_PORT     → port={redis_config["port"]}
• REDIS_PASSWORD → password={"***" if redis_config["password"] else "None"}
• REDIS_DB       → db=0

💡 How Migration Works:
1. Application uses os.environ.get() to read variables
2. Variables are loaded from .env file at startup
3. Changing .env file + restart = new Redis connection
4. No code changes needed for migration!

📊 Current Active Connection:
{backend_type}
🔗 Connected to: {redis_config["host"]}:{redis_config["port"]}"""

# =============================================================================
# RIOT UTILITY FUNCTIONS
# =============================================================================

def get_riot_host() -> str:
    """Get RIOT host from environment variables."""
    return f"ubuntu@{os.getenv('RIOT_PUBLIC_IP', 'ec2-44-243-4-116.us-west-2.compute.amazonaws.com')}"

def check_riot_process_running() -> Tuple[bool, str]:
    """
    Check if RIOT process is currently running.
    
    Returns:
        Tuple of (is_running: bool, stdout: str)
    """
    host = get_riot_host()
    command = "ps aux | grep 'com.redis.riot.Riotx' | grep -v grep"
    success, stdout, stderr = execute_ssh_command(host, command, timeout=10)
    # For grep commands, exit code 1 (no matches) is normal, not an error
    # Only raise exception for actual SSH connection failures (exit code != 0 and != 1)
    if not success and ("Connection" in stderr or "Permission denied" in stderr):
        raise Exception(f"SSH command failed: {stderr}")
    is_running = len(stdout.strip()) > 0
    return is_running, stdout

def start_riot_process() -> None:
    """Start RIOT process in background."""
    host = get_riot_host()
    command = "cd /home/ubuntu && nohup ./start_riotx.sh > riotx.log 2>&1 &"
    
    # Use Popen for fire-and-forget execution
    ssh_key_path = os.getenv("SSH_KEY_PATH", "/home/ubuntu/bamos-aws-us-west-2.pem")
    subprocess.Popen([
        "ssh", "-i", ssh_key_path,
        "-o", "StrictHostKeyChecking=no",
        host, command
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def stop_riot_processes() -> Tuple[bool, str]:
    """
    Stop all RIOT-related processes.
    
    Returns:
        Tuple of (success: bool, message: str)
    """
    host = get_riot_host()
    
    # Kill RIOT process
    success1, _, stderr1 = execute_ssh_command(host, "pkill -f 'com.redis.riot.Riotx'", timeout=10)
    
    # Kill start script
    success2, _, stderr2 = execute_ssh_command(host, "pkill -f 'start_riotx.sh'", timeout=10)
    
    # pkill returns exit code 1 when no processes found - this is normal
    return True, "RIOT replication stopped successfully"

# =============================================================================
# FLASK ROUTES
# =============================================================================

@app.route("/")
def home():
    return render_template("index.html")

@app.route("/api/test")
def api_test():
    return jsonify(create_json_response(
        True, "Test successful - API is working perfectly!",
        timestamp=datetime.now().isoformat()
    ))

@app.route("/api/start-redisarena", methods=["POST"])
def start_redisarena():
    try:
        logger.info("Starting RedisArena application...")
        success, stdout, stderr = execute_subprocess_with_timeout(
            ["sudo", "systemctl", "start", "redisarena"], timeout=30
        )
        
        if success:
            return jsonify(create_json_response(True, "RedisArena application started successfully!"))
        else:
            return jsonify(create_json_response(False, f"Failed to start RedisArena: {stderr}"))
    except Exception as e:
        return jsonify(create_json_response(False, f"Error starting RedisArena: {str(e)}"))

@app.route("/api/load-data", methods=["POST"])
def load_sample_data():
    try:
        logger.info("Loading sample data into Redis...")
        success, stdout, stderr = execute_subprocess_with_timeout(
            ["/opt/redisarena/load_data.sh"], timeout=300
        )
        
        if success:
            return jsonify(create_json_response(
                True, "Sample gaming data loaded successfully! RedisArena is now populated with player leaderboards and game data."
            ))
        else:
            return jsonify(create_json_response(False, f"Failed to load sample data: {stderr}"))
    except Exception as e:
        return jsonify(create_json_response(False, f"Error loading sample data: {str(e)}"))

@app.route("/api/get-app-url")
def get_app_url():
    try:
        success, public_ip, stderr = execute_subprocess_with_timeout(
            ["curl", "-s", "http://169.254.169.254/latest/meta-data/public-ipv4"], timeout=10
        )
        
        if success and public_ip:
            url = f"http://{public_ip}:5000"
            return jsonify(create_json_response(True, f"RedisArena available at {url}", url=url))
        else:
            # Fallback URL
            fallback_url = "http://44.243.93.201:5000"
            return jsonify(create_json_response(True, f"RedisArena available at {fallback_url}", url=fallback_url))
    except Exception as e:
        fallback_url = "http://44.243.93.201:5000"
        return jsonify(create_json_response(True, f"RedisArena available at {fallback_url}", url=fallback_url))

@app.route("/api/validate-redis-cloud", methods=["POST"])
def validate_redis_cloud():
    try:
        logger.info("Validating Redis Cloud connectivity...")
        success, stdout, stderr = execute_subprocess_with_timeout(
            ["/home/ubuntu/do_cutover.sh", "validate"], timeout=30
        )
        
        if "Redis Cloud connectivity verified" in stdout:
            return jsonify(create_json_response(True, "Redis Cloud connectivity verified successfully!"))
        else:
            error_msg = stderr or stdout or "Validation failed"
            return jsonify(create_json_response(False, f"Redis Cloud PING test failed: {error_msg}"))
    except Exception as e:
        return jsonify(create_json_response(False, f"Error validating Redis Cloud: {str(e)}"))

@app.route("/api/perform-cutover", methods=["POST"])
def perform_cutover():
    try:
        logger.info("Starting Redis Cloud cutover...")
        success, stdout, stderr = execute_subprocess_with_timeout(
            ["/home/ubuntu/do_cutover.sh", "cutover"], timeout=300
        )
        
        if "Cutover completed successfully" in stdout:
            return jsonify(create_json_response(
                True, "Cutover completed successfully! RedisArena is now connected to Redis Cloud."
            ))
        else:
            error_msg = stderr or "Cutover process failed"
            return jsonify(create_json_response(False, f"Cutover failed: {error_msg}"))
    except Exception as e:
        return jsonify(create_json_response(False, f"Error performing cutover: {str(e)}"))

@app.route("/api/perform-rollback", methods=["POST"])
def perform_rollback():
    try:
        logger.info("Starting rollback to ElastiCache...")
        success, stdout, stderr = execute_subprocess_with_timeout(
            ["/home/ubuntu/do_cutover.sh", "rollback"], timeout=300
        )
        
        if "Configuration rolled back" in stdout:
            return jsonify(create_json_response(
                True, "Rollback completed successfully! RedisArena is now connected to ElastiCache."
            ))
        else:
            error_msg = stderr or "Rollback process failed"
            return jsonify(create_json_response(False, f"Rollback failed: {error_msg}"))
    except Exception as e:
        return jsonify(create_json_response(False, f"Error performing rollback: {str(e)}"))

@app.route("/api/restart-redisarena", methods=["POST"])
def restart_redisarena():
    try:
        logger.info("Restarting RedisArena application...")
        success, stdout, stderr = execute_subprocess_with_timeout(
            ["/home/ubuntu/do_cutover.sh", "restart"], timeout=60
        )
        
        if "RedisArena service restarted successfully" in stdout or "Restarting RedisArena" in stdout:
            return jsonify(create_json_response(True, "RedisArena application restarted successfully!"))
        elif success:  # Check if the script ran without error even if the expected message isn't found
            return jsonify(create_json_response(True, "Restart command executed successfully!"))
        else:
            error_msg = stderr or "Restart process failed"
            return jsonify(create_json_response(False, f"Restart failed: {error_msg}"))
    except Exception as e:
        return jsonify(create_json_response(False, f"Error restarting application: {str(e)}"))

@app.route("/api/flush-elasticache", methods=["POST"])
def flush_elasticache():
    """Flush ElastiCache database using shared utility function"""
    try:
        success, message = flush_redis_database('elasticache')
        return jsonify(create_json_response(success, message))
    except Exception as e:
        logger.error(f"Error in flush_elasticache endpoint: {str(e)}")
        return jsonify(create_json_response(False, f"Error flushing ElastiCache: {str(e)}"))

@app.route("/api/flush-redis-cloud", methods=["POST"])
def flush_redis_cloud():
    """Flush Redis Cloud database using shared utility function"""
    try:
        success, message = flush_redis_database('redis_cloud')
        return jsonify(create_json_response(success, message))
    except Exception as e:
        logger.error(f"Error in flush_redis_cloud endpoint: {str(e)}")
        return jsonify(create_json_response(False, f"Error flushing Redis Cloud: {str(e)}"))

@app.route("/api/get-grafana-url")
def get_grafana_url():
    try:
        env_vars = read_env_file("/opt/cutover-ui/.env")
        riot_ip = env_vars.get("RIOT_PUBLIC_IP", "")
        
        if riot_ip:
            grafana_url = f"http://{riot_ip}:3000"
            return jsonify(create_json_response(
                True, f"RIOT-X Grafana available at {grafana_url}",
                url=grafana_url
            ))
        else:
            return jsonify(create_json_response(False, "RIOT IP not found in configuration"))
            
    except Exception as e:
        logger.error(f"Error getting Grafana URL: {str(e)}")
        return jsonify(create_json_response(False, f"Error getting Grafana URL: {str(e)}"))

@app.route("/api/get-database-stats")
def get_database_stats():
    """Get database statistics using refactored utility functions"""
    try:
        logger.info("Getting database statistics...")
        
        # Get stats for both databases using the utility function
        elasticache_stats = get_redis_stats('elasticache')
        redis_cloud_stats = get_redis_stats('redis_cloud')
        
        return jsonify(create_json_response(
            True, "Database statistics retrieved successfully",
            elasticache=elasticache_stats,
            redis_cloud=redis_cloud_stats,
            timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        ))
        
    except Exception as e:
        logger.error(f"Error getting database stats: {str(e)}")
        return jsonify(create_json_response(False, f"Error getting database stats: {str(e)}"))

@app.route("/api/get-config")
def get_config():
    try:
        logger.info("Reading current .env configuration...")
        
        # Read the .env file
        env_file_path = "/opt/redisarena/.env"
        if not os.path.exists(env_file_path):
            return jsonify(create_json_response(False, f"Configuration file not found: {env_file_path}"))
        
        with open(env_file_path, 'r') as f:
            env_content = f.read()
        
        # Parse Redis configuration
        redis_config = parse_redis_config_from_env(env_content)
        backend_type = determine_backend_type(redis_config["host"])
        
        # Create formatted displays
        config_display = f"""📁 Configuration File Path: {env_file_path}

📄 Current Configuration:
{env_content}

📊 Redis Connection Summary:{create_config_summary(redis_config, backend_type)}"""
        
        app_connection_code = create_app_connection_code(redis_config, backend_type)

        return jsonify(create_json_response(
            True, "Configuration retrieved successfully",
            config=config_display,
            app_connection_code=app_connection_code,
            file_path=env_file_path,
            backend_type=backend_type
        ))
        
    except Exception as e:
        logger.error(f"Error reading configuration: {str(e)}")
        return jsonify(create_json_response(False, f"Error reading configuration: {str(e)}"))

# =============================================================================
# RIOT Control API Routes
# =============================================================================

@app.route("/api/riot-status")
def riot_status():
    """Check if RIOT process is running"""
    try:
        logger.info("Checking RIOT status...")
        is_running, stdout = check_riot_process_running()
        
        return jsonify(create_json_response(
            True, "RIOT is running" if is_running else "RIOT is not running",
            running=is_running
        ))
        
    except Exception as e:
        logger.error(f"Error checking RIOT status: {e}")
        return jsonify(create_json_response(False, f"Error: {str(e)}", running=False))

@app.route("/api/start-riot", methods=["POST"])
def start_riot():
    """Start RIOT replication process"""
    try:
        logger.info("Starting RIOT replication...")
        
        # First check if already running
        is_running, _ = check_riot_process_running()
        if is_running:
            return jsonify(create_json_response(False, "RIOT is already running"))
        
        # Start RIOT process
        start_riot_process()
        
        # Wait a moment then verify it started
        time.sleep(3)
        is_running_after, _ = check_riot_process_running()
        
        if is_running_after:
            return jsonify(create_json_response(True, "RIOT replication started successfully"))
        else:
            return jsonify(create_json_response(False, "RIOT process may not have started properly"))
            
    except Exception as e:
        logger.error(f"Error starting RIOT: {e}")
        return jsonify(create_json_response(False, f"Error starting RIOT: {str(e)}"))

@app.route("/api/stop-riot", methods=["POST"])
def stop_riot():
    """Stop RIOT replication process"""
    try:
        logger.info("Stopping RIOT replication...")
        success, message = stop_riot_processes()
        return jsonify(create_json_response(success, message))
            
    except Exception as e:
        logger.error(f"Error stopping RIOT: {e}")
        return jsonify(create_json_response(False, f"Error stopping RIOT: {str(e)}"))

if __name__ == "__main__":
    logger.info("🚀 Starting Redis Migration Control Panel (Final Optimized)...")
    logger.info("🌐 Access at: http://0.0.0.0:8080")
    app.run(
        host=os.getenv("SERVER_HOST", "0.0.0.0"), 
        port=int(os.getenv("SERVER_PORT", "8080")), 
        debug=False
    )