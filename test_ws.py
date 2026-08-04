import asyncio
import websockets

async def test():
    try:
        async with websockets.connect('ws://localhost:8765') as ws:
            print("Successfully connected to YOLO WebSocket")
            await asyncio.sleep(2)
            print("Closing connection")
    except Exception as e:
        print(f"Connection failed: {e}")

if __name__ == "__main__":
    asyncio.run(test())
