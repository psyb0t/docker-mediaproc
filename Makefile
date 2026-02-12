# Docker image configuration
IMAGE_NAME := psyb0t/mediaproc
TAG := latest
TEST_TAG := $(TAG)-test

.PHONY: build build-test test installer clean help

# Default target
all: build

# Build the main image
build:
	docker build -t $(IMAGE_NAME):$(TAG) .

# Build the test image with -test suffix
build-test:
	docker build -t $(IMAGE_NAME):$(TEST_TAG) .

# Build test image and run integration tests
test: build-test
	./test.sh

# Generate install.sh from installer.yaml using lockbox's create_installer.sh
installer:
	curl -fsSL https://raw.githubusercontent.com/psyb0t/docker-lockbox/main/create_installer.sh | bash -s installer.yaml > install.sh
	chmod +x install.sh

# Clean up images
clean:
	docker rmi $(IMAGE_NAME):$(TAG) || true
	docker rmi $(IMAGE_NAME):$(TEST_TAG) || true

# Show available targets
help:
	@echo "Available targets:"
	@echo "  build      - Build the main Docker image"
	@echo "  build-test - Build the test Docker image with -test suffix"
	@echo "  clean      - Remove built images"
