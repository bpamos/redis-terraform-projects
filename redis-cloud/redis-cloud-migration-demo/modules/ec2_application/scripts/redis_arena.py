#!/usr/bin/env python3
"""
RedisArena - High-Performance Gaming Platform (ENHANCED VERSION)
- 1000+ ops/sec for realistic migration demo
- Thousands of keys with TTLs 
- Dynamic leaderboard with realistic score ranges
- Realistic Redis patterns (cache, sessions, rate limiting)
"""

import os
import redis
import json
import time
import random
import threading
import logging
import re
import uuid
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
            max_connections=50,  # Increased for high ops
            retry_on_timeout=True
        )
        self.connection = redis.Redis(connection_pool=self.connection_pool)
        self._test_connection()
    
    def _test_connection(self):
        try:
            self.connection.ping()
            logger.info(f"✅ Connected to Redis at {self.connection_pool.connection_kwargs['host']}:{self.connection_pool.connection_kwargs['port']} with pool size 50")
        except Exception as e:
            logger.error(f"❌ Redis connection failed: {e}")
            raise
    
    def get_connection(self):
        """Get a connection from the pool (thread-safe)"""
        return redis.Redis(connection_pool=self.connection_pool)

# Expanded player names for larger dataset
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
    "Battle_Axe", "War_Hammer", "Steel_Blade", "Silver_Arrow", "Golden_Crown",
    "Dragon_Slayer", "Phoenix_Rising", "Shadow_Clone", "Lightning_Bolt", "Ice_Shard",
    "Fire_Storm", "Wind_Blade", "Earth_Shaker", "Water_Spirit", "Metal_Gear",
    "Neon_Racer", "Cyber_Punk", "Space_Marine", "Time_Traveler", "Dimension_Walker",
    "Quantum_Fighter", "Plasma_Warrior", "Laser_Knight", "Rocket_Ranger", "Turbo_Driver",
    "Speed_Demon", "Power_House", "Energy_Blast", "Force_Field", "Shield_Bearer",
    "Sword_Saint", "Bow_Master", "Staff_Wielder", "Hammer_Time", "Axe_Grinder",
    "Spell_Caster", "Rune_Keeper", "Crystal_Mage", "Elemental_Lord", "Arcane_Scholar",
    "Battle_Mage", "War_Chief", "Guild_Master", "Arena_Champion", "Tournament_King",
    "Legend_Hunter", "Myth_Buster", "Epic_Gamer", "Pro_Player", "Elite_Warrior",
    "Master_Chief", "Commander_X", "Captain_Strike", "General_Storm", "Admiral_Frost",
    "Knight_Rider", "Paladin_Light", "Guardian_Angel", "Defender_Prime", "Protector_Max",
    "Assassin_Swift", "Rogue_Shadow", "Thief_Quick", "Ninja_Fast", "Spy_Silent",
    "Ranger_Wild", "Hunter_Sharp", "Tracker_Keen", "Scout_Alert", "Explorer_Bold",
    "Miner_Deep", "Builder_Strong", "Crafter_Wise", "Smith_Iron", "Engineer_Tech"
]

# Game items and achievements for realistic cache data
GAME_ITEMS = [
    "Legendary_Sword", "Epic_Shield", "Rare_Bow", "Magic_Staff", "Dragon_Armor",
    "Phoenix_Wings", "Lightning_Boots", "Frost_Gloves", "Fire_Ring", "Shadow_Cape",
    "Crystal_Helm", "Mithril_Chain", "Adamant_Plate", "Elven_Cloak", "Dwarven_Axe",
    "Orc_Hammer", "Troll_Club", "Giant_Mace", "Demon_Blade", "Angel_Harp",
    "Healing_Potion", "Mana_Elixir", "Speed_Boost", "Strength_Brew", "Wisdom_Tea",
    "Lucky_Charm", "Exp_Gem", "Gold_Coin", "Silver_Token", "Bronze_Medal"
]

