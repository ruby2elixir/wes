# WES
[![Release](http://img.shields.io/github/release/wooga/wes.svg?style=flat-square)](https://github.com/wooga/wes/releases/latest)
[![Build Status](http://img.shields.io/travis/wooga/wes.svg?style=flat-square)](http://travis-ci.org/wooga/wes)
[![Code Climate](http://img.shields.io/badge/code_climate-Erlang_18.0-brightgreen.svg?style=flat-square)](https://travis-ci.org/wooga/wes)

## Introduction
WES is a library that helps you build actor based services in Erlang.

### Actors, Channels, Commands and Reads
An _Actor_ is an isolated state and logic that acts upon this state given
input. An Actor subscribes to one channel at a time. The user interacts with
its actors via Commands and Reads.

A _Channel_ is implemented as an Erlang process that among other things holds
the states of all actors that subscribe to it.

A _Command_ is sent to a channel and is then broadcasted to all actors
subscribing to that channel. Each actor can react to the command by changing
its state. A Command call returns `ok` if all actors handled the message.

A _Read_ is sent directly to one actor. The actor returns a view of its state.

In other words, a channel is a set of actors that acts atomically to commands.
The restrictions of commands and reads make it to easier to keep your code
decoupled. All actors for a channel are persisted periodically and when a
channel stops (without signaling an error).

## Getting Started

### Example Project
[WES bank](https://github.com/anha0825/wes_bank) - Implements a simple bank
account model on top of WES.

## Building Blocks
For each building block (except channels) WES exposes a callback interface to
implement.

### Name Registry
A name registry implementation keeps track of the process each channel is
running in and to which channel an actor is listening. This registry acts as a
lock for a certain channel or actor, preventing it from being started twice.

WES provides some predefined registry implementations:

* `wes_lock_null` - Doesn't lock anything. Can be used to start many copies of
  the same actor.
* `wes_lock_ets` - In-memory, single node lock backed by ETS.
* `wes_locker` - Locker backed registry, for multi-node systems.

### Channels
A channel receives commands and reads. Commands are broad-casted to all actors
that are listening to the channel. Reads are sent to the actor that it is aimed
for. A channel manages the timeouts for itself and for the actors connected to
it.

A WES channel doesn't need its own callback module, as this is a primitive that
is handled internally by WES itself.

#### Error Handling

Any exception that occurs inside a channel will shut the channel down without
saving the actors. When resuming, the channel will have the latest persistent
state of the actors, allowing you to resume from a known state.

If the exception occurred in a command to the channel, the same exception will
be raised from the call to `wes:command/2` or `wes:command/3`.

The stats module will also get a `stop` event with an `{exception, Class,
Reason, Stacktrace}` argument so that individual error statistics can be
tracked.

### Actors
This is where the game logic lives. An actor is off-line (persisted) or listens
to one channel. An actor gets all commands sent to the channel where it lives
and the read events that are sent directly to it. An actor can tell its channel
to stop and can register periodic timeout calls from the channel.

### Actor Persistence
A persistence module implements read and write operations for serialized
actors. This module is typically used to store actor state in databases.

WES provides some predefined persistence implementations:

* `wes_db_null` - Doesn't store anything. Can be used for short lived actors
  that doesn't need to store any persistent state.
* `wes_db_ets` - In-memory, single node storage backed by ETS.
* [`wes_db_s3`](https://github.com/wooga/wes_db_s3) - Amazon AWS S3 backed
  storage (external repository).

### Statistics
A stats implementation gets statistics about what happens in each channel.

WES provides some predefined stats implementations:

* `wes_stats_null` - Doesn't store anything. Can be used when stats are not
  needed.
* `wes_stats_ets` - In-memory stats counters backed by ETS.
