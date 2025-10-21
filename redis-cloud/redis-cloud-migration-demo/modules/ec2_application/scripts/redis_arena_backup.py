#!/usr/bin/env python3
"""
RedisArena - Gaming Platform (FIXED VERSION)
- Fix Load Game Data button response
- Fix profile stats to start at 0
"""

import os
import redis
import json
import time
import random
import threading
import logging
import re
from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import Dict, List, Optional
from flask import Flask, render_template, jsonify, request
from flask_socketio import SocketIO, emit
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class RedisConfig:
    host: str
    port: int
    password: str
    db: int

class RedisManager:
    def __init__(self, config: RedisConfig):
        # Create connection pool for thread-safe operations
        self.connection_pool = redis.ConnectionPool(
            host=config.host,
            port=config.port,
            password=config.password if config.password else None,
            db=config.db,
            decode_responses=True,
            socket_keepalive=True,
            socket_keepalive_options={},
            health_check_interval=30,
            max_connections=20,  # Pool size for concurrent operations
            retry_on_timeout=True
        )
        self.connection = redis.Redis(connection_pool=self.connection_pool)
        self._test_connection()
    
    def _test_connection(self):
        try:
            self.connection.ping()
            logger.info(f"✅ Connected to Redis at {self.connection_pool.connection_kwargs['host']}:{self.connection_pool.connection_kwargs['port']} with pool size 20")
        except Exception as e:
            logger.error(f"❌ Redis connection failed: {e}")
            raise
    
    def get_connection(self):
        """Get a connection from the pool (thread-safe)"""
        return redis.Redis(connection_pool=self.connection_pool)

# Player names for realistic leaderboard
PLAYER_NAMES = [
    "Shadow_Warrior", "Lightning_Strike", "Phoenix_Fire", "Ice_Queen", "Storm_Rider",
    "Blade_Master", "Night_Hunter", "Fire_Dragon", "Steel_Wolf", "Thunder_God",
    "Dark_Knight", "Frost_Mage", "Blood_Reaper", "Wind_Walker", "Stone_Crusher",
    "Flash_Bang", "Venom_Strike", "Cyber_Ninja", "Plasma_Gun", "Quantum_Leap",
    "Neon_Ghost", "Turbo_Boost", "Laser_Beam", "Rocket_Jump", "Power_Surge",
    "Alpha_Wolf", "Beta_Test", "Gamma_Ray", "Delta_Force", "Omega_Strike",
    "Nova_Blast", "Comet_Tail", "Asteroid_Belt", "Galaxy_Guard", "Cosmic_Dust",
    "Pixel_Perfect", "Code_Breaker", "Data_Stream", "Circuit_Board", "Binary_Beast",
    "Mystic_Sword", "Legendary_Bow", "Epic_Shield", "Magic_Wand", "Sacred_Rune",
    "Battle_Axe", "War_Hammer", "Steel_Blade", "Silver_Arrow", "Golden_Crown"
]

# Chat messages for realistic activity
CHAT_TEMPLATES = [
    "GG everyone! 🎮",
    "Who wants to team up?",
    "Epic match! 🔥",
    "Anyone up for a challenge?",
    "New high score! 💪",
    "This game is intense!",
    "Great teamwork guys",
    "Ready for round 2?",
    "Nice moves @{player}!",
    "That was close! 😅",
    "Level up! 🎊",
    "Achievement unlocked!",
    "Lag is killing me 😤",
    "Best game ever!",
    "Who's leading now?",
    "Time for revenge 😈",
    "Clutch play right there",
    "Can't stop playing!",
    "One more game?",
    "Victory! 🏆"
]

