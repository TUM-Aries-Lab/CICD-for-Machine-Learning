SHELL := /bin/bash
OS := $(shell uname -s)

init:
	python3 -m venv .venv
	poetry install --with dev
	pre-commit install
	poetry env info
	@echo "Created virtual environment"

test:
	poetry run pytest --cov=src/ --cov-report=term-missing --no-cov-on-fail

format:
	ruff format
	ruff check --fix
	poetry run mypy src/ tests/ --ignore-missing-imports

train:
	python train.py

eval:
	echo "## Model Metrics" > report.md
	cat ./Results/metrics.txt >> report.md

	echo '\n## Confusion Matrix Plot' >> report.md
	echo '![Confusion Matrix](./Results/model_results.png)' >> report.md

	cml comment create report.md

update-branch:
	git config --global user.name $(USER_NAME)
	git config --global user.email $(USER_EMAIL)
	git commit -am "Update with new results"
	git push --force origin HEAD:update

hf-login:
	curl -LsSf https://hf.co/cli/install.sh | bash
	git pull origin update
	git switch update
	hf auth login --token $(HF) --add-to-git-credential

push-hub:
	hf upload Tsmorz/Drug-Classification ./src/App --repo-type=space --commit-message="Sync App files"
	hf upload Tsmorz/Drug-Classification ./Model /Model --repo-type=space --commit-message="Sync Model"
	hf upload Tsmorz/Drug-Classification ./Results /Metrics --repo-type=space --commit-message="Sync Model"

deploy: hf-login push-hub

all: install format train eval update-branch deploy

clean:
	rm -rf .venv
	rm -rf .mypy_cache
	rm -rf .pytest_cache
	rm -rf build/
	rm -rf dist/
	rm -rf juninit-pytest.xml
	rm -rf logs/*
	find . -name ".coverage*" -delete
	find . -name --pycache__ -exec rm -r {} +

update:
	poetry cache clear pypi --all
	poetry update

docker:
	docker build --no-cache -f Dockerfile -t change_me-smoke .
	docker run --rm change_me-smoke

app:
	poetry run python -m change_me