ACHIEVEMENTS = [
    "First_Blood", "Double_Kill", "Triple_Kill", "Monster_Kill", "Unstoppable",
    "Dominating", "Godlike", "Legendary", "Beyond_Godlike", "Rampage",
    "Killing_Spree", "Ultra_Kill", "Perfect_Game", "Flawless_Victory", "Master_Class",
    "Speed_Runner", "Collector", "Explorer", "Guardian", "Destroyer"
]

# Chat messages for realistic activity
CHAT_TEMPLATES = [
    "GG everyone! 🎮", "Who wants to team up?", "Epic match! 🔥", "Anyone up for a challenge?",
    "New high score! 💪", "This game is intense!", "Great teamwork guys", "Ready for round 2?",
    "Nice moves @{player}!", "That was close! 😅", "Level up! 🎊", "Achievement unlocked!",
    "Lag is killing me 😤", "Best game ever!", "Who's leading now?", "Time for revenge 😈",
    "Clutch play right there", "Can't stop playing!", "One more game?", "Victory! 🏆",
    "Insane combo!", "Perfect timing!", "What a save!", "Incredible shot!", "Unbelievable!",
    "That's how it's done!", "Show me your skills!", "Bring it on!", "Let's do this!",
    "Amazing play!", "Spectacular!", "Outstanding!", "Magnificent!", "Phenomenal!"
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
        self.cache_thread = None
        self.ttl_thread = None
        
        self._setup_routes()
        self._setup_websocket_handlers()
        
        # AUTO-DETECT EXISTING DATA ON STARTUP (Migration-friendly)
        self._auto_detect_and_continue()
    
    def _validate_player_name(self, name: str) -> bool:
        """Validate player name for security"""
        if not name or not isinstance(name, str):
            return False
        return bool(re.match(r'^[a-zA-Z0-9_\-\s]{1,30}$', name))
    
    def _validate_message_content(self, content: str) -> bool:
        """Validate message content for security"""
        if not content or not isinstance(content, str):
            return False
        if len(content) > 200:
            return False
        dangerous_patterns = ['<script', 'javascript:', 'onload=', 'onerror=']
        content_lower = content.lower()
        return not any(pattern in content_lower for pattern in dangerous_patterns)
    
    def _sanitize_html(self, text: str) -> str:
        """Basic HTML sanitization"""
        if not isinstance(text, str):
            return ""
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
                
                # Auto-resume simulation if it was previously running (demo counter > 0)
                if existing_counter and int(existing_counter) > 0:
                    logger.info("🚀 Auto-resuming simulation after restart (demo counter was active)")
                    self.start_simulation()
                else:
                    logger.info("📋 Data detected - simulation ready for manual start")
            else:
                logger.info("📭 No existing data found - waiting for manual initialization")
                
        except Exception as e:
            logger.error(f"Error during auto-detection: {e}")
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
            pipe.dbsize()                                                     # 3: total_keys
            results = pipe.execute()
            
            total_players = results[0] or 0
            online_count = results[1] or 0
            top_player = results[2] or []
            total_keys = results[3] or 0
            high_score = int(top_player[0][1]) if top_player else 0
            
            return {
                'total_players': total_players,
                'active_games': online_count,
                'high_score': f'{high_score:,}',
                'total_keys': f'{total_keys:,}',
                'server_status': 'Running' if self.simulation_active else 'Loaded'
            }
        except Exception as e:
            logger.error(f"Error getting profile stats: {e}")
            return {
                'total_players': 0,
                'active_games': 0,
                'high_score': '0',
                'total_keys': '0',
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
                
                logger.info("🎮 Starting enhanced data load process...")
                self._load_initial_data()
                self.data_loaded = True
                logger.info("✅ Enhanced game data loaded successfully!")
                
                return jsonify({'success': True, 'message': 'Enhanced game data loaded successfully!'})
            except Exception as e:
                logger.error(f"Error loading data: {e}")
                return jsonify({'success': False, 'error': str(e)})
        
        @self.app.route('/api/start-simulation', methods=['POST'])
        def api_start_simulation():
            try:
                if not self.data_loaded:
                    return jsonify({'success': False, 'message': 'Load data first'})
                
                # Only reset counter for manual starts (not auto-continue)
                if self.demo_counter_value == 0:
                    logger.info("🔢 Manual start - resetting demo counter")
                
                self.start_simulation()
                return jsonify({'success': True, 'message': 'High-performance gaming simulation started!'})
            except Exception as e:
                logger.error(f"Error starting simulation: {e}")
                return jsonify({'success': False, 'error': str(e)})
        
        @self.app.route('/api/stop-simulation', methods=['POST'])
        def api_stop_simulation():
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
        """Load enhanced initial data with thousands of keys"""
        logger.info("🎮 Loading enhanced gaming data with thousands of keys...")
        
        # Clear existing data
        pipe = self.redis_mgr.connection.pipeline()
        
        # Create expanded leaderboard with 100 players and dynamic score ranges
        logger.info("📊 Creating 100-player leaderboard with dynamic scores...")
        for i, player in enumerate(random.sample(PLAYER_NAMES, 100)):
            # More realistic score distribution (1-10M range)
            if i < 3:  # Top 3 players - very high scores
                score = random.randint(5000000, 10000000)
            elif i < 10:  # Top 10 - high scores
                score = random.randint(1000000, 4999999)
            elif i < 25:  # Top 25 - good scores
                score = random.randint(100000, 999999)
            elif i < 50:  # Top 50 - average scores
                score = random.randint(10000, 99999)
            else:  # Rest - lower scores
                score = random.randint(100, 9999)
            
            pipe.zadd('leaderboard:global', {player: score})
            
            # Add to online players
            pipe.sadd('online:players', player)
            
            # Create detailed user session with TTL
            session_data = {
                'username': player,
                'level': random.randint(1, 100),
                'games_played': random.randint(50, 5000),
                'wins': random.randint(20, 2000),
                'losses': random.randint(10, 1500),
                'last_seen': datetime.now().isoformat(),
                'status': random.choice(['online', 'playing', 'idle']),
                'current_game_id': str(uuid.uuid4()) if random.random() < 0.3 else '',
                'rank': random.randint(1, 1000),
                'xp': random.randint(1000, 100000)
            }
            pipe.hset(f'user:session:{player}', mapping=session_data)
            pipe.expire(f'user:session:{player}', random.randint(1800, 86400))  # 30min-24hr TTL
        
        # Create thousands of cache entries with TTLs
        logger.info("🗄️ Creating cache entries with TTLs...")
        for i in range(2000):
            cache_key = f'cache:item:{random.choice(GAME_ITEMS)}:{i}'
            cache_data = {
                'item_id': str(uuid.uuid4()),
                'name': random.choice(GAME_ITEMS),
                'rarity': random.choice(['common', 'rare', 'epic', 'legendary']),
                'level': random.randint(1, 100),
                'stats': json.dumps({
                    'attack': random.randint(10, 1000),
                    'defense': random.randint(10, 1000),
                    'speed': random.randint(10, 100)
                }),
                'price': random.randint(100, 50000)
            }
            pipe.hset(cache_key, mapping=cache_data)
            pipe.expire(cache_key, random.randint(300, 3600))  # 5min-1hr TTL
        
        # Create game lobby data with TTLs
        logger.info("🎮 Creating game lobbies with TTLs...")
        for i in range(500):
            lobby_id = str(uuid.uuid4())
            lobby_key = f'game:lobby:{lobby_id}'
            lobby_data = {
                'id': lobby_id,
                'name': f'Game Room {i+1}',
                'players': json.dumps(random.sample(PLAYER_NAMES, random.randint(2, 8))),
                'max_players': random.randint(4, 16),
                'game_mode': random.choice(['deathmatch', 'team_battle', 'survival', 'tournament']),
                'map': random.choice(['arena1', 'castle', 'desert', 'forest', 'city']),
                'status': random.choice(['waiting', 'starting', 'active']),
                'created_at': datetime.now().isoformat()
            }
            pipe.hset(lobby_key, mapping=lobby_data)
            pipe.expire(lobby_key, random.randint(600, 1800))  # 10-30min TTL
        
        # Create rate limiting keys
        logger.info("⚡ Creating rate limiting keys...")
        for player in random.sample(PLAYER_NAMES, 50):
            for api_endpoint in ['login', 'game_action', 'chat', 'leaderboard']:
                rate_key = f'ratelimit:{api_endpoint}:{player}'
                pipe.set(rate_key, random.randint(1, 10))
                pipe.expire(rate_key, random.randint(60, 300))  # 1-5min TTL
        
        # Create achievement tracking
        logger.info("🏆 Creating achievement data...")
        for player in random.sample(PLAYER_NAMES, 80):
            for achievement in random.sample(ACHIEVEMENTS, random.randint(3, 12)):
                achievement_key = f'achievement:{player}:{achievement}'
                achievement_data = {
                    'player': player,
                    'achievement': achievement,
                    'unlocked_at': (datetime.now() - timedelta(days=random.randint(1, 365))).isoformat(),
                    'progress': random.randint(80, 100),
                    'reward_claimed': str(random.choice([True, False]))
                }
                pipe.hset(achievement_key, mapping=achievement_data)
                pipe.expire(achievement_key, random.randint(86400, 604800))  # 1-7 days TTL
        
        # Create analytics events
        logger.info("📈 Creating analytics events...")
        for i in range(1000):
            event_timestamp = int(time.time()) - random.randint(0, 86400)  # Last 24hrs
            event_key = f'analytics:event:{event_timestamp}:{i}'
            event_data = {
                'timestamp': event_timestamp,
                'event_type': random.choice(['login', 'logout', 'game_start', 'game_end', 'purchase', 'achievement']),
                'player': random.choice(PLAYER_NAMES),
                'value': random.randint(1, 1000),
                'metadata': json.dumps({
                    'game_mode': random.choice(['solo', 'team', 'tournament']),
                    'duration': random.randint(60, 3600)
                })
            }
            pipe.hset(event_key, mapping=event_data)
            pipe.expire(event_key, random.randint(3600, 259200))  # 1hr-3days TTL
        
        # Create notification queues
        logger.info("🔔 Creating notification queues...")
        for player in random.sample(PLAYER_NAMES, 60):
            for i in range(random.randint(1, 5)):
                notif_key = f'notification:{player}:{uuid.uuid4()}'
                notification = {
                    'type': random.choice(['friend_request', 'game_invite', 'achievement', 'system']),
                    'title': 'New Notification',
                    'message': random.choice(CHAT_TEMPLATES),
                    'from_player': random.choice(PLAYER_NAMES),
                    'created_at': datetime.now().isoformat(),
                    'read': str(random.choice([True, False]))
                }
                pipe.hset(notif_key, mapping=notification)
                pipe.expire(notif_key, random.randint(86400, 604800))  # 1-7 days TTL
        
        # Execute all operations
        logger.info("💾 Executing bulk data creation...")
        pipe.execute()
        
        # Get final key count
        total_keys = self.redis_mgr.connection.dbsize()
        logger.info(f"✅ Enhanced gaming data loaded! Total keys: {total_keys:,}")
    
    def start_simulation(self):
        """Start high-performance gaming simulation targeting 1000+ ops/sec"""
        try:
            logger.info("🚀 Starting HIGH-PERFORMANCE gaming simulation (targeting 1000+ ops/sec)...")
            self.simulation_active = True
            
            # Clear previous threads if any
            self.worker_threads.clear()
            logger.info("🧹 Cleared previous threads")
            
            # Start MORE simulation threads for higher ops
            for i in range(8):  # 8 worker threads for 1000+ ops
                logger.info(f"🔧 Starting GameWorker-{i}")
                thread = threading.Thread(target=self._simulation_worker, daemon=False, name=f"GameWorker-{i}")
                thread.start()
                self.worker_threads.append(thread)
                logger.info(f"✅ GameWorker-{i} started successfully")
            
            # Start specialized high-ops threads
            logger.info("🔧 Starting cache worker")
            self.cache_thread = threading.Thread(target=self._cache_worker, daemon=False)
            self.cache_thread.start()
            logger.info("✅ Cache worker started")
            
            logger.info("🔧 Starting TTL worker")
            self.ttl_thread = threading.Thread(target=self._ttl_worker, daemon=False)
            self.ttl_thread.start()
            logger.info("✅ TTL worker started")
            
            # Start demo counter
            logger.info("🔧 Starting demo counter")
            self.demo_thread = threading.Thread(target=self._demo_counter_worker, daemon=False)
            self.demo_thread.start()
            logger.info("✅ Demo counter started")
            
            # Start performance monitor
            logger.info("🔧 Starting performance monitor")
            self.performance_thread = threading.Thread(target=self._performance_monitor, daemon=False)
            self.performance_thread.start()
            logger.info("✅ Performance monitor started")
            
            logger.info("🔥 HIGH-PERFORMANCE gaming simulation started with 8 worker threads + 4 specialized threads")
            logger.info(f"🔍 simulation_active flag: {self.simulation_active}")
            
        except Exception as e:
            logger.error(f"❌ Error starting simulation: {e}")
            self.simulation_active = False
            raise
    
    def stop_simulation(self):
        """Stop all simulation activity"""
        self.simulation_active = False
        self.demo_counter_value = 0
        logger.info("⏹️ Stopping high-performance gaming simulation...")
        
        # Wait for threads to finish gracefully
        logger.info("🧹 Cleaning up worker threads...")
        for thread in self.worker_threads:
            if thread.is_alive():
                thread.join(timeout=2.0)
        
        if self.demo_thread and self.demo_thread.is_alive():
            self.demo_thread.join(timeout=2.0)
            
        if self.performance_thread and self.performance_thread.is_alive():
            self.performance_thread.join(timeout=2.0)
            
        if self.cache_thread and self.cache_thread.is_alive():
            self.cache_thread.join(timeout=2.0)
            
        if self.ttl_thread and self.ttl_thread.is_alive():
            self.ttl_thread.join(timeout=2.0)
        
        # Clear thread references
        self.worker_threads.clear()
        self.demo_thread = None
        self.performance_thread = None
        self.cache_thread = None
        self.ttl_thread = None
        
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
                # Batch MORE operations for higher throughput
                for _ in range(random.randint(8, 15)):  # 8-15 ops per batch
                    operation = random.choice([
                        'update_leaderboard',
                        'post_message', 
                        'update_session',
                        'player_activity',
                        'create_temp_data',
                        'update_analytics'
                    ])
                    
                    if operation == 'update_leaderboard':
                        self._update_leaderboard()
                    elif operation == 'post_message':
                        self._post_chat_message()
                    elif operation == 'update_session':
                        self._update_player_session()
                    elif operation == 'player_activity':
                        self._simulate_player_activity()
                    elif operation == 'create_temp_data':
                        self._create_temporary_data()
                    elif operation == 'update_analytics':
                        self._update_analytics()
                    
                    self.total_operations += 1
                
                # Smaller delay for higher ops/sec
                time.sleep(random.uniform(0.001, 0.010))  # 1-10ms
                
            except Exception as e:
                logger.error(f"Simulation error: {e}")
                time.sleep(0.1)
    
    def _cache_worker(self):
        """Dedicated high-speed cache operations worker"""
        while self.simulation_active:
            try:
                # High-speed cache operations
                for _ in range(random.randint(10, 20)):  # 10-20 cache ops
                    cache_op = random.choice(['set_cache', 'get_cache', 'delete_cache', 'update_cache'])
                    
                    if cache_op == 'set_cache':
                        cache_key = f'cache:rapid:{uuid.uuid4()}'
                        self.redis_mgr.connection.setex(cache_key, random.randint(60, 300), 
                                                      json.dumps({'data': random.randint(1, 1000)}))
                    elif cache_op == 'get_cache':
                        # Try to get random cache key
                        try:
                            self.redis_mgr.connection.get(f'cache:rapid:{uuid.uuid4()}')
                        except:
                            pass
                    elif cache_op == 'update_cache':
                        # Update cache with new TTL
                        cache_key = f'cache:update:{random.randint(1, 1000)}'
                        self.redis_mgr.connection.setex(cache_key, random.randint(30, 600),
                                                      json.dumps({'updated': time.time()}))
                    
                    self.total_operations += 1
                
                time.sleep(random.uniform(0.001, 0.005))  # Very fast cache ops
                
            except Exception as e:
                logger.error(f"Cache worker error: {e}")
                time.sleep(0.1)
    
    def _ttl_worker(self):
        """Dedicated TTL and key lifecycle management worker"""
        while self.simulation_active:
            try:
                # Create expiring keys rapidly
                for _ in range(random.randint(5, 10)):
                    key_type = random.choice(['session', 'temp', 'rate', 'event'])
                    
                    if key_type == 'session':
                        key = f'temp:session:{uuid.uuid4()}'
                        self.redis_mgr.connection.setex(key, random.randint(30, 300), 
                                                      json.dumps({'session_data': time.time()}))
                    elif key_type == 'temp':
                        key = f'temp:data:{uuid.uuid4()}'
                        self.redis_mgr.connection.setex(key, random.randint(10, 60),
                                                      f'temp_value_{random.randint(1, 1000)}')
                    elif key_type == 'rate':
                        key = f'rate:{random.choice(PLAYER_NAMES)}:{random.randint(1, 100)}'
                        self.redis_mgr.connection.setex(key, random.randint(5, 30), '1')
                    elif key_type == 'event':
                        key = f'event:temp:{int(time.time())}:{random.randint(1, 1000)}'
                        self.redis_mgr.connection.setex(key, random.randint(60, 180),
                                                      json.dumps({'event': 'temp_event'}))
                    
                    self.total_operations += 1
                
                time.sleep(random.uniform(0.002, 0.008))  # Fast TTL operations
                
            except Exception as e:
                logger.error(f"TTL worker error: {e}")
                time.sleep(0.1)
    
    def _update_leaderboard(self):
        """Update leaderboard with MUCH more dynamic score changes"""
        player = random.choice(PLAYER_NAMES)
        
        # Get current score to make changes more dynamic
        current_score = self.redis_mgr.connection.zscore('leaderboard:global', player) or 0
        
        # More dramatic and varied score changes
        change_type = random.choice(['mega_win', 'big_win', 'win', 'loss', 'big_loss', 'mega_loss', 'reset_streak'])
        
        if change_type == 'mega_win':  # Rare massive gains
            score_change = random.randint(50000, 500000)
        elif change_type == 'big_win':
            score_change = random.randint(10000, 49999)
        elif change_type == 'win':
            score_change = random.randint(500, 9999)
        elif change_type == 'loss':
            score_change = random.randint(-5000, -100)
        elif change_type == 'big_loss':
            score_change = random.randint(-25000, -5001)
        elif change_type == 'mega_loss':  # Rare massive losses
            score_change = random.randint(-200000, -25001)
        else:  # reset_streak - random dramatic change
            score_change = random.randint(-100000, 200000)
        
        # Apply score change
        new_score = self.redis_mgr.connection.zincrby('leaderboard:global', score_change, player)
        
        # Keep scores in reasonable bounds (but much higher than before)
        if new_score < 100:
            self.redis_mgr.connection.zadd('leaderboard:global', {player: 100})
        elif new_score > 50000000:  # 50M max instead of 100k
            self.redis_mgr.connection.zadd('leaderboard:global', {player: 50000000})
    
    def _create_temporary_data(self):
        """Create various temporary data with TTLs"""
        temp_type = random.choice(['lobby', 'match', 'notification', 'cache'])
        
        if temp_type == 'lobby':
            lobby_id = str(uuid.uuid4())
            key = f'temp:lobby:{lobby_id}'
            data = {
                'players': json.dumps(random.sample(PLAYER_NAMES, random.randint(2, 6))),
                'status': 'waiting',
                'created': time.time()
            }
            self.redis_mgr.connection.hset(key, mapping=data)
            self.redis_mgr.connection.expire(key, random.randint(300, 900))  # 5-15min
            
        elif temp_type == 'match':
            match_id = str(uuid.uuid4())
            key = f'temp:match:{match_id}'
            self.redis_mgr.connection.setex(key, random.randint(600, 1800),  # 10-30min
                                          json.dumps({
                                              'players': random.sample(PLAYER_NAMES, random.randint(4, 8)),
                                              'score': {p: random.randint(0, 1000) for p in random.sample(PLAYER_NAMES, 4)},
                                              'status': 'active'
                                          }))
    
    def _update_analytics(self):
        """Update analytics data"""
        event_key = f'analytics:realtime:{int(time.time())}:{random.randint(1, 1000)}'
        event_data = {
            'player': random.choice(PLAYER_NAMES),
            'action': random.choice(['click', 'view', 'purchase', 'achievement', 'level_up']),
            'value': random.randint(1, 500),
            'timestamp': time.time()
        }
        self.redis_mgr.connection.setex(event_key, random.randint(1800, 7200),  # 30min-2hr
                                      json.dumps(event_data))
    
    def _post_chat_message(self):
        """Post realistic chat message"""
        player = random.choice(PLAYER_NAMES)
        template = random.choice(CHAT_TEMPLATES)
        
        if not self._validate_player_name(player):
            return
        
        if '{player}' in template:
            target_player = random.choice([p for p in PLAYER_NAMES if p != player])
            message_text = template.replace('{player}', target_player)
        else:
            message_text = template
        
        if not self._validate_message_content(message_text):
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
            'games_played': random.randint(1, 3)
        }
        
        if random.random() < 0.3:
            updates['wins'] = random.randint(0, 2)
        
        self.redis_mgr.connection.hincrby(f'user:session:{player}', 'games_played', updates['games_played'])
        self.redis_mgr.connection.hset(f'user:session:{player}', 'last_seen', updates['last_seen'])
        # Refresh TTL
        self.redis_mgr.connection.expire(f'user:session:{player}', random.randint(1800, 86400))
    
    def _simulate_player_activity(self):
        """Simulate various player activities"""
        activity = random.choice(['join', 'leave', 'achievement', 'status_update', 'purchase'])
        player = random.choice(PLAYER_NAMES)
        
        if activity == 'join':
            self.redis_mgr.connection.sadd('online:players', player)
        elif activity == 'leave':
            self.redis_mgr.connection.srem('online:players', player)
        elif activity == 'achievement':
            if not self._validate_player_name(player):
                return
                
            achievement = random.choice(ACHIEVEMENTS)
            message = {
                'player': self._sanitize_html(player),
                'message': self._sanitize_html(f'{player} unlocked {achievement}! 🏆'),
                'timestamp': datetime.now().isoformat(),
                'type': 'achievement'
            }
            pipe = self.redis_mgr.connection.pipeline()
            pipe.lpush('messages:global', json.dumps(message))
            pipe.ltrim('messages:global', 0, 49)
            pipe.execute()
        elif activity == 'status_update':
            status = random.choice(['playing', 'idle', 'in-menu', 'in-game'])
            self.redis_mgr.connection.hset(f'user:session:{player}', 'status', status)
        elif activity == 'purchase':
            # Simulate item purchase
            item = random.choice(GAME_ITEMS)
            purchase_key = f'purchase:{player}:{uuid.uuid4()}'
            purchase_data = {
                'player': player,
                'item': item,
                'price': random.randint(100, 10000),
                'timestamp': time.time()
            }
            self.redis_mgr.connection.setex(purchase_key, 86400, json.dumps(purchase_data))  # 24hr TTL
    
    def _performance_monitor(self):
        """Monitor operations per second"""
        while self.simulation_active:
            time.sleep(5)  # Update every 5 seconds
            
            current_time = time.time()
            time_diff = current_time - self.last_ops_time
            
            if time_diff > 0:
                self.ops_per_second = int((self.total_operations) / time_diff)
                total_keys = self.redis_mgr.connection.dbsize()
                logger.info(f"⚡ Performance: {self.ops_per_second} ops/sec | Total keys: {total_keys:,}")
                
                # Reset counters
                self.total_operations = 0
                self.last_ops_time = current_time
    
    def run(self, host='0.0.0.0', port=5000, debug=False):
        """Run the RedisArena application"""
        logger.info(f"🚀 Starting Enhanced RedisArena Gaming Platform on {host}:{port}")
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
        logger.error(f"Failed to start Enhanced RedisArena: {e}")
        raise