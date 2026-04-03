#!/bin/bash
set -e

echo "=== Finder Server Setup (continued) ==="

# Install PostgreSQL
apt install -y postgresql postgresql-contrib

# Install Nginx
apt install -y nginx

# Install additional tools (skip ufw, already configured)
apt install -y certbot python3-certbot-nginx build-essential

# Setup PostgreSQL
sudo -u postgres psql -c "CREATE USER finder WITH PASSWORD 'FinderDB_2024_Secure';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE finder_db OWNER finder;" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE finder_db TO finder;" 2>/dev/null || true

# Create app directory
mkdir -p /opt/finder
cd /opt/finder

# Initialize Node.js project
npm init -y

# Install dependencies
npm install express ws pg bcryptjs jsonwebtoken multer uuid cors helmet
npm install -g pm2

# Create database schema
sudo -u postgres psql -d finder_db << 'DBEOF'
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    finder_id VARCHAR(20) UNIQUE NOT NULL,
    avatar_icon VARCHAR(50) DEFAULT 'person.fill',
    avatar_color VARCHAR(20) DEFAULT 'blue',
    status_text VARCHAR(200) DEFAULT '',
    is_online BOOLEAN DEFAULT false,
    last_seen TIMESTAMP DEFAULT NOW(),
    is_verified BOOLEAN DEFAULT false,
    is_banned BOOLEAN DEFAULT false,
    is_deleted BOOLEAN DEFAULT false,
    is_admin BOOLEAN DEFAULT false,
    pin_hash VARCHAR(255),
    decoy_pin_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    is_group BOOLEAN DEFAULT false,
    is_channel BOOLEAN DEFAULT false,
    is_support BOOLEAN DEFAULT false,
    group_name VARCHAR(100),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chat_members (
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP DEFAULT NOW(),
    is_admin BOOLEAN DEFAULT false,
    is_muted BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    unread_count INT DEFAULT 0,
    PRIMARY KEY (chat_id, user_id)
);

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id),
    text TEXT,
    message_type VARCHAR(20) DEFAULT 'text',
    reply_to_id UUID REFERENCES messages(id),
    is_edited BOOLEAN DEFAULT false,
    is_read BOOLEAN DEFAULT false,
    is_delivered BOOLEAN DEFAULT true,
    is_phantom BOOLEAN DEFAULT false,
    self_destruct_time INT,
    is_forwardable BOOLEAN DEFAULT true,
    encrypted_payload TEXT,
    file_url VARCHAR(500),
    file_name VARCHAR(255),
    file_size BIGINT,
    duration INT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caller_id UUID REFERENCES users(id),
    callee_id UUID REFERENCES users(id),
    chat_id UUID REFERENCES chats(id),
    is_video BOOLEAN DEFAULT false,
    status VARCHAR(20) DEFAULT 'ringing',
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    duration INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    uploader_id UUID REFERENCES users(id),
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_chat_members_user_id ON chat_members(user_id);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
DBEOF

echo "Database schema created!"

# Create uploads directory
mkdir -p /opt/finder/uploads/files
mkdir -p /opt/finder/uploads/voice
mkdir -p /opt/finder/uploads/media

# Create the server
cat > /opt/finder/server.js << 'SERVEREOF'
const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const fs = require('fs');

// Config
const JWT_SECRET = 'finder_jwt_secret_2024_stable';
const PORT = 3000;
const WS_PORT = 3001;

// Database
const pool = new Pool({
    user: 'finder',
    host: 'localhost',
    database: 'finder_db',
    password: 'FinderDB_2024_Secure',
    port: 5432,
});

// Express app
const app = express();
app.use(cors());
app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(express.json({ limit: '50mb' }));
app.use('/uploads', express.static('/opt/finder/uploads'));

