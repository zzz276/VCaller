import express from 'express';
import http from 'http';
import { Server } from 'socket.io';
import 'dotenv/config';

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' },
  pingInterval: 30000,
  pingTimeout: 15000,
});

const PORT = process.env.PORT || 3000;
const WHEREBY_API_KEY = process.env.WHEREBY_API_KEY;
const WHEREBY_API_URL = 'https://api.whereby.dev/v1/meetings';

const users = {};

// Handle socket connections
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);

  // Register userId when client connects
  socket.on('register', (userId) => {
    users[userId] = socket.id;

    console.log(`Registered user ${userId} with socket ${socket.id}`);
  });

  // Caller initiates a call
  socket.on('callUser', async ({ from, to }) => {
    if (!users[to]) {
      console.log(`User ${to} not connected`);

      return;
    }

    let endDate = new Date(Date.now() + (7 * 24 * 60 * 60 * 1000));

    try {
      // 1. Create a Whereby room via API
      const response = await fetch(WHEREBY_API_URL, {
        method: 'POST',
        headers: {
          "Authorization": `Bearer ${WHEREBY_API_KEY}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          "endDate": endDate.toISOString(),
          "isLocked": false,
          "roomMode": "normal",
          "roomNamePrefix": "v-call",
          "roomNamePattern": "human-short"
        })
      });
      
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ message: 'No JSON body or body unreadable.' }));
        console.error(`Whereby API Error: HTTP Status ${response.status}`, errorData);
        // Inform the caller that the call failed (optional but good practice)
        io.to(users[from]).emit('callFailed', { reason: `Call failed: API error ${response.status}` });

        return;
      }

      const data = await response.json();
      const meetingId = data.meetingId;
      const roomUrl = data.roomUrl;

      // 2. Send callRequest to the callee with the roomUrl
      io.to(users[from]).emit('getRequest', { meetingId, roomUrl });

      io.to(users[to]).emit('callRequest', { from, meetingId, roomUrl });

      console.log(`Room created: ${roomUrl}, sent to ${to}`);
    } catch (err) { console.error('Error creating Whereby room:', err); }
  });

  socket.on('deleteRoom', async ({ meetingId }) => {
    try {
      // 3. Delete a Whereby room via API
      const response = await fetch(`${WHEREBY_API_URL}/${meetingId}`, {
        method: 'DELETE',
        headers: {
          "Authorization": `Bearer ${WHEREBY_API_KEY}`,
          "Content-Type": "application/json"
        }
      });

      if (response.status(429)) {
        const data = response.json();

        console.log(data["error"]);
      } else if (response.status(401)) {
        console.log('Access token is missing or invalid.');
      } else {
        console.log(`Room with room ID: ${meetingId} was deleted successfully.`);
      }
    } catch (err) { console.error('Error deleting Whereby room:', err); }
  });

  // Callee accepts the call
  socket.on('acceptCall', ({ from, to, meetingId, roomUrl }) => {
    if (users[from]) {
      io.to(users[from]).emit('callAccepted', { meetingId, roomUrl });
      console.log(`User ${to} accepted call from ${from}`);
    }
  });

  // Callee rejects the call
  socket.on('rejectCall', ({ from, to }) => {
    if (users[from]) {
      io.to(users[from]).emit('callRejected');
      console.log(`User ${to} rejected call from ${from}`);
    }
  });

  // Relay signaling data (SDP/ICE candidates)
  socket.on('signal', (data) => {
    console.log('Signal data:', data);
    socket.broadcast.emit('signal', data);
  });

  // Handle disconnect
  socket.on('disconnect', () => {
    for (const [userId, sId] of Object.entries(users)) {
      if (sId === socket.id) {
        delete users[userId];
        console.log(`User ${userId} disconnected`);
        break;
      }
    }
  });
});

// Start the server
server.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
    console.log(`Whereby API Key is set: ${!!WHEREBY_API_KEY}`);
});
