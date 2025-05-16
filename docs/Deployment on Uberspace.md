# 🚀 Rails Deployment on Uberspace (with Git + Supervisor)

This guide outlines how to deploy a Rails app to [Uberspace](https://uberspace.de/) using Git, MariaDB, and `supervisord`.

# 1. Set up remote repository

## Create Remote Repository

SSH into your uberspace and create a remote repository:

```bash
ssh your_uberspace_username@your_uberspace_host
mkdir -p ~/repos/example-app.git
cd ~/repos/example-app.git
git init --bare
```

Then on your local machine, you can add a remote to push into this repository:

```bash
# On local machine
cd path/to/example
git remote add uberspace your_uberspace_username@your_uberspace_host:repos/example-app.git
```

The uberspace host is something like `longmore.uberspace.de`.

## Create app directory with contents of `main` branch

You can now operate with the remote repository and then later set up a `post-receive` hook to automate the deployment. Let's do this manually first.

To start, ssh into your uberspace. I assume that your repo is in `repos/example-app.git`.

Create a folder for your app:

```bash
# On uberspace
mkdir -p ~/apps/example-app
```

This is where we'll deploy to. To copy the contents of the repo there, run:

```bash
GIT_WORK_TREE="$HOME/apps/example-app" git checkout -f main
```

If you check `apps/example-app` you should see the contents of the repo.

```bash
cd ~/apps/example-app
ls
```

## Create `post-receive` hook to automatically copy changes to app folder

Let's automate this for future pushes by creating a `post-receive` hook:

```bash
# On uberspace
nano ~/repos/example-app.git/hooks/post-receive
```

Then add the following to that file:

```bash
#!/bin/bash
TARGET_DIR="$HOME/apps/example-app"
GIT_DIR="$HOME/example-app.git"

echo "Deploying to $TARGET_DIR..."

# Checkout the latest code to working dir
GIT_WORK_TREE="$TARGET_DIR" git checkout -f main
```

Press Ctrl+X and press enter to confirm. Next time you push to the repo, the contents of the `main` branch will be copied to `~/apps/example-app`.

## Install dependencies

Now inside your app, install everything:

```bash
# On uberspace
uberspace tools version use ruby 3.4 # make sure to use the latest version
bundle lock --add-platform ruby
bundle config set force_ruby_platform true
bundle install
```

The first command makes sure we're using the most recent version of Ruby. The next two commands make sure all dependencies with native modules are compiled using that version. The last command installs the gems.

# 2. Set up the database

Let's continue with setting up the DB.

## Set up MySQL instead of SQLite

Instead of using SQLite, use MySQL/MariaDB. SQLite fails because of dependency version mismatches on uberspace.

So in your `Gemfile` replace the `sqlite3` line with the following:

```gemfile
# On local machine
group :development, :test do
  gem "sqlite3", ">= 2.1"
end
group :production do
  gem 'mysql2', '~> 0.5.2'
end
```

Use the MySQL adapter in `config/database.yml`:

```yaml
production:
  primary: &primary
    adapter: mysql2
    encoding: utf8mb4
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
    username: <%= ENV.fetch("RAILS_DB_USERNAME") %>
    password: <%= ENV.fetch("RAILS_DB_PASSWORD") %>
    host: localhost
    database: mrc_traction_production

  cache:
    <<: *primary
    database: mrc_traction_production_cache
    migrations_paths: db/cache_migrate

  queue:
    <<: *primary
    database: mrc_traction_production_queue
    migrations_paths: db/queue_migrate

  cable:
    <<: *primary
    database: mrc_traction_production_cable
    migrations_paths: db/cable_migrate
```

As we are using environment variables, you have to make sure that they are set. I chose to use `dotenv-rails`:

At the top of your `Gemfile`, add:

```Gemfile
gem 'dotenv-rails', :groups => [:production, :development, :test]
```

Then create environment variables. Locally create an `.env` with empty values:

```bash
RAILS_DB_USERNAME=
RAILS_DB_PASSWORD=
SECRET_KEY_BASE=
```

Then on your Uberspace, create `.env.production` inside `apps/example-app`:

```bash
# On uberspace
RAILS_DB_USERNAME=your_uberspace_username
RAILS_DB_PASSWORD=find_in_~/.my.cnf
SECRET_KEY_BASE=... # output of running `rails secret`
```

Find the MySQL password on your Uberspace in `~/.my.cnf`. The database names have to follow the schema `[username]_*`, see [more info in the manual](https://manual.uberspace.de/database-mysql/#additional-databases).

Populate the `SECRET_KEY_BASE` with the output of `bundle rails secret`. It's important for later.

Then install everything on your local machine, commit the changes, and push them to your existing remote:

```bash
# On local machine
bundle install

git add .
git commit -m "Update database configuration for production"
git push uberspace
```

While running `git push uberspace` you should now see "Deploying to example-app" as a message. Check the contents of `config/database.yml` to make sure it worked.

## Create database tables

With MySQL, you have to create the databases first. On your Uberspace, run:

```bash
# On uberspace
mysql
```

And then create all the databases:

```sql
CREATE DATABASE username_appname_production CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE username_appname_production_cache CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE username_appname_production_queue CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE username_appname_production_cable CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

## Update indices

If you used SQLite locally, you might run into problems where the data type of the foreign key fields (integer) doesn't match the ID fields (bigint). So let's update all tables that use foreign keys.

```bash
# On local machine
rails generate migration ChangeForeignKeysToBigInt
```

And then in that file, add the following migration for every table that uses a foreign key:

```ruby
class ChangeForeignKeysToBigInt < ActiveRecord::Migration[8.0]
  def change
    # Do this for every foreign key
    # Check your db/schema.rb for foreign keys you might have
    remove_foreign_key :sessions, :users
    change_column :sessions, :user_id, :bigint, null: false
    add_foreign_key :sessions, :users
  end
end
```

Then locally, run

```bash
bin/rails db:migrate
```

If everything worked your `db/schema.rb` should have updated. Commit it and push it to your uberspace.

## Check that the DB works

On your uberspace, you can now test if the database connection works. Run:

```bash
# On uberspace
bundle exec rails db:setup RAILS_ENV=production
```

Resolve any errors that might come up. That's the DB setup!

# 3. Create a web backend

Uberspace uses [web backends](https://manual.uberspace.de/web-backends/) to route requests to your application. I chose to run my app on a subdomain, so run:

```bash
uberspace web backend set example-app.myuberspacename.uberspace.de --http --port 45678
```

Note the port – it can be any random number between 1024 and 65535.

# 4. Test run application

Let's test if the application works:

First precompile your assets and (if you haven't yet) migrate your DB:

```bash
# On uberspace
bundle exec rake assets:precompile RAILS_ENV=production
bundle exec rails db:setup RAILS_ENV=production
```

Then run your Rails server in production:

```
RAILS_ENV=production bundle exec rails server -e production -b 0.0.0.0 -p 45678
```

If everything worked you should see the output from Puma. Try navigating to `example-app.myuberspacename.uberspace.de` to see if it worked. The first visit might take a bit longer. Afterwards, quit the app again.

# 5. Using `supervisorctl` to run the application

To make sure the app runs without us, we can use [supervisorctl](https://manual.uberspace.de/daemons-supervisord/) to start and restart it automatically.

Create a new configuration file in `~/etc/services.d/example-app.ini` and add the following:

```ini
[program:example-app]
directory=%(ENV_HOME)s/apps/example-app
command=bundle exec rails server -e production -b 0.0.0.0 -p 45678
environment=RAILS_ENV="production"
startsecs=60
```

Then run:

```bash
supervisorctl reread
supervisorctl update
```

This should start the application. Check with `supervisorctl status` and by visiting your app. If something fails you can debug using `supervisorctl tail example-app`.

# 6. Automate deployment

That's it! Your application is now running on its own. Let's automate the deployment process by updating the hook in `repos/example-app.git/hooks/post-receive` hook:

```bash
# On uberspace

#!/bin/bash
TARGET_DIR="$HOME/apps/example-app"
GIT_DIR="$HOME/repos/example-app.git"

echo "Deploying to $TARGET_DIR..."

# Checkout the latest code to working dir
GIT_WORK_TREE="$TARGET_DIR" git checkout -f main
cd ~/apps/example-app
bundle lock --add-platform ruby
bundle install

export RAILS_ENV=production

echo "Precompiling assets..."
bundle exec rake assets:precompile RAILS_ENV=production

echo "Migrating DB..."
bundle exec rails db:migrate RAILS_ENV=production

LOGFILE="$HOME/apps/example-app/log/deploy.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') Restarting application..." | tee -a "$LOGFILE"
nohup supervisorctl restart example-app >> "$LOGFILE" 2>&1 &
```

Make a change to your local repo and push it to your uberspace:

```bash
# On local machine
git push uberspace main
```

You should then see something like the following output:

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
remote: 2025-05-16 13:18:08 Restarting application...
To uberspace:~/repos/example-app.git
 + 96107e1...efebc48 main -> main (forced update)

```

Check again by visiting the URL. You're done!
