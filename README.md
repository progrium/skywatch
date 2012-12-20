# Skywatch

Simple, Unix-oriented alerting system that lets you define checks and
alerts in any language that are then magically run on Heroku.

NoOps! Polyglot! Free monitoring of anything!

## Installation

    $ gem install skywatch

## Usage

The skywatch command manages a directory containing check scripts and
alert scripts. You can make a new directory and let skywatch set it up
for you:

    $ mkdir my-watcher
    $ cd my-watcher
    $ skywatch init

At this point, it will have you authenticate with your Heroku
credentials if you haven't already. Grab a free account if you don't
have one. When you run `skywatch init` authenticated it will create some
directories for you and deploy a Heroku app.

    $ ls
    alerts  checks


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

MIT
