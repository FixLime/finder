#!/bin/bash
# Update WebSocket server with WebRTC signaling support

cat > /opt/finder/ws-server.js << 'WSEOF'
const WebSocket = require('ws');
const jwt = require('jsonwebtoken');

const JWT_SECRET = 'finder_jwt_secret_2024_stable';
const PORT = 3001;

const wss = new WebSocket.Server({ port: PORT });
const clients = new Map(); // userId -> ws
const activeCalls = new Map(); // callId -> { callerId, receiverId, isVideo }

console.log(`[WS] WebSocket server running on port ${PORT}`);

wss.on('connection', (ws) => {
    let userId = null;

    ws.on('message', (data) => {
        try {
            const msg = JSON.parse(data.toString());

            // Auth
            if (msg.type === 'auth') {
                try {
                    const decoded = jwt.verify(msg.token, JWT_SECRET);
                    userId = decoded.userId || decoded.id;
                    clients.set(userId, ws);
                    console.log(`[WS] User authenticated: ${userId}`);
                    ws.send(JSON.stringify({ type: 'auth-ok' }));

                    // Notify others this user is online
                    broadcast({ type: 'user-online', user_id: userId }, userId);
                } catch (e) {
                    ws.send(JSON.stringify({ type: 'auth-error', message: 'Invalid token' }));
                }
                return;
            }

            if (!userId) {
                ws.send(JSON.stringify({ type: 'error', message: 'Not authenticated' }));
                return;
            }

            switch (msg.type) {
                case 'message':
                    handleMessage(userId, msg);
                    break;
                case 'typing':
                    handleTyping(userId, msg);
                    break;
                case 'read':
                    handleRead(userId, msg);
                    break;

                // WebRTC Signaling
                case 'webrtc-offer':
                    forwardToUser(msg.to, {
                        type: 'webrtc-offer',
                        call_id: msg.call_id,
                        sdp: msg.sdp,
                        from: userId
                    });
                    break;

                case 'webrtc-answer':
                    forwardToUser(msg.to, {
                        type: 'webrtc-answer',
                        call_id: msg.call_id,
                        sdp: msg.sdp,
                        from: userId
                    });
                    break;

                case 'ice-candidate':
                    forwardToUser(msg.to, {
                        type: 'ice-candidate',
                        call_id: msg.call_id,
                        candidate: msg.candidate,
                        from: userId
                    });
                    break;

                // Call management
                case 'call-start':
                    handleCallStart(userId, msg);
                    break;

                case 'call-accept':
                    handleCallAccept(userId, msg);
                    break;

                case 'call-reject':
                case 'call-end':
                    handleCallEnd(userId, msg);
                    break;

                default:
                    console.log(`[WS] Unknown message type: ${msg.type}`);
            }
        } catch (e) {
            console.error('[WS] Message parse error:', e.message);
        }
    });

    ws.on('close', () => {
        if (userId) {
            clients.delete(userId);
            broadcast({ type: 'user-offline', user_id: userId }, userId);

            // End any active calls for this user
            for (const [callId, call] of activeCalls) {
                if (call.callerId === userId || call.receiverId === userId) {
                    const otherUser = call.callerId === userId ? call.receiverId : call.callerId;
                    forwardToUser(otherUser, { type: 'call-ended', call_id: callId });
                    activeCalls.delete(callId);
                }
            }

            console.log(`[WS] User disconnected: ${userId}`);
        }
    });

    ws.on('error', (err) => {
        console.error('[WS] Error:', err.message);
    });
});

function handleMessage(userId, msg) {
    // Forward message to chat participants
    // For now, broadcast to all connected users
    const outMsg = {
        type: 'message',
        message: {
            id: generateId(),
            chat_id: msg.chat_id,
            sender_id: userId,
            text: msg.text,
            message_type: msg.message_type || 'text',
            created_at: new Date().toISOString(),
            is_read: false
        }
    };
    broadcast(outMsg, userId);
}

function handleTyping(userId, msg) {
    broadcast({
        type: 'typing',
        chat_id: msg.chat_id,
        user_id: userId
    }, userId);
}

function handleRead(userId, msg) {
    broadcast({
        type: 'read',
        chat_id: msg.chat_id,
        user_id: userId,
        message_id: msg.message_id
    }, userId);
}

function handleCallStart(userId, msg) {
    const callId = msg.call_id || generateId();
    const receiverId = msg.to;

    activeCalls.set(callId, {
        callerId: userId,
        receiverId: receiverId,
        isVideo: msg.is_video || false,
        startedAt: new Date()
    });

    // Notify receiver
    forwardToUser(receiverId, {
        type: 'call-incoming',
        call_id: callId,
        chat_id: msg.chat_id || '',
        is_video: msg.is_video || false,
        from: userId
    });

    console.log(`[WS] Call started: ${callId} from ${userId} to ${receiverId}`);
}

function handleCallAccept(userId, msg) {
    const callId = msg.call_id;
    const call = activeCalls.get(callId);
    if (call) {
        forwardToUser(call.callerId, {
            type: 'call-accepted',
            call_id: callId
        });
        console.log(`[WS] Call accepted: ${callId}`);
    }
}

function handleCallEnd(userId, msg) {
    const callId = msg.call_id;
    const call = activeCalls.get(callId);
    if (call) {
        const otherUser = call.callerId === userId ? call.receiverId : call.callerId;
        forwardToUser(otherUser, {
            type: 'call-ended',
            call_id: callId
        });
        activeCalls.delete(callId);
        console.log(`[WS] Call ended: ${callId}`);
    }
}

function forwardToUser(targetUserId, msg) {
    const client = clients.get(targetUserId);
    if (client && client.readyState === WebSocket.OPEN) {
        client.send(JSON.stringify(msg));
        return true;
    }
    return false;
}

function broadcast(msg, excludeUserId) {
    const data = JSON.stringify(msg);
    clients.forEach((client, uid) => {
        if (uid !== excludeUserId && client.readyState === WebSocket.OPEN) {
            client.send(data);
        }
    });
}

function generateId() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

// Ping to keep connections alive
setInterval(() => {
    wss.clients.forEach((ws) => {
        if (ws.isAlive === false) return ws.terminate();
        ws.isAlive = false;
        ws.ping();
    });
}, 30000);

wss.on('connection', (ws) => {
    ws.isAlive = true;
    ws.on('pong', () => { ws.isAlive = true; });
});
WSEOF

# Restart WS server
cd /opt/finder
pm2 restart ws-server 2>/dev/null || pm2 start ws-server.js --name ws-server
pm2 save

echo "WebSocket server updated with WebRTC signaling!"
