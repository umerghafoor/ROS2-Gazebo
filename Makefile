.PHONY: build run shell stop clean demo x11 help

help:
	@echo "ROS2-Gazeebo — Make targets"
	@echo "  make build   Build the Docker image"
	@echo "  make run     Start an interactive container"
	@echo "  make shell   Open another shell in the running container"
	@echo "  make demo    Run the gz sim shapes demo"
	@echo "  make x11     Set up X11 forwarding only"
	@echo "  make stop    Stop and remove the container"
	@echo "  make clean   Remove the image too"

build:
	./scripts/build.sh

run:
	./scripts/run.sh

shell:
	./scripts/shell.sh

stop:
	./scripts/stop.sh

clean:
	./scripts/clean.sh

demo:
	./scripts/demo.sh

x11:
	./scripts/setup_x11.sh
