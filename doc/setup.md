# App Setup

## Dependencies

* Ruby 2.2.2
* PostgreSQL 9.x
* A [MyUSA](https://alpha.my.usa.gov/) account
* An SMTP server (`production` mode only)

## Installation

C2 is a fairly typical Rails application, so the setup is straightforward:

1. Run

    ```bash
    git clone https://github.com/18F/C2.git
    cd C2

    # Will print "DONE" if successful. NOTE: This will delete any existing records in your C2 database.
    ./script/bootstrap
    ```

1. [Register an application on MyUSA](https://alpha.my.usa.gov/applications/new) that provides the `email` scope. You will also need to set the 'Redirect uri' field to [your_domain]/auth/myusa/callback. For example, http://localhost:3000/auth/myusa/callback.
    * Note that the MyUSA app will need to be whitelisted on their end if you need other people to log into it. This matters for staging servers more than local development, so you may not need to worry about it.
1. Add the required `MYUSA_*` values in your [`.env`](../.env.example).

Per [the Twelve-Factor guidelines](http://12factor.net/config), all necessary configuration should be possible through environment variables. See [`.env.example`](../.env.example) for the full list.

### Troubleshooting

#### Can't create or connect to database

* Check that PostgreSQL is running
* Set the `DATABASE_URL` variable in [`.env`](../.env.example) to match your setup

## Starting the application

```bash
./bin/rails s
open http://localhost:3000
```

To include the background jobs (which include sending emails), run using `foreman start -p 3000`.

### Viewing the mailers

As emails are sent, they will be visible at http://localhost:3000/letter_opener. If you are working on an email mailer/template, you can view all of them at http://localhost:3000/mail_view/.

## Running tests

### PhantomJS

You will need to install [PhantomJS](http://phantomjs.org/download.html) and
have it in your PATH. This is used for javascript and interface testing.

### Running the entire suite once

```bash
./bin/rspec
```

### Running tests as corresponding files are changed

```bash
bundle exec guard
```

### Checking for security vulnerabilities

```bash
gem install brakeman
brakeman
```

or just [visit the project on Gemnasium](https://gemnasium.com/18F/C2).
