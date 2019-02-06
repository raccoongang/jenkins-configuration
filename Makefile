SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help
.PHONY: clean requirements plugins build logs e2e show run

help:
	@echo ''
	@echo 'Makefile for '
	@echo '     make help            show this information'
	@echo '     make clean           shutdown running container and delete image and clean workspace'
	@echo '     make clean.container shutdown running container and delete image'
	@echo '     make clean.ws        delete all groovy/gradle artifacts in the workspace'
	@echo '     make build           build a dockerfile for testing the jenkins configuration'
	@echo '     make run             run the dockerfile and kickoff jenkins'
	@echo '     make run.container   run the dockerfile without starting the jenkins .war'
	@echo '     make run.jenkins     run the jenkins .war on the container'
	@echo '     make logs            tail the logs for the Jenkins container'
	@echo '     make shell           shell into the runnning Jenkkins container for debugging'
	@echo '     make healthcheck     run healthcheck script to test if Jenkins has successfully booted'
	@echo '     make quality         run codenarc on groovy source and tests'
	@echo '     make requirements    install requirements for acceptance tests'
	@echo '     make plugins         install specified Jenkins plugins and their dependencies'
	@echo '     make show            show the versions of downloaded plugins'
	@echo '     make e2e             run python acceptance tests against a provisioned docker container'

clean: clean.container clean.ws

clean.container:
# run the following docker commands with '|| true' because they do not have a 'quiet' flag
	docker kill $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true
	docker rmi $(CONTAINER_NAME) || true

clean.ws:
	./gradlew clean
	./gradlew -b plugins.gradle clean

build: build-master build-worker

build-master:
	docker build -f Dockerfile.master \
		-t $(CONTAINER_NAME) --build-arg=CONFIG_PATH=$(CONFIG_PATH) \
		--build-arg=JENKINS_VERSION=$(JENKINS_VERSION) \
		--build-arg=JENKINS_WAR_SOURCE=$(JENKINS_WAR_SOURCE) \
		--target=$(TEST_SHARD) .

build-worker:
	docker build -t jenkins_worker:hawthorn.master - < Dockerfile.worker

run:
	docker-compose up -d

stop:
	docker-compose stop

logs:
	docker exec $(CONTAINER_NAME) tail -f /var/log/jenkins/jenkins.log

shell:
	docker exec -it $(CONTAINER_NAME) /bin/bash

healthcheck:
	./healthcheck.sh

quality:
	./gradlew codenarcMain codenarcTest

requirements:
	./gradlew libs
	pip install -r test-requirements.txt

plugins:
	./gradlew -b plugins.gradle plugins

e2e:
	pytest

show:
	./gradlew -b plugins.gradle show