class RedisArenaApp:
    def __init__(self, config: RedisConfig):
        self.redis_mgr = RedisManager(config)
        self.app = Flask(__name__)
        self.app.config['SECRET_KEY'] = os.getenv('FLASK_SECRET_KEY', 'redis-arena-demo-key-change-in-production')
        self.socketio = SocketIO(self.app, cors_allowed_origins="*")
        
        # Application state
        self.simulation_active = False
        self.data_loaded = False
        self.demo_counter_value = 0
        
        # Performance tracking
        self.ops_per_second = 0
        self.total_operations = 0
        self.last_ops_time = time.time()
        
        # Thread management
        self.worker_threads = []
        self.performance_thread = None
        self.demo_thread = None
        
        self._setup_routes()
        self._setup_websocket_handlers()
        
        # AUTO-DETECT EXISTING DATA ON STARTUP (Migration-friendly)
        self._auto_detect_and_continue()
    
    def _validate_player_name(self, name: str) -> bool:
        """Validate player name for security"""
        if not name or not isinstance(name, str):
            return False
        # Allow alphanumeric, spaces, underscores, dashes (max 30 chars)
        return bool(re.match(r'^[a-zA-Z0-9_\-\s]{1,30}$', name))
    
    def _validate_message_content(self, content: str) -> bool:
        """Validate message content for security"""
        if not content or not isinstance(content, str):
            return False
        # Basic length and content validation (max 200 chars, no HTML/script tags)
        if len(content) > 200:
            return False
        # Block potential script injection
        dangerous_patterns = ['<script', 'javascript:', 'onload=', 'onerror=']
        content_lower = content.lower()
        return not any(pattern in content_lower for pattern in dangerous_patterns)
    
    def _sanitize_html(self, text: str) -> str:
        """Basic HTML sanitization"""
        if not isinstance(text, str):
            return ""
        # Replace basic HTML entities
        return (text.replace('<', '&lt;')
                   .replace('>', '&gt;')
                   .replace('"', '&quot;')
                   .replace("'", '&#x27;'))
    
    def _auto_detect_and_continue(self):
        """Auto-detect existing data and continue simulation seamlessly after restart"""
        try:
            logger.info("🔍 Auto-detecting existing data for seamless restart...")
            
            # Check if we have existing leaderboard data
            leaderboard_count = self.redis_mgr.connection.zcard('leaderboard:global')
            
            # Check if we have existing demo counter
            existing_counter = self.redis_mgr.connection.get('migration:demo:counter')
            
            if leaderboard_count > 0:
                logger.info(f"✅ Found existing data: {leaderboard_count} players in leaderboard")
                self.data_loaded = True
                
                # Continue demo counter from existing value (don't reset!)
                if existing_counter:
                    self.demo_counter_value = int(existing_counter)
                    logger.info(f"🔢 Continuing demo counter from: {self.demo_counter_value}")
                else:
                    self.demo_counter_value = 0
                    logger.info("🔢 Starting demo counter from 0")
                
                # Auto-start simulation for seamless experience
                logger.info("🚀 Auto-starting simulation with existing data...")
                self.start_simulation()
            else:
                logger.info("📭 No existing data found - waiting for manual initialization")
                
        except Exception as e:
            logger.error(f"Error during auto-detection: {e}")
            # Fallback to manual mode if auto-detection fails
            logger.info("⚠️ Falling back to manual initialization mode")
    
    def _get_profile_stats(self):
        """Get real-time profile statistics"""
        try:
            if not self.data_loaded:
                return {
                    'total_players': 0,
                    'active_games': 0,
                    'high_score': '0',
                    'server_status': 'Ready'
                }
            
            # Use Redis pipeline for efficient batch operations
            pipe = self.redis_mgr.connection.pipeline()
            pipe.zcard('leaderboard:global')                                  # 0: total_players
            pipe.scard('online:players')                                      # 1: online_count  
            pipe.zrevrange('leaderboard:global', 0, 0, withscores=True)      # 2: top_player
            results = pipe.execute()
            
            total_players = results[0] or 0
            online_count = results[1] or 0
            top_player = results[2] or []
            high_score = int(top_player[0][1]) if top_player else 0
            
            return {
                'total_players': total_players,
                'active_games': online_count,
                'high_score': f'{high_score:,}',
                'server_status': 'Running' if self.simulation_active else 'Loaded'
            }
        except Exception as e:
            logger.error(f"Error getting profile stats: {e}")
            return {
                'total_players': 0,
                'active_games': 0,
                'high_score': '0',
                'server_status': 'Error'
            }
    
    def _setup_routes(self):
        @self.app.route('/')
        def home():
            return render_template('index.html')
        
        @self.app.route('/api/stats')
        def get_stats():
            try:
                # Always return profile stats
                profile_stats = self._get_profile_stats()
                
                if not self.simulation_active:
                    return jsonify({
                        'success': True,
                        'leaderboard': [],
                        'recent_messages': [],
                        'online_count': 0,
                        'ops_per_second': 0,
                        'demo_counter': 0,
                        'profile_stats': profile_stats,
                        'simulation_running': False,
                        'data_loaded': self.data_loaded
                    })
                
                # Use Redis pipeline for efficient batch operations
                pipe = self.redis_mgr.connection.pipeline()
                pipe.zrevrange('leaderboard:global', 0, 9, withscores=True)  # 0: leaderboard
                pipe.lrange('messages:global', 0, 19)                        # 1: messages
                pipe.scard('online:players')                                  # 2: online_count
                pipe.get('migration:demo:counter')                           # 3: demo_counter
                results = pipe.execute()
                
                # Process results from pipeline
                leaderboard_data = results[0] or []
                leaderboard = [{'player': player, 'score': int(score)} for player, score in leaderboard_data]
                
                recent_messages = results[1] or []
                messages = [json.loads(msg) for msg in recent_messages] if recent_messages else []
                
                online_count = results[2] or 0
                demo_counter = results[3] or 0
                
                return jsonify({
                    'success': True,
                    'leaderboard': leaderboard,
                    'recent_messages': messages,
                    'online_count': online_count,
                    'ops_per_second': self.ops_per_second,
                    'demo_counter': int(demo_counter),
                    'profile_stats': profile_stats,
                    'simulation_running': True,
                    'data_loaded': self.data_loaded
                })
            except Exception as e:
                logger.error(f"Error getting stats: {e}")
                return jsonify({'success': False, 'error': str(e)})
        
        @self.app.route('/api/load-data', methods=['POST'])
        def load_data():
            try:
                logger.info("🎮 Loading game data request received...")
                
                if self.simulation_active:
                    logger.warning("Cannot load data while simulation is running")
                    return jsonify({'success': False, 'message': 'Stop simulation first'})
                
                logger.info("🎮 Starting data load process...")
                self._load_initial_data()
                self.data_loaded = True
                logger.info("✅ Game data loaded successfully!")
                
                return jsonify({'success': True, 'message': 'Game data loaded successfully!'})
            except Exception as e:
                logger.error(f"Error loading data: {e}")
                return jsonify({'success': False, 'error': str(e)})
        
        @self.app.route('/api/start-simulation', methods=['POST'])
        def start_simulation():
            try:
                if not self.data_loaded:
                    return jsonify({'success': False, 'message': 'Load data first'})
                
                # Only reset counter for manual starts (not auto-continue)
                if self.demo_counter_value == 0:
                    logger.info("🔢 Manual start - resetting demo counter")
                
                self.start_simulation()
                return jsonify({'success': True, 'message': 'Gaming simulation started!'})
            except Exception as e:
                logger.error(f"Error starting simulation: {e}")
                return jsonify({'success': False, 'error': str(e)})
        
        @self.app.route('/api/stop-simulation', methods=['POST'])
        def stop_simulation():
            try:
                self.stop_simulation()
                return jsonify({'success': True, 'message': 'Simulation stopped'})
            except Exception as e:
                logger.error(f"Error stopping simulation: {e}")
                return jsonify({'success': False, 'error': str(e)})
    
    def _setup_websocket_handlers(self):
        @self.socketio.on('connect')
        def handle_connect():
            logger.info('Client connected')
            emit('status', {'connected': True})
        
        @self.socketio.on('disconnect')
        def handle_disconnect():
            logger.info('Client disconnected')
    
    def _load_initial_data(self):
        """Load initial leaderboard and setup data structures"""
        logger.info("🎮 Loading initial gaming data...")
        
        # Clear existing data
        pipe = self.redis_mgr.connection.pipeline()
        pipe.delete('leaderboard:global', 'messages:global', 'online:players')
        
        # Create initial leaderboard with varied scores (1-100k)
        for i, player in enumerate(random.sample(PLAYER_NAMES, 30)):
            # Create realistic score distribution
            if i < 5:  # Top players
                score = random.randint(80000, 100000)
            elif i < 15:  # Good players  
                score = random.randint(25000, 79999)
            else:  # Average players
                score = random.randint(1, 24999)
            
            pipe.zadd('leaderboard:global', {player: score})
            
            # Add to online players
            pipe.sadd('online:players', player)
            
            # Create user session
            session_data = {
                'username': player,
                'level': random.randint(1, 50),
                'games_played': random.randint(10, 500),
                'wins': random.randint(5, 200),
                'last_seen': datetime.now().isoformat(),
                'status': 'online'
            }
            pipe.hset(f'user:session:{player}', mapping=session_data)
        
        pipe.execute()
        logger.info("✅ Initial gaming data loaded")
    
    def start_simulation(self):
        """Start high-performance gaming simulation"""
        self.simulation_active = True
        # Don't reset demo_counter_value here - let it continue from existing value
        logger.info("🚀 Starting gaming simulation (targeting 1000-2000 ops/sec)...")
        
        # Clear previous threads if any
        self.worker_threads.clear()
        
        # Start simulation threads
        for i in range(4):  # 4 worker threads for high ops
            thread = threading.Thread(target=self._simulation_worker, daemon=False, name=f"GameWorker-{i}")
            thread.start()
            self.worker_threads.append(thread)
        
        # Start demo counter
        self.demo_thread = threading.Thread(target=self._demo_counter_worker, daemon=False)
        self.demo_thread.start()
        
        # Start performance monitor
        self.performance_thread = threading.Thread(target=self._performance_monitor, daemon=False)
        self.performance_thread.start()
        
        logger.info("🔥 Gaming simulation started with 4 worker threads")
    
    def stop_simulation(self):
        """Stop all simulation activity"""
        self.simulation_active = False
        self.demo_counter_value = 0
        logger.info("⏹️ Stopping gaming simulation...")
        
        # Wait for threads to finish gracefully
        logger.info("🧹 Cleaning up worker threads...")
        for thread in self.worker_threads:
            if thread.is_alive():
                thread.join(timeout=2.0)  # 2 second timeout
        
        if self.demo_thread and self.demo_thread.is_alive():
            self.demo_thread.join(timeout=2.0)
            
        if self.performance_thread and self.performance_thread.is_alive():
            self.performance_thread.join(timeout=2.0)
        
        # Clear thread references
        self.worker_threads.clear()
        self.demo_thread = None
        self.performance_thread = None
        
        # Clean up demo counter
        try:
            self.redis_mgr.connection.delete('migration:demo:counter')
            logger.info("🔢 Demo counter removed")
        except Exception as e:
            logger.error(f"Error cleaning demo counter: {e}")
        
        logger.info("✅ All simulation threads stopped")
    
    def _demo_counter_worker(self):
        """Demo counter for migration demonstration"""
        logger.info("🔢 Starting demo counter...")
        
        while self.simulation_active:
            try:
                self.demo_counter_value += 1
                self.redis_mgr.connection.set('migration:demo:counter', self.demo_counter_value)
                
                if self.demo_counter_value % 10 == 0:
                    logger.info(f"🔢 Demo counter: {self.demo_counter_value}")
                
                time.sleep(1)
            except Exception as e:
                logger.error(f"Demo counter error: {e}")
                time.sleep(1)
        
        logger.info("🔢 Demo counter stopped")
    
    def _simulation_worker(self):
        """High-volume gaming simulation worker"""
        while self.simulation_active:
            try:
                # Batch multiple operations for higher throughput
                for _ in range(random.randint(3, 8)):
                    operation = random.choice([
                        'update_leaderboard',
                        'post_message', 
                        'update_session',
                        'player_activity'
                    ])
                    
                    if operation == 'update_leaderboard':
                        self._update_leaderboard()
                    elif operation == 'post_message':
                        self._post_chat_message()
                    elif operation == 'update_session':
                        self._update_player_session()
                    elif operation == 'player_activity':
                        self._simulate_player_activity()
                    
                    self.total_operations += 1
                
                # Small delay for target ops/sec
                time.sleep(random.uniform(0.005, 0.020))  # 5-20ms
                
            except Exception as e:
                logger.error(f"Simulation error: {e}")
                time.sleep(0.1)
    
    def _update_leaderboard(self):
        """Update leaderboard with score changes (high variability)"""
        player = random.choice(PLAYER_NAMES)
        
        # High variability score changes
        change_type = random.choice(['big_win', 'win', 'loss', 'big_loss', 'random'])
        
        if change_type == 'big_win':
            score_change = random.randint(1000, 5000)
        elif change_type == 'win':
            score_change = random.randint(100, 999)
        elif change_type == 'loss':
            score_change = random.randint(-500, -50)
        elif change_type == 'big_loss':
            score_change = random.randint(-2000, -501)
        else:  # random
            score_change = random.randint(-1000, 2000)
        
        # Apply score change
        new_score = self.redis_mgr.connection.zincrby('leaderboard:global', score_change, player)
        
        # Ensure score stays within bounds (1-100k)
        if new_score < 1:
            self.redis_mgr.connection.zadd('leaderboard:global', {player: 1})
        elif new_score > 100000:
            self.redis_mgr.connection.zadd('leaderboard:global', {player: 100000})
    
    def _post_chat_message(self):
        """Post realistic chat message"""
        player = random.choice(PLAYER_NAMES)
        template = random.choice(CHAT_TEMPLATES)
        
        # Validate player name
        if not self._validate_player_name(player):
            logger.warning(f"Invalid player name: {player}")
            return
        
        # Replace placeholder if exists
        if '{player}' in template:
            target_player = random.choice([p for p in PLAYER_NAMES if p != player])
            message_text = template.replace('{player}', target_player)
        else:
            message_text = template
        
        # Validate and sanitize message content
        if not self._validate_message_content(message_text):
            logger.warning(f"Invalid message content: {message_text}")
            return
        
        message = {
            'player': self._sanitize_html(player),
            'message': self._sanitize_html(message_text),
            'timestamp': datetime.now().isoformat(),
            'type': 'chat'
        }
        
        # Add to message list (keep last 50 messages)
        pipe = self.redis_mgr.connection.pipeline()
        pipe.lpush('messages:global', json.dumps(message))
        pipe.ltrim('messages:global', 0, 49)
        pipe.execute()
    
    def _update_player_session(self):
        """Update player session data"""
        player = random.choice(PLAYER_NAMES)
        
        updates = {
            'last_seen': datetime.now().isoformat(),
            'games_played': random.randint(1, 3)  # Increment games
        }
        
        # Randomly update other stats
        if random.random() < 0.3:
            updates['wins'] = random.randint(0, 2)
        
        self.redis_mgr.connection.hincrby(f'user:session:{player}', 'games_played', updates['games_played'])
        self.redis_mgr.connection.hset(f'user:session:{player}', 'last_seen', updates['last_seen'])
    
    def _simulate_player_activity(self):
        """Simulate various player activities"""
        activity = random.choice(['join', 'leave', 'achievement', 'status_update'])
        player = random.choice(PLAYER_NAMES)
        
        if activity == 'join':
            self.redis_mgr.connection.sadd('online:players', player)
        elif activity == 'leave':
            self.redis_mgr.connection.srem('online:players', player)
        elif activity == 'achievement':
            # Post achievement message
            # Validate player name before creating achievement message
            if not self._validate_player_name(player):
                logger.warning(f"Invalid player name for achievement: {player}")
                return
                
            message = {
                'player': self._sanitize_html(player),
                'message': self._sanitize_html(f'{player} unlocked an achievement! 🏆'),
                'timestamp': datetime.now().isoformat(),
                'type': 'achievement'
            }
            # Use pipeline to add message and maintain list size limit
            pipe = self.redis_mgr.connection.pipeline()
            pipe.lpush('messages:global', json.dumps(message))
            pipe.ltrim('messages:global', 0, 49)  # Keep last 50 messages
            pipe.execute()
        elif activity == 'status_update':
            # Update player status
            status = random.choice(['playing', 'idle', 'in-menu'])
            self.redis_mgr.connection.hset(f'user:session:{player}', 'status', status)
    
    def _performance_monitor(self):
        """Monitor operations per second"""
        while self.simulation_active:
            time.sleep(5)  # Update every 5 seconds
            
            current_time = time.time()
            time_diff = current_time - self.last_ops_time
            
            if time_diff > 0:
                self.ops_per_second = int((self.total_operations) / time_diff)
                logger.info(f"⚡ Performance: {self.ops_per_second} ops/sec")
                
                # Reset counters
                self.total_operations = 0
                self.last_ops_time = current_time
    
    def run(self, host='0.0.0.0', port=5000, debug=False):
        """Run the RedisArena application"""
        logger.info(f"🚀 Starting RedisArena Gaming Platform on {host}:{port}")
        self.socketio.run(self.app, host=host, port=port, debug=debug)

def load_config() -> RedisConfig:
    """Load Redis configuration from environment"""
    load_dotenv("/opt/redisarena/.env")
    
    return RedisConfig(
        host=os.environ.get("REDIS_HOST", "localhost"),
        port=int(os.environ.get("REDIS_PORT", 6379)),
        password=os.environ.get("REDIS_PASSWORD", ""),
        db=int(os.environ.get("REDIS_DB", 0))
    )

if __name__ == "__main__":
    try:
        config = load_config()
        app = RedisArenaApp(config)
        app.run(host="0.0.0.0", port=5000, debug=False)
    except Exception as e:
        logger.error(f"Failed to start RedisArena: {e}")
        raise