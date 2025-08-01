let socket = io();
let isSimulationRunning = false;
let dataLoaded = false;

socket.on('connect', function() {
    console.log('Connected to RedisArena');
    updateButtonStates(); // Initialize button states
    updateStats();
});

setInterval(updateStats, 2000);

function updateStats() {
    fetch('/api/stats')
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                updateLeaderboard(data.leaderboard);
                updateChat(data.recent_messages);
                document.getElementById('online-count').textContent = data.online_count;
                document.getElementById('ops-per-second').textContent = data.ops_per_second;
                document.getElementById('demo-counter').textContent = data.demo_counter;
                
                // Update profile stats
                if (data.profile_stats) {
                    document.getElementById('total-players').textContent = data.profile_stats.total_players;
                    document.getElementById('active-games').textContent = data.profile_stats.active_games;
                    document.getElementById('high-score').textContent = data.profile_stats.high_score;
                    document.getElementById('server-uptime').textContent = data.profile_stats.server_status;
                }
                
                // Sync button states with server state
                if (data.simulation_running !== undefined && data.data_loaded !== undefined) {
                    if (isSimulationRunning !== data.simulation_running || dataLoaded !== data.data_loaded) {
                        isSimulationRunning = data.simulation_running;
                        dataLoaded = data.data_loaded;
                        updateButtonStates();
                    }
                }
            }
        })
        .catch(error => console.log('Stats update error:', error));
}

function updateButtonStates() {
    const startBtn = document.getElementById('start-btn');
    const stopBtn = document.getElementById('stop-btn');
    const loadBtn = document.getElementById('load-btn');
    
    if (isSimulationRunning) {
        // Simulation is running
        startBtn.disabled = true;
        startBtn.textContent = '✅ Running';
        stopBtn.disabled = false;
        stopBtn.textContent = '⏹️ Stop Simulation';
        if (loadBtn) loadBtn.disabled = true;
    } else {
        // Simulation is stopped
        stopBtn.disabled = true;
        stopBtn.textContent = '⏹️ Stop Simulation';
        
        if (dataLoaded) {
            // Data is loaded, can start simulation
            startBtn.disabled = false;
            startBtn.textContent = '▶️ Start Simulation';
        } else {
            // No data loaded, can't start simulation
            startBtn.disabled = true;
            startBtn.textContent = '📊 Load Data First';
        }
        
        if (loadBtn) loadBtn.disabled = false;
    }
}

let lastLeaderboardData = null;

function updateLeaderboard(leaderboard) {
    const container = document.getElementById('leaderboard');
    
    // Skip update if data hasn't changed
    const currentData = JSON.stringify(leaderboard);
    if (lastLeaderboardData === currentData) {
        return;
    }
    lastLeaderboardData = currentData;
    
    if (leaderboard.length === 0) {
        container.innerHTML = '<div style="text-align: center; padding: 50px; opacity: 0.6;">No leaderboard data</div>';
        return;
    }
    
    // Use document fragment for efficient DOM updates
    const fragment = document.createDocumentFragment();
    leaderboard.forEach((player, index) => {
        const item = document.createElement('div');
        item.className = 'leaderboard-item';
        item.innerHTML = `
            <div class="rank">#${index + 1}</div>
            <div class="player-name">${player.player}</div>
            <div class="score">${player.score.toLocaleString()}</div>
        `;
        fragment.appendChild(item);
    });
    
    container.innerHTML = '';
    container.appendChild(fragment);
}

let lastChatData = null;

function updateChat(messages) {
    const container = document.getElementById('chat-messages');
    
    // Skip update if data hasn't changed
    const currentData = JSON.stringify(messages);
    if (lastChatData === currentData) {
        return;
    }
    lastChatData = currentData;
    
    if (messages.length === 0) {
        container.innerHTML = '<div style="text-align: center; padding: 50px; opacity: 0.6;">No messages yet</div>';
        return;
    }
    
    // Use document fragment for efficient DOM updates
    const fragment = document.createDocumentFragment();
    messages.forEach(msg => {
        const time = new Date(msg.timestamp).toLocaleTimeString();
        const messageClass = msg.type === 'achievement' ? 'message achievement' : 'message';
        
        const messageDiv = document.createElement('div');
        messageDiv.className = messageClass;
        messageDiv.innerHTML = `
            <div class="message-header">
                <span class="message-player">${msg.player}</span>
                <span class="message-time">${time}</span>
            </div>
            <div class="message-text">${msg.message}</div>
        `;
        fragment.appendChild(messageDiv);
    });
    
    container.innerHTML = '';
    container.appendChild(fragment);
    container.scrollTop = container.scrollHeight;
}

function loadData() {
    console.log('Loading data...');
    document.getElementById('load-btn').disabled = true;
    document.getElementById('load-btn').textContent = '⏳ Loading...';
    
    fetch('/api/load-data', { 
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
    })
        .then(response => {
            console.log('Load response status:', response.status);
            return response.json();
        })
        .then(data => {
            console.log('Load response data:', data);
            if (data.success) {
                dataLoaded = true;
                document.getElementById('start-btn').disabled = false;
                document.getElementById('load-btn').textContent = '✅ Data Loaded';
                
                // Immediately update stats to show leaderboard
                setTimeout(updateStats, 500);
                
                setTimeout(() => {
                    document.getElementById('load-btn').textContent = '📊 Load Game Data';
                    document.getElementById('load-btn').disabled = false;
                }, 2000);
            } else {
                console.error('Load failed:', data);
                alert('Error loading data: ' + (data.error || data.message));
                document.getElementById('load-btn').disabled = false;
                document.getElementById('load-btn').textContent = '📊 Load Game Data';
            }
        })
        .catch(error => {
            console.error('Load error:', error);
            alert('Network error loading data');
            document.getElementById('load-btn').disabled = false;
            document.getElementById('load-btn').textContent = '📊 Load Game Data';
        });
}

function startSimulation() {
    document.getElementById('start-btn').disabled = true;
    document.getElementById('start-btn').textContent = '⏳ Starting...';
    
    fetch('/api/start-simulation', { method: 'POST' })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                isSimulationRunning = true;
                updateButtonStates();
            } else {
                alert('Error starting simulation: ' + (data.error || data.message));
                updateButtonStates();
            }
        })
        .catch(error => {
            console.error('Start error:', error);
            updateButtonStates();
        });
}

function stopSimulation() {
    document.getElementById('stop-btn').disabled = true;
    document.getElementById('stop-btn').textContent = '⏳ Stopping...';
    
    fetch('/api/stop-simulation', { method: 'POST' })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                isSimulationRunning = false;
                updateButtonStates();
                
                document.getElementById('online-count').textContent = '0';
                document.getElementById('ops-per-second').textContent = '0';
                document.getElementById('demo-counter').textContent = '0';
            } else {
                alert('Error stopping simulation: ' + (data.error || data.message));
                updateButtonStates();
            }
        })
        .catch(error => {
            console.error('Stop error:', error);
            updateButtonStates();
        });
}