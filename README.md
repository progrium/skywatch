# Skywatch (alpha)

A simple alerting system that lets you define checks and alerts in any
language that are then magically run on Heroku. Nagios can go cry in a
corner.

NoOps! Polyglot! Free monitoring of anything!

## Installation

    $ gem install skywatch

## Usage / Quickstart

It's a fairly powerful tool. Run `skywatch --help` to see a list of
subcommands. Here is the quickest way to something interesting:

    $ mkdir demo && cd demo   # make a directory for your scripts
    $ skywatch init           # this will fail and require Heroku auth
    $ skywatch init           # run again, after logged in
    $ skywatch enable check example    # enable the example check script
    $ skywatch deploy         # everything is shipped to Heroku
    $ skywatch monitor        # watch it run

## Features

 * Lets you monitor or assert anything at any frequency
 * Scriptable alerts (email, sms, tweet, etc)
 * Runs in the cloud on Heroku for free
 * Completely automated deployment
 * Easily monitor activity logs in real-time
 * Enable / disable checks or alerts
 * No flapping! It just doesn't happen.
 * Entire system is in self-contained CLI tool
 * Simple enough for personal use, powerful enough for commercial use
 * Can be used for building adaptive systems?

## What the hell is this amazing thing??

**tl;dr, skywatch is a tool to run repeating check scripts on
Heroku. It's the simplest idea wrapped into a convenient utility.**

Skywatch is a command-line utility that manages checking and alerting
scripts used by a small (50 lines) watcher service. Skywatch deploys these
scripts and the service on Heroku where they can run and monitor
anything from the cloud for free.

The watcher service runs check scripts that can assert anything at any
frequency. If a check script returns a non-zero exit status, it will
fire any enabled alert scripts, passing it the output of the check
script. Alert scripts can then act on this assertion failure, such as
send email, SMS, or webhook.

The check script will continue to run and potentially fail, but the
alert script only runs once if it ran without error. Only until a reset signal
is sent will it be ready to fire the alert again for any failed check
script. In this way, alerts work like [clip
indicators](http://help.adobe.com/en_US/audition/cs/using/WS58a04a822e3e5010548241038980c2c5-7f93.html)
in the audio recording world. They turn on once any clipping happens and
remain on until you manually reset them.

You manage your scripts locally with the skywatch command, or by hand
since they're just files in directories. When you want to deploy script
changes, toggle enabled scripts, or reset the alert state, you can run a
skywatch command and it will handle pushing changes to Heroku for you.

## Getting Started

The skywatch command manages a directory containing check scripts and
alert scripts. You can make a new directory and let skywatch set this up
for you:

    $ mkdir skywatch-demo
    $ cd skywatch-demo
    $ skywatch init

It will have you authenticate with your Heroku credentials if you
haven't already. [Grab a free account if you don't have
one.](https://api.heroku.com/signup) When you run `skywatch init`
authenticated it will create some example alerts and checks, then deploy
an empty watcher to Heroku. None of the checks or alerts are enabled by
default. See the scripts it set up by just running `skywatch` from the
directory:

    $ skywatch
      Checks for fathomless-crag-3169
        example                  every 30s        disabled
        skywatch_watchers        every 3600s      disabled
      Alerts for fathomless-crag-3169
        email            disabled

Take a look at all the files in the directory. Checks and alerts are nothing
more than scripts. Checks have a naming convention of `<interval>.<name>`,
and enabling and disabling is just setting the execute bit on the
scripts. There's nothing the `skywatch` command does that you can't
easily do by hand. It just happens to be terribly convenient.

    $ skywatch edit alert email

This will open your editor and you can see the example email alert
script is using SendGrid. In fact, when you ran `skywatch init`, you
were set up with a free SendGrid starter addon for 600 emails a day. So
let's try it by putting your email address in the `TO` variable of the
script. Now enable the alert:

    $ skywatch enable alert email

Let's create a new check script in bash that fails so we can get the
alert.

    $ skywatch create check failure_test 30

The last argument is the interval. Intervals are always in seconds. All
this did was create a new file under the `checks` directory with a
little bit of boiler plate. Let's replace its contents with this:

    #!/usr/bin/env bash
    echo "Oh no, a failed check."
    exit 255

Enable the check and then deploy:

    $ skywatch enable check failure_test
    $ skywatch deploy

It's going to move some files around and then deploy to Heroku. It keeps
a staging directory called `.skywatch`, which is a Git repo used to push
to Heroku. It automatically adds this to a `.gitignore` file, so you can
version your scripts with Git and not worry about this implementation
detail.

Once it's finished, you might want to run monitor to see how it went and
what's going on. This is just tailing the Heroku logs of the watcher
service:

    $ skywatch monitor

You can run this whenever to see what it's doing. You'll probably see
that it triggered the alert. Go check your email! That will be the only
email you get, regardless of whether the check starts to work again and
then fail again. No flapping. You have to manually reset:

    $ skywatch reset

This should cause another alert email within 30 seconds. And of course,
you can tear everything down with destroy:
  
    $ skywatch destroy

This destroys the Heroku app and the `.skywatch` directory. It doesn't
touch your scripts at all. In fact, you can run `skywatch init` again if
you'd like. 

The source code to all this is terribly simple. [The watcher service is
only about 50 lines of Ruby.](https://github.com/progrium/skywatch/blob/master/lib/skywatch/watcher/watcher.rb) Everything else is just file operations.
In fact, the little state it maintains is kept in file metadata. For how
automated it is, skywatch has to be one of the simplest monitoring services
ever.

## Writing Check Scripts

Check scripts are any executable script using the shebang to define the
interpreter. Heroku has most common languages built-in to its Cedar
stack, so feel free to use Python, Perl, Ruby, whatever. I like bash.

The only conventions of check scripts are the interval-in-the-filename and that a non-zero exit status will fire the alerts. Any output of the check script will be piped into STDIN of the alert script, so try be verbose but not too
verbose.

If you're using bash, it's a good idea to use `set -e` so any failed
subcommand will bubble up. Here's an example check script:

    #!/usr/bin/env bash
    set -e
    curl --trace-ascii --silent --fail http://example.com

## Writing Alert Scripts

Like check scripts, alert scripts can be written in any language. Also,
like check scripts, the exit status is important. If an alert script
exit status is non-zero, it will run again with the next failure of the check
script. 

The alert script is given the output of the check script via STDIN. It's
also given 2 arguments. The first is the name of the check script. The
second is the exit status of the failed check script. Here's an example
alert script:

    #!/usr/bin/env bash
    TO=foobar@example.com
    SUBJECT="[skywatch] $1"
    BODY=`echo -e "Failure with status $2:\n\n$(cat)"`
    set -e
    curl \
      -X 'POST' \
      -F "api_user=$SENDGRID_USERNAME" \
      -F "api_key=$SENDGRID_PASSWORD" \
      -F "to=$TO" \
      -F "subject=$SUBJECT" \
      -F "text=$BODY" \
      -F "from=$TO" \
      --silent --fail "https://sendgrid.com/api/mail.send.json"

The output of an alert script is ignored. It might be a good idea to log
the output of failed alert scripts. You'd then be able to see it via
`skywatch monitor`. Sounds like a contribution idea.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

MIT
