#Energy nodes messages

This is a simple Proof of Concept of nodes pub/sub messaging system.
The underlying concept is nodes (`Devices`) that can ask for energy through an AMQP message, then another node (`EnergyNode`) subscribed to the proper exchange, can provide energy to the soliciting node.

Note that nodes has been represented using two different classes just for separation of concerns, but conceptually, both classes are _messenger_ nodes.

`EnergyNode`s _«deliver»_ energy by pusblishing messages to another exchange in the message broker, this could have been done using any other method (like an HTTP Post), but considering a messaging broker was already in place, it was used for simplicity's sake.

## Prerequisites

You'll need to meet the following in order to run the code in this repository:

* A [RabbitMQ](https://www.rabbitmq.com) instance running
* A Ruby environment (tested on 2.2.2, but any modern-ish version should work)

It is recommended to use a gemset to isolate gems used in this PoC.

### Gems

It requires only two gems for runtime:

* `bunny`
* `eventmachine`

And an extra one if you want to run tests

* `mocha`

Gems dependencies are listed in `.gems` and `.gems-test` files. These are to be used with the [dep](https://rubygems.org/gems/dep) gem. If you want to use `dep`, first [get the code](#clone-the-repository), then run the following within the cloned directory:

```
gem install dep
dep install && dep -f .gems-test install
```

Otherwise, you can just `gem install` manually.

## Running the code

### Clone the repository

```
git clone https://github.com/kandalf/energy-nodes-messages && cd energy-nodes-messages
```

If you're using some Ruby manager compatible with the `.ruby-version` config file, such as RVM, copy the sample file:

```
cp ruby-version.sample .ruby-version && cd .
```

Now you can [install necessary gems](#gems) so they get isolated in the right gemset.

### Run the scripts

There are two scripts to make it easier to showcase:

* `bin/energy_nodes`
* `bin/run_devices`

You'll need two terminals, in the first one, run `bin/energy_nodes`, this will start 2 provider nodes by default. You can customize the amount of nodes using the `MAX_NODES` environment variable:

```
[kandalf@funkymonkey energy-nodes-messages]$ MAX_NODES=5 bin/energy_nodes 
[2016-04-03 20:09:18 UTC] Energy Node 94a4bec1 running. Press Ctrl+C to exit
[2016-04-03 20:09:18 UTC] Energy Node 39eb62e1 running. Press Ctrl+C to exit
[2016-04-03 20:09:18 UTC] Energy Node 188c27f7 running. Press Ctrl+C to exit
[2016-04-03 20:09:18 UTC] Energy Node d0637593 running. Press Ctrl+C to exit
[2016-04-03 20:09:18 UTC] Energy Node 7a5bf228 running. Press Ctrl+C to exit
```

In the second terminal, run `bin/run_devices`, this will start 2 devices by default. You can customize the number of devices using the `MAX_DEVICES` environment variable:

```
[kandalf@funkymonkey energy-nodes-messages]$ MAX_DEVICES=3 bin/run_devices 
[2016-04-03 20:11:37 UTC] [855b681e] Discharging... 100%
[2016-04-03 20:11:37 UTC] [c4958687] Discharging... 100%
[2016-04-03 20:11:37 UTC] [b314f5dc] Discharging... 100%
```

Devices will start consuming their energy until they reach their 20% and then will request energy until they're full again.

```
[kandalf@funkymonkey energy-nodes-messages]$ MAX_DEVICES=1 bin/run_devices
[2016-04-03 20:19:34 UTC] [f3afffcc] Discharging... 100%
[2016-04-03 20:19:35 UTC] [f3afffcc] Discharging... 97%
[2016-04-03 20:19:36 UTC] [f3afffcc] Discharging... 94%
...
[2016-04-03 20:20:02 UTC] [f3afffcc] Discharging... 24%
[2016-04-03 20:20:03 UTC] [f3afffcc] Discharging... 21%
[2016-04-03 20:20:03 UTC] Charging... 34%
[2016-04-03 20:20:04 UTC] Charging... 47%
[2016-04-03 20:20:05 UTC] Charging... 63%
[2016-04-03 20:20:06 UTC] Charging... 77%
```

EnergyNodes will provide energy upon devices requests.

```
[kandalf@funkymonkey energy-nodes-messages]$ bin/energy_nodes
[2016-04-03 20:19:23 UTC] Energy Node a98b939e running. Press Ctrl+C to exit
[2016-04-03 20:19:23 UTC] Energy Node 4591bab8 running. Press Ctrl+C to exit
[2016-04-03 20:20:03 UTC] Delivering energy from node 4591bab8 to f3afffcc
[2016-04-03 20:20:04 UTC] Delivering energy from node 4591bab8 to f3afffcc
```

### Run the tests

The code is tested using `minitest` form the Ruby core library and `mocha` for mocks and stubs.
Make sure you have [installed the necessary gems](#gems), then you can run all tests:

```
rake test
```

Or you can run individual tests with the ruby interpreter:

```
ruby test/device_test.rb
```

