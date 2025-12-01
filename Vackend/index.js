import express from 'express';
import axios from 'axios';
import http from 'http';
import { Server } from 'socket.io';

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

const baseURL = 'https://api.whereby.dev/v1/meetings'
const API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmFwcGVhci5pbiIsImF1ZCI6Imh0dHBzOi8vYXBpLmFwcGVhci5pbi92MSIsImV4cCI6OTAwNzE5OTI1NDc0MDk5MSwiaWF0IjoxNzYyODIwNzUwLCJvcmdhbml6YXRpb25JZCI6MzI4NzY3LCJqdGkiOiI0OGQzYjFlMi02YTljLTQ5NGQtYjlkZC00MTUwNDJmYzAzODAifQ.mQWuhmPEhDxzB3RshbQ4DSwuFRJnnqrQvU2Z4Ew94l0";

app.post('/create-room', async (req, res) => {
  try {
    const response = await axios.post(baseURL, {
      endDate: new Date(Date.now() + (7 * 24 * 60 * 60 * 1000)).toISOString(),
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

server.listen(3000, () => {
  console.log('Server running at http://localhost:3000');
});