// File upload config
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        let dir = '/opt/finder/uploads/files';
        if (file.mimetype.startsWith('audio/')) dir = '/opt/finder/uploads/voice';
        if (file.mimetype.startsWith('video/') || file.mimetype.startsWith('image/')) dir = '/opt/finder/uploads/media';
        cb(null, dir);
    },
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname);
        cb(null, uuidv4() + ext);
    }
});
const upload = multer({ storage, limits: { fileSize: 100 * 1024 * 1024 } });

// Auth middleware
function auth(req, res, next) {
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (!token) return res.status(401).json({ error: 'No token' });
    try {
        req.user = jwt.verify(token, JWT_SECRET);
        next();
    } catch {
        res.status(401).json({ error: 'Invalid token' });
    }
}

// ============ AUTH ROUTES ============

app.post('/api/register', async (req, res) => {
    try {
        const { username, display_name, password } = req.body;
        if (!username || !password) return res.status(400).json({ error: 'Missing fields' });

        const existing = await pool.query('SELECT id FROM users WHERE username = $1', [username.toLowerCase()]);
        if (existing.rows.length > 0) return res.status(409).json({ error: 'Username taken' });

        const hash = await bcrypt.hash(password, 12);
        const finderId = 'FID-' + uuidv4().substring(0, 8).toUpperCase();
        const isAdmin = username.toLowerCase() === 'awfulc';

        const result = await pool.query(
            `INSERT INTO users (username, display_name, password_hash, finder_id, is_admin)
             VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [username.toLowerCase(), display_name || username, hash, finderId, isAdmin]
        );

        const user = result.rows[0];
        const token = jwt.sign({ id: user.id, username: user.username, is_admin: user.is_admin }, JWT_SECRET, { expiresIn: '30d' });

        res.json({ user: sanitizeUser(user), token });
    } catch (err) {
        console.error('Register error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

app.post('/api/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        const result = await pool.query('SELECT * FROM users WHERE username = $1', [username.toLowerCase()]);
        if (result.rows.length === 0) return res.status(401).json({ error: 'User not found' });

        const user = result.rows[0];
        if (user.is_banned) return res.status(403).json({ error: 'Account banned' });
        if (user.is_deleted) return res.status(403).json({ error: 'Account deleted' });

        const valid = await bcrypt.compare(password, user.password_hash);
        if (!valid) return res.status(401).json({ error: 'Wrong password' });

        const token = jwt.sign({ id: user.id, username: user.username, is_admin: user.is_admin }, JWT_SECRET, { expiresIn: '30d' });

        await pool.query('UPDATE users SET is_online = true, last_seen = NOW() WHERE id = $1', [user.id]);

        res.json({ user: sanitizeUser(user), token });
    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// ============ USER ROUTES ============

app.get('/api/users/search', auth, async (req, res) => {
    const { q } = req.query;
    if (!q) return res.json([]);
    const result = await pool.query(
        `SELECT * FROM users WHERE (username ILIKE $1 OR display_name ILIKE $1) AND is_deleted = false LIMIT 20`,
        [`%${q}%`]
    );
    res.json(result.rows.map(sanitizeUser));
});

app.get('/api/users/:id', auth, async (req, res) => {
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
    res.json(sanitizeUser(result.rows[0]));
});

app.put('/api/users/me', auth, async (req, res) => {
    const { display_name, status_text, avatar_icon, avatar_color } = req.body;
    const result = await pool.query(
        `UPDATE users SET display_name = COALESCE($1, display_name), status_text = COALESCE($2, status_text),
         avatar_icon = COALESCE($3, avatar_icon), avatar_color = COALESCE($4, avatar_color), updated_at = NOW()
         WHERE id = $5 RETURNING *`,
        [display_name, status_text, avatar_icon, avatar_color, req.user.id]
    );
    res.json(sanitizeUser(result.rows[0]));
});

// ============ CHAT ROUTES ============

app.get('/api/chats', auth, async (req, res) => {
    const result = await pool.query(
        `SELECT c.*, cm.is_pinned, cm.is_muted, cm.unread_count,
         (SELECT json_agg(json_build_object(
             'id', u.id, 'username', u.username, 'display_name', u.display_name,
             'avatar_icon', u.avatar_icon, 'avatar_color', u.avatar_color,
             'is_online', u.is_online, 'is_verified', u.is_verified,
             'is_banned', u.is_banned, 'is_deleted', u.is_deleted,
             'status_text', u.status_text, 'finder_id', u.finder_id
         )) FROM chat_members cm2 JOIN users u ON u.id = cm2.user_id
         WHERE cm2.chat_id = c.id AND cm2.user_id != $1) as participants,
         (SELECT json_build_object('id', m.id, 'text', m.text, 'sender_id', m.sender_id,
          'message_type', m.message_type, 'created_at', m.created_at)
          FROM messages m WHERE m.chat_id = c.id ORDER BY m.created_at DESC LIMIT 1) as last_message
         FROM chats c
         JOIN chat_members cm ON cm.chat_id = c.id AND cm.user_id = $1
         ORDER BY (SELECT MAX(created_at) FROM messages WHERE chat_id = c.id) DESC NULLS LAST`,
        [req.user.id]
    );
    res.json(result.rows);
});

app.post('/api/chats', auth, async (req, res) => {
    const { participant_id, is_group, group_name, participant_ids } = req.body;

    if (!is_group && participant_id) {
        const existing = await pool.query(
            `SELECT c.id FROM chats c
             JOIN chat_members cm1 ON cm1.chat_id = c.id AND cm1.user_id = $1
             JOIN chat_members cm2 ON cm2.chat_id = c.id AND cm2.user_id = $2
             WHERE c.is_group = false AND c.is_channel = false`,
            [req.user.id, participant_id]
        );
        if (existing.rows.length > 0) return res.json({ id: existing.rows[0].id, existing: true });
    }

    const chatId = uuidv4();
    await pool.query(
        `INSERT INTO chats (id, is_group, group_name, created_by) VALUES ($1, $2, $3, $4)`,
        [chatId, is_group || false, group_name, req.user.id]
    );

    await pool.query('INSERT INTO chat_members (chat_id, user_id, is_admin) VALUES ($1, $2, true)', [chatId, req.user.id]);

    const ids = is_group ? (participant_ids || []) : (participant_id ? [participant_id] : []);
    for (const pid of ids) {
        await pool.query('INSERT INTO chat_members (chat_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING', [chatId, pid]);
    }

    if (is_group) {
        await pool.query(
            `INSERT INTO messages (chat_id, sender_id, text, message_type) VALUES ($1, $2, $3, 'system')`,
            [chatId, req.user.id, `Группа "${group_name}" создана`]
        );
    }

    res.json({ id: chatId });
});

// ============ MESSAGE ROUTES ============

app.get('/api/chats/:chatId/messages', auth, async (req, res) => {
    const { chatId } = req.params;
    const { before, limit = 50 } = req.query;

    let query = `SELECT * FROM messages WHERE chat_id = $1`;
    const params = [chatId];

    if (before) {
        query += ` AND created_at < $2 ORDER BY created_at DESC LIMIT $3`;
        params.push(before, parseInt(limit));
    } else {
        query += ` ORDER BY created_at DESC LIMIT $2`;
        params.push(parseInt(limit));
    }

    const result = await pool.query(query, params);
    res.json(result.rows.reverse());
});

app.post('/api/chats/:chatId/messages', auth, async (req, res) => {
    const { chatId } = req.params;
    const { text, message_type = 'text', reply_to_id, encrypted_payload } = req.body;

    const result = await pool.query(
        `INSERT INTO messages (chat_id, sender_id, text, message_type, reply_to_id, encrypted_payload)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
        [chatId, req.user.id, text, message_type, reply_to_id, encrypted_payload]
    );

    const message = result.rows[0];

    await pool.query(
        `UPDATE chat_members SET unread_count = unread_count + 1 WHERE chat_id = $1 AND user_id != $2`,
        [chatId, req.user.id]
    );

    broadcastToChat(chatId, { type: 'new_message', message, chat_id: chatId });

    res.json(message);
});

// ============ FILE UPLOAD ============

app.post('/api/upload', auth, upload.single('file'), async (req, res) => {
    if (!req.file) return res.status(400).json({ error: 'No file' });

    const fileUrl = `/uploads/${path.basename(path.dirname(req.file.path))}/${req.file.filename}`;

    await pool.query(
        `INSERT INTO files (uploader_id, file_name, file_path, file_size, mime_type)
         VALUES ($1, $2, $3, $4, $5)`,
        [req.user.id, req.file.originalname, fileUrl, req.file.size, req.file.mimetype]
    );

    res.json({
        url: fileUrl,
        name: req.file.originalname,
        size: req.file.size,
        mime: req.file.mimetype
    });
});

// ============ CALL ROUTES ============

app.post('/api/calls', auth, async (req, res) => {
    const { callee_id, chat_id, is_video } = req.body;

    const result = await pool.query(
        `INSERT INTO calls (caller_id, callee_id, chat_id, is_video, status)
         VALUES ($1, $2, $3, $4, 'ringing') RETURNING *`,
        [req.user.id, callee_id, chat_id, is_video || false]
    );

    sendToUser(callee_id, {
        type: 'incoming_call',
        call: result.rows[0],
        caller: req.user
    });

    res.json(result.rows[0]);
});

app.put('/api/calls/:callId', auth, async (req, res) => {
    const { status } = req.body;
    const { callId } = req.params;

    let updates = 'status = $1';
    const params = [status, callId];

    if (status === 'accepted') {
        updates += ', started_at = NOW()';
    } else if (status === 'ended') {
        updates += ', ended_at = NOW(), duration = EXTRACT(EPOCH FROM (NOW() - started_at))::int';
    }

    const result = await pool.query(`UPDATE calls SET ${updates} WHERE id = $2 RETURNING *`, params);
    const call = result.rows[0];

    const otherId = call.caller_id === req.user.id ? call.callee_id : call.caller_id;
    sendToUser(otherId, { type: 'call_update', call });

    res.json(call);
});

// ============ ADMIN ROUTES ============

app.post('/api/admin/verify', auth, async (req, res) => {
    if (!req.user.is_admin) return res.status(403).json({ error: 'Not admin' });
    const { username } = req.body;
    await pool.query('UPDATE users SET is_verified = true WHERE username = $1', [username.toLowerCase()]);
    res.json({ ok: true });
});

app.post('/api/admin/ban', auth, async (req, res) => {
    if (!req.user.is_admin) return res.status(403).json({ error: 'Not admin' });
    const { username } = req.body;
    await pool.query('UPDATE users SET is_banned = true WHERE username = $1', [username.toLowerCase()]);

    const result = await pool.query('SELECT id FROM users WHERE username = $1', [username.toLowerCase()]);
    if (result.rows[0]) {
        sendToUser(result.rows[0].id, { type: 'banned' });
    }

    res.json({ ok: true });
});

app.post('/api/admin/unban', auth, async (req, res) => {
    if (!req.user.is_admin) return res.status(403).json({ error: 'Not admin' });
    const { username } = req.body;
    await pool.query('UPDATE users SET is_banned = false WHERE username = $1', [username.toLowerCase()]);
    res.json({ ok: true });
});

app.post('/api/admin/delete-account', auth, async (req, res) => {
    if (!req.user.is_admin) return res.status(403).json({ error: 'Not admin' });
    const { username } = req.body;
    await pool.query('UPDATE users SET is_deleted = true WHERE username = $1', [username.toLowerCase()]);
    res.json({ ok: true });
});

// ============ HEALTH ============

app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', version: '1.0.0', name: 'Finder Server' });
});

