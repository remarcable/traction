# Rails Deployment on Uberspace

This guide walks you through deploying a Rails application on [Uberspace](https://uberspace.de/) using Git, MariaDB, and Supervisor. It assumes familiarity with Rails, SSH, Git, and basic Unix commands.

## Contents

- [Rails Deployment on Uberspace](#rails-deployment-on-uberspace)
  - [Contents](#contents)
  - [1. Set up remote repository](#1-set-up-remote-repository)
    - [Create Remote Repository](#create-remote-repository)
    - [Create app directory with contents of main branch](#create-app-directory-with-contents-of-main-branch)
    - [Create post-receive hook for automatic deployment](#create-post-receive-hook-for-automatic-deployment)
    - [Install dependencies](#install-dependencies)
  - [2. Set up the database](#2-set-up-the-database)
    - [Set up MySQL](#set-up-mysql)
    - [Create database tables](#create-database-tables)
    - [Update indices](#update-indices)
    - [Verify database setup](#verify-database-setup)
  - [3. Create a web backend](#3-create-a-web-backend)
  - [4. Test run application](#4-test-run-application)
  - [5. Process management with Supervisor](#5-process-management-with-supervisor)
  - [6. Automate deployment](#6-automate-deployment)

## 1. Set up remote repository

### Create Remote Repository

SSH into your Uberspace account:

```bash
ssh your_uberspace_username@your_uberspace_host
mkdir -p ~/repos/example-app.git
cd ~/repos/example-app.git
git init --bare
```

On your local machine, add this repository as a remote:

```bash
# On local machine
cd path/to/example-app
git remote add uberspace your_uberspace_username@your_uberspace_host:repos/example-app.git
```

The Uberspace host typically has a format like `longmore.uberspace.de`.

### Create app directory with contents of main branch

On Uberspace, create a directory for the application:

```bash
mkdir -p ~/apps/example-app
GIT_WORK_TREE="$HOME/apps/example-app" git checkout -f main
```

Verify the files were copied:

```bash
cd ~/apps/example-app
ls
```

### Create post-receive hook for automatic deployment

Create a hook file in the bare repository to automate deployment:

```bash
# Create and edit the hook file
nano ~/repos/example-app.git/hooks/post-receive
```

Add this content:

```bash
#!/bin/bash
TARGET_DIR="$HOME/apps/example-app"

echo "Deploying to $TARGET_DIR..."

GIT_WORK_TREE="$TARGET_DIR" git checkout -f main
```

Make the hook executable:

```bash
chmod +x ~/repos/example-app.git/hooks/post-receive
```

### Install dependencies

In your app directory on Uberspace:

```bash
# Set Ruby version
uberspace tools version use ruby 3.4

# Configure bundler
bundle lock --add-platform ruby
bundle config set force_ruby_platform true

# Install dependencies
bundle install
```

## 2. Set up the database

### Set up MySQL

Update your Gemfile:

```ruby
group :development, :test do
  gem "sqlite3", ">= 2.1"
end

group :production do
  gem 'mysql2', '~> 0.5.2'
end
```

Configure `config/database.yml` for production:

```yaml
production:
  primary: &primary
    adapter: mysql2
    encoding: utf8mb4
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
    username: <%= ENV.fetch("RAILS_DB_USERNAME") %>
    password: <%= ENV.fetch("RAILS_DB_PASSWORD") %>
    host: localhost
    database: username_appname_production

  cache:
    <<: *primary
    database: username_appname_production_cache
    migrations_paths: db/cache_migrate

  queue:
    <<: *primary
    database: username_appname_production_queue
    migrations_paths: db/queue_migrate

  cable:
    <<: *primary
    database: username_appname_production_cable
    migrations_paths: db/cable_migrate
```

Important: Replace `username_appname` with your Uberspace username and app name. Database names must start with your username (see [the manual](https://manual.uberspace.de/database-mysql/#additional-databases) for more details.)

Create `.env.production` on Uberspace:

```
RAILS_DB_USERNAME=your_uberspace_username
RAILS_DB_PASSWORD=find_in_~/.my.cnf
SECRET_KEY_BASE=... # generate with: bundle exec rails secret
```

Add `dotenv-rails` to your Gemfile:

```ruby
gem 'dotenv-rails', :groups => [:production, :development, :test]
```

Then run locally:

```bash
bundle install
git add .
git commit -m "Update database configuration for production"
git push uberspace
```

### Create database tables

SSH into Uberspace and open MySQL:

```bash
mysql
```

Create all required databases:

```sql
CREATE DATABASE username_appname_production CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE username_appname_production_cache CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE username_appname_production_queue CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE username_appname_production_cable CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Unlike with SQLite, databases in MySQL aren't created automatically. So here you're doing this yourself.

### Update indices

Create a migration to fix potential foreign key type issues:

```bash
rails generate migration ChangeForeignKeysToBigInt
```

Edit the migration file:

```ruby
class ChangeForeignKeysToBigInt < ActiveRecord::Migration[8.0]
  def change
    # Update every foreign key like this example:
    # Check db/schema.rb for potential foreign keys
    remove_foreign_key :sessions, :users
    change_column :sessions, :user_id, :bigint, null: false
    add_foreign_key :sessions, :users
  end
end
```

Run the migration locally, then commit and push:

```bash
bin/rails db:migrate
git add .
git commit -m "Fix foreign key types"
git push uberspace
```

The reason for this migration is that the data type of the foreign key fields (integer) doesn't match the ID fields (bigint), especially if you use SQLite locally.

### Verify database setup

On Uberspace:

```bash
bundle exec rails db:setup RAILS_ENV=production
```

## 3. Create a web backend

Make your app accessible from the outside:

```bash
uberspace web backend set example-app.myuberspacename.uberspace.de --http --port 45678
```

Choose an unused port between 1024 and 65535. Verify port availability with `lsof -i :45678`. You can find more info on [web backends](https://manual.uberspace.de/web-backends/) in the Uberspace docs.

## 4. Test run application

Prepare the application:

```bash
bundle exec rake assets:precompile RAILS_ENV=production
bundle exec rails db:setup RAILS_ENV=production
```

Start the Rails server:

```bash
RAILS_ENV=production bundle exec rails server -e production -b 0.0.0.0 -p 45678
```

Visit your app's URL to verify it works. The first visit might take a bit longer to load.

## 5. Process management with Supervisor

Create a new configuration file at `~/etc/services.d/example-app.ini`:

```ini
[program:example-app]
directory=%(ENV_HOME)s/apps/example-app
command=bundle exec rails server -e production -b 0.0.0.0 -p 45678
environment=RAILS_ENV="production"
```

Stop any running instance of your app, then reload supervisor:

```bash
supervisorctl reread
supervisorctl update
```

Common Supervisor commands are `supervisorctl status` to see if your app is running, `supervisorctl tail example-app` to view the logs, and `supervisorctl restart example-app` to restart your app.

## 6. Automate deployment

Update the post-receive hook to fully automate deployment:

```bash
#!/bin/bash
set -e

TARGET_DIR="$HOME/apps/example-app"

echo "Deploying to $TARGET_DIR..."

GIT_WORK_TREE="$TARGET_DIR" git checkout -f main
cd "$TARGET_DIR"

bundle lock --add-platform ruby
bundle install

export RAILS_ENV=production

echo "Precompiling assets..."
bundle exec rake assets:precompile RAILS_ENV=production

echo "Migrating DB..."
bundle exec rails db:migrate RAILS_ENV=production

echo "Restarting application..."
supervisorctl restart example-app
```

Test the deployment workflow with a push from your local machine:

```bash
git push uberspace main
```

You should see deployment logs similar to:

```
~/Code/example-app: git push uberspace main
Total 0 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
remote: Deploying to /home/my_username/apps/example-app...
remote: Already on 'main'
remote: Writing lockfile to /home/my_username/apps/example-app/Gemfile.lock
remote: Fetching gem metadata from https://rubygems.org/.........
remote: Resolving dependencies...
remote: Bundle complete! 25 Gemfile dependencies, 92 gems now installed.
remote: Gems in the groups 'development' and 'test' were not installed.
remote: Bundled gems are installed into `./vendor/bundle`
remote: 1 installed gem you directly depend on is looking for funding.
remote:   Run `bundle fund` for details
remote: Precompiling assets...
remote: Migrating DB
remote: Restarting application...
remote: example-app: stopped
remote: example-app: started
To uberspace:~/repos/example-app.git
 + 96107e1...efebc48 main -> main (forced update)

```

After deployment completes, visit your app URL to verify everything works correctly. Your Rails app is now deployed on Uberspace with automatic deployment via `git push`!
