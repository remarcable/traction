# Traction

A simple streak tracker to build and maintain daily habits.

## Getting Started

1. Clone the repository
2. Install dependencies: `bundle install`
3. Create `.env`: `cp sample.env .env` (no need to fill out for development)
4. Set up the database: `bin/rails db:setup`
5. Start the server: `bin/rails server`
6. Visit `http://localhost:3000`

## Deployment

Traction is a standard Rails app that you can deploy to any hosting environment.

I've created a [deployment guide](./docs/Deployment%20on%20Uberspace.md) for deploying using `git push` specifically on [Uberspace](https://uberspace.de).

## Motivation

I've always wanted a super simple streak tracker that's not distracting with raw access to the data. This project is my attempt to build this, and explore Ruby on Rails at the same time.
