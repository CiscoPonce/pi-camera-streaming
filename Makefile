# Pi Camera Streaming Makefile
# Simplifies common operations

.PHONY: help setup install start stop restart test clean logs status

# Default target
help:
	@echo "Pi Camera Streaming - Available commands:"
	@echo ""
	@echo "  make setup     - Run automated setup script"
	@echo "  make install   - Install dependencies and configure system"
	@echo "  make start     - Start all services (containers + camera)"
	@echo "  make stop      - Stop all services"
	@echo "  make restart   - Restart all services"
	@echo "  make test      - Run system verification tests"
	@echo "  make logs      - View service logs"
	@echo "  make status    - Check service status"
	@echo "  make clean     - Clean up containers and images"
	@echo ""
	@echo "  make help      - Show this help message"

# Run setup script
setup:
	@echo "Running setup script..."
	chmod +x scripts/setup.sh
	./scripts/setup.sh

# Install dependencies (manual setup)
install:
	@echo "Installing dependencies..."
	sudo apt update
	sudo apt install -y docker.io docker-compose-plugin libcamera-tools ffmpeg
	sudo usermod -aG docker $$USER
	@echo "Please log out and back in for Docker group changes to take effect"

# Start all services
start:
	@echo "Starting services..."
	docker-compose up -d
	@echo "Services started. Run 'make start-camera' to begin streaming."

# Start camera streaming
start-camera:
	@echo "Starting camera streaming..."
	chmod +x scripts/start-camera.sh
	./scripts/start-camera.sh

# Stop all services
stop:
	@echo "Stopping services..."
	pkill -f rpicam-vid || true
	docker-compose down

# Restart all services
restart: stop start

# Run tests
test:
	@echo "Running system tests..."
	chmod +x scripts/test-setup.sh
	./scripts/test-setup.sh

# View logs
logs:
	@echo "=== SRS Logs ==="
	docker logs srs --tail 50
	@echo ""
	@echo "=== Nginx Logs ==="
	docker logs cam-viewer --tail 50

# Check status
status:
	@echo "=== Container Status ==="
	docker-compose ps
	@echo ""
	@echo "=== Camera Process ==="
	ps aux | grep rpicam-vid | grep -v grep || echo "No camera streaming process found"
	@echo ""
	@echo "=== System Resources ==="
	@if command -v vcgencmd >/dev/null 2>&1; then \
		echo "CPU Temperature: $$(vcgencmd measure_temp | cut -d'=' -f2)"; \
	fi
	@echo "Memory Usage: $$(free | grep Mem | awk '{printf "%.1f%%", $$3/$$2 * 100.0}')"

# Clean up
clean:
	@echo "Cleaning up..."
	docker-compose down -v
	docker system prune -f
	pkill -f rpicam-vid || true

# Development helpers
dev-start:
	@echo "Starting development environment..."
	docker-compose up -d
	@echo "Development environment ready at http://localhost/"

dev-stop:
	@echo "Stopping development environment..."
	docker-compose down

# Quick start (for experienced users)
quick-start: start start-camera
	@echo "Quick start complete!"
	@echo "View stream at: http://$$(hostname -I | awk '{print $$1}')/"

# Full setup (for new users)
full-setup: setup
	@echo "Full setup complete!"
	@echo "Please reboot your system and then run: make start"
