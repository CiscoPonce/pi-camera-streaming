/**
 * SRS WebRTC Player for Pi Camera Streaming
 * Created by CiscoPonce
 * Handles WebRTC connection with FLV fallback
 * Optimized for Raspberry Pi 5 with Camera Module 3
 */

let currentPlayer = null;
let isConnected = false;

async function playWebRTC() {
  const video = document.getElementById('player');
  const host = window.location.hostname;
  const api = `http://${host}:1985/rtc/v1/play/`;
  const streamurl = `webrtc://${host}/live/cam`;

  console.log('Attempting WebRTC connection...');
  console.log('API:', api);
  console.log('Stream URL:', streamurl);

  const pc = new RTCPeerConnection({ 
    iceServers: [
      { urls: 'stun:stun.l.google.com:19302' },
      { urls: 'stun:stun1.l.google.com:19302' }
    ]
  });
  
  pc.addTransceiver('video', { direction: 'recvonly' });
  
  pc.ontrack = (e) => { 
    console.log('WebRTC track received');
    video.srcObject = e.streams[0];
    isConnected = true;
    updateStatus('WebRTC connected', 'connected');
  };

  pc.oniceconnectionstatechange = () => {
    console.log('ICE connection state:', pc.iceConnectionState);
    if (pc.iceConnectionState === 'connected') {
      updateStatus('WebRTC connected', 'connected');
    } else if (pc.iceConnectionState === 'failed') {
      updateStatus('WebRTC connection failed', 'error');
    }
  };

  pc.onicecandidate = (e) => {
    if (e.candidate) {
      console.log('ICE candidate:', e.candidate.candidate);
    }
  };

  const offer = await pc.createOffer({ offerToReceiveVideo: true });
  await pc.setLocalDescription(offer);

  try {
    const r = await fetch(api, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ api, streamurl, sdp: offer.sdp })
    });
    
    if (!r.ok) {
      throw new Error(`SRS play failed: ${r.status} ${r.statusText}`);
    }
    
    const data = await r.json();
    console.log('SRS response:', data);
    
    await pc.setRemoteDescription({ type: 'answer', sdp: data.sdp });
    
    window._pc = pc;
    currentPlayer = { type: 'webrtc', pc };
    
  } catch (error) {
    console.error('WebRTC connection failed:', error);
    throw error;
  }
}

async function playFLV() {
  const v = document.getElementById('player');
  const host = window.location.hostname;
  const flvUrl = `http://${host}:8081/live/cam.flv`;
  
  console.log('Attempting FLV fallback...');
  console.log('FLV URL:', flvUrl);
  
  if (flvjs.isSupported()) {
    const player = flvjs.createPlayer({ 
      type: 'flv', 
      url: flvUrl, 
      isLive: true, 
      hasAudio: false, 
      hasVideo: true,
      enableWorker: false,
      enableStashBuffer: false,
      stashInitialSize: 128
    });

    player.attachMediaElement(v);
    
    player.on(flvjs.Events.LOADING_COMPLETE, () => {
      console.log('FLV loading complete');
      updateStatus('FLV stream connected', 'connected');
    });
    
    player.on(flvjs.Events.ERROR, (errorType, errorDetail) => {
      console.error('FLV error:', errorType, errorDetail);
      updateStatus(`FLV error: ${errorType}`, 'error');
    });
    
    player.on(flvjs.Events.MEDIA_INFO, (mediaInfo) => {
      console.log('FLV media info:', mediaInfo);
    });
    
    player.load();
    player.play();
    
    window._flv = player;
    currentPlayer = { type: 'flv', player };
    
  } else {
    console.log('FLV.js not supported, using native video');
    v.src = flvUrl;
    await v.play();
    currentPlayer = { type: 'native', element: v };
  }
}

function updateStatus(message, type) {
  const status = document.getElementById('status');
  if (status) {
    status.textContent = message;
    status.className = `status ${type}`;
  }
  console.log(`Status: ${message} (${type})`);
}

function disconnect() {
  if (currentPlayer) {
    if (currentPlayer.type === 'webrtc' && currentPlayer.pc) {
      currentPlayer.pc.close();
    } else if (currentPlayer.type === 'flv' && currentPlayer.player) {
      currentPlayer.player.destroy();
    }
    currentPlayer = null;
  }
  
  if (window._pc) {
    window._pc.close();
    window._pc = null;
  }
  
  if (window._flv) {
    window._flv.destroy();
    window._flv = null;
  }
  
  const video = document.getElementById('player');
  if (video) {
    video.srcObject = null;
    video.src = '';
  }
  
  isConnected = false;
  updateStatus('Disconnected', 'info');
}

// Initialize connection on page load
window.addEventListener('DOMContentLoaded', async () => {
  console.log('Initializing Pi Camera Viewer...');
  updateStatus('Connecting to stream...', 'info');
  
  try {
    // Try WebRTC first
    await playWebRTC();
    console.log('WebRTC connection successful');
  } catch (webrtcError) {
    console.warn('WebRTC failed, trying FLV fallback:', webrtcError);
    
    try {
      // Fallback to FLV
      await playFLV();
      console.log('FLV fallback successful');
    } catch (flvError) {
      console.error('Both WebRTC and FLV failed:', flvError);
      updateStatus('Failed to connect to stream', 'error');
    }
  }
});

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
  disconnect();
});

// Export functions for external use
window.PiCameraPlayer = {
  playWebRTC,
  playFLV,
  disconnect,
  updateStatus
};
