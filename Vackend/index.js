import express from 'express';
import axios from 'axios';
import http from 'http';
import fetch from 'node-fetch';
// import dotenv from 'dotenv';
import { Server } from 'socket.io';
import 'dotenv/config';

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

const PORT = process.env.PORT || 3000;
const WHEREBY_API_KEY = process.env.WHEREBY_API_KEY;
const WHEREBY_API_URL = 'https://api.whereby.dev/v1/meetings';

app.use(express.json());

app.post('/create-room', async (req, res) => {
  try {
    const response = await axios.post(baseURL, {
      endDate: new Date(Date.now() + (7 * 24 * 60 * 60 * 1000)).toISOString(), // Whereby room expires in 7 days.
      isLocked: false,
      roomNamePrefix: 'v-call',
      roomNamePattern: 'human-short',
    }, {
      headers: {
        Authorization: `Bearer ${API_KEY}`,
        'Content-Type': 'application/json',
      }
    });

    const roomUrl = response.data.roomUrl;
    const meetingId = response.data.meetingId;

    res.json({ roomUrl, meetingId });
  } catch (error) {
    console.error(error);
    res.status(500).send('Failed to create room.');
  }
});

app.delete('/delete-room/:meetingId', async (req, res) => {
  try {
    const { meetingId } = req.params;
    await axios.delete(`${baseURL}/${meetingId}`, {
      headers: { Authorization: `Bearer ${API_KEY}` }
    });

    res.send('Room has been deleted.');
  } catch (error) {
    console.error(error);
    res.status(500).send('Failed to delete room.');
  }
});

async function createWherebyRoom(expiryInMinutes = (7 * 24 * 60)) {
  if (!WHEREBY_API_KEY) {
    console.error("Whereby API Key is missing!");
    return null;
  }

  // Calculate endDate (ISO 8601 format)
  const endDate = new Date(Date.now() + expiryInMinutes * 60 * 1000).toISOString();
  const roomConfig = {
    // The room will be automatically deleted 1 week after endDate
    endDate: endDate,
    isLocked": false,
    roomMode": "normal",
    roomNamePrefix: 'v-call',
    roomNamePattern: 'human-short',
  };
  
  try {
    const response = await fetch(WHEREBY_API_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${WHEREBY_API_KEY}`,
        'Content-Type': 'application/json'
      },
      
      body: JSON.stringify(roomConfig)
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Whereby API error: ${response.status} - ${errorText}`);
    }
    
    const data = await response.json();
    
    console.log(`Room created: ${data.roomUrl}`);
    return data.roomUrl;
  } catch (error) {
    console.error('Error creating Whereby room:', error.message);
    return null;
  }
}

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('join-room', (data) => {
    socket.join(data.meetingId);
    console.log(`${data.user} joined room ${data.meetingId}`);
    socket.to(data.meetingId).emit('user-joined', { user: data.user });
  });

  socket.on("chat-message", (data) => {
    io.to(data.meetingId).emit("chat-message", { user: data.user, message: data.message });
  });

  socket.on("disconnect", () => {
    console.log("User disconnected:", socket.id);
  });
});

io.on('connection', (socket) => {
    console.log(`A user connected: ${socket.id}`);

    // This map stores which user is associated with which socket ID
    // In a real app, this should be linked to Firebase UID
    let userId = null; 

    // Event: User registers their ID (e.g., Firebase UID)
    socket.on('registerUser', (id) => {
        userId = id;
        socket.join(userId); // Join a private room named after the user ID
        console.log(`User ${userId} registered and joined their private room.`);
    });

    // Event: A user initiates a call to another user
    socket.on('initiateCall', async ({ callerId, calleeId }) => {
        console.log(`Call initiated from ${callerId} to ${calleeId}`);
        
        // 1. Create the Whereby room
        const roomUrl = await createWherebyRoom(30); // 30 minutes expiry

        if (roomUrl) {
            // 2. Send the call offer with the room URL to the callee
            io.to(calleeId).emit('incomingCall', {
                roomUrl: roomUrl,
                callerId: callerId
            });

            // 3. Send confirmation back to the caller
            socket.emit('callInitiatedSuccess', { roomUrl: roomUrl, calleeId: calleeId });
        } else {
            // Handle room creation failure
            socket.emit('callFailure', { message: 'Could not create video room.' });
        }
    });

    // Event: Callee accepts the call
    socket.on('acceptCall', ({ callerId, roomUrl }) => {
        // Notify the original caller that the call was accepted
        io.to(callerId).emit('callAccepted', { roomUrl: roomUrl });
    });

    // Event: Callee declines the call
    socket.on('declineCall', ({ callerId }) => {
        io.to(callerId).emit('callDeclined');
    });

    socket.on('disconnect', () => {
        console.log(`User disconnected: ${socket.id} (ID: ${userId})`);
        // In a real app, update Firestore status (e.g., 'is_online': false)
    });
});

// Start the server
Server.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
    console.log(`Whereby API Key is set: ${!!WHEREBY_API_KEY}`);
});
