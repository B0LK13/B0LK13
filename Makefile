install:
	npm ci

sync:
	npm run etl:sync

lint:
	npm run lint

build:
	npm run build

test:
	npm run lint && npm run build
