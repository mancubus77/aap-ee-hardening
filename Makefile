.PHONY: build run_test

REGISTRY ?= quay.io/mancubus77
IMAGE ?= winee
TAG ?= pub

build:
	ansible-builder build -v3 -t ${REGISTRY}/${IMAGE}:${TAG}

run_test:
	ansible-navigator --ce podman --eei ${REGISTRY}/${IMAGE}:${TAG} run test/pb.yaml -m stdout

push:
	podman push ${REGISTRY}/${IMAGE}:${TAG}