// ============ WEBSOCKET ============

const server = http.createServer(app);
const wss = new WebSocket.Server({ port: WS_PORT });

const clients = new Map();

wss.on('connection', (ws, req) => {
    let userId = null;

    ws.on('message', (data) => {
        try {
            const msg = JSON.parse(data);

            if (msg.type === 'auth') {
                try {
                    const decoded = jwt.verify(msg.token, JWT_SECRET);
                    userId = decoded.id;
                    if (!clients.has(userId)) clients.set(userId, new Set());
                    clients.get(userId).add(ws);

                    pool.query('UPDATE users SET is_online = true, last_seen = NOW() WHERE id = $1', [userId]);

                    ws.send(JSON.stringify({ type: 'auth_ok', user_id: userId }));
                    console.log(`User ${decoded.username} connected`);
                } catch {
                    ws.send(JSON.stringify({ type: 'auth_error' }));
                }
                return;
            }

            if (!userId) return;

            switch (msg.type) {
                case 'typing':
                    broadcastToChat(msg.chat_id, { type: 'typing', user_id: userId, chat_id: msg.chat_id }, userId);
                    break;

                case 'read':
                    pool.query('UPDATE messages SET is_read = true WHERE chat_id = $1 AND sender_id != $2', [msg.chat_id, userId]);
                    pool.query('UPDATE chat_members SET unread_count = 0 WHERE chat_id = $1 AND user_id = $2', [msg.chat_id, userId]);
                    broadcastToChat(msg.chat_id, { type: 'read', chat_id: msg.chat_id, user_id: userId }, userId);
                    break;

                case 'webrtc_signal':
                    sendToUser(msg.target_id, {
                        type: 'webrtc_signal',
                        signal: msg.signal,
                        from_id: userId,
                        call_id: msg.call_id
                    });
                    break;
            }
        } catch (err) {
            console.error('WS message error:', err);
        }
    });

    ws.on('close', () => {
        if (userId) {
            const userSockets = clients.get(userId);
            if (userSockets) {
                userSockets.delete(ws);
                if (userSockets.size === 0) {
                    clients.delete(userId);
                    pool.query('UPDATE users SET is_online = false, last_seen = NOW() WHERE id = $1', [userId]);
                }
            }
        }
    });
});

function broadcastToChat(chatId, data, excludeUserId = null) {
    pool.query('SELECT user_id FROM chat_members WHERE chat_id = $1', [chatId])
        .then(result => {
            for (const row of result.rows) {
                if (row.user_id !== excludeUserId) {
                    sendToUser(row.user_id, data);
                }
            }
        });
}

function sendToUser(userId, data) {
    const sockets = clients.get(userId);
    if (sockets) {
        const msg = JSON.stringify(data);
        for (const ws of sockets) {
            if (ws.readyState === WebSocket.OPEN) {
                ws.send(msg);
            }
        }
    }
}

function sanitizeUser(user) {
    const { password_hash, pin_hash, decoy_pin_hash, ...safe } = user;
    return safe;
}

// Start
server.listen(PORT, '0.0.0.0', () => {
    console.log(`Finder API server running on port ${PORT}`);
    console.log(`WebSocket server running on port ${WS_PORT}`);
});
SERVEREOF

# Setup Nginx reverse proxy
cat > /etc/nginx/sites-available/finder << 'NGINXEOF'
server {
    listen 80;
    server_name _;

    client_max_body_size 100M;

    location /api/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }

    location /uploads/ {
        proxy_pass http://127.0.0.1:3000;
    }

    location /ws {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400;
    }

    location / {
        return 200 '{"status":"Finder Server Running"}';
        add_header Content-Type application/json;
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/finder /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Start server with PM2
cd /opt/finder
pm2 start server.js --name finder-api
pm2 startup
pm2 save

echo ""
echo "=== SETUP COMPLETE ==="
echo "API: http://155.212.165.134:3000/api/health"
echo "WebSocket: ws://155.212.165.134:3001"
echo "Nginx proxy: http://155.212.165.134/api/health"
echo ""
echo "PM2 commands:"
echo "  pm2 logs finder-api    - view logs"
echo "  pm2 restart finder-api - restart server"
echo "  pm2 status             - check status"
