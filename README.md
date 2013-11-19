# Automate navigation on the web <br/>[![Build Status](https://secure.travis-ci.org/kenhkan/noflo-automaton.png?branch=master)](http://travis-ci.org/kenhkan/noflo-automaton) [![Dependency Status](https://gemnasium.com/kenhkan/noflo-automaton.png)](https://gemnasium.com/kenhkan/noflo-automaton) [![NPM version](https://badge.fury.io/js/noflo-automaton.png)](http://badge.fury.io/js/noflo-automaton) [![Stories in Ready](https://badge.waffle.io/kenhkan/noflo-automaton.png)](http://waffle.io/kenhkan/noflo-automaton)

Given a URL and a rule set (structure described below), noflo-automaton would
go through the rule set and try to reach the end, at which point the automaton
would forward the accumulated output to its OUT port with the status of 'true'.

If at any point it fails, the automaton would still forward the accumulated
output but with the status being the rule number in the provided rule set.


## Why not just CasperJS?

Automaton is a nice abstraction over CasperJS. It provides a consistent
JSON-based API so you could program with this:

    [
      { "action": "start", "url": "http://casperjs.org/" },
      { "action": "title" },
      { "action": "open", "url": "http://phantomjs.org" }
      { "action": "title" }
    ]

Rather than this:

    var casper = require('casper').create();

    casper.start('http://casperjs.org/', function() {
        this.echo(this.getTitle());
    });

    casper.thenOpen('http://phantomjs.org', function() {
        this.echo(this.getTitle());
    });

    casper.run();


## Installation

Casper.js and by extension, Phantom.js, are required. In other words, this
library runs only on a server and not the browser. Check out [Casper.js
documentation](http://docs.casperjs.org/en/latest/installation.html) for
installation instructions.

Once you have these installed, it's just a simple `npm install --save
noflo-automaton`!


## Usage

There are two user modes: CommonJS and NoFlo. CommonJS mode exposes a regular class
for you to run a JavaScript object-based (i.e. parsed JSON) rule set. In NoFlo
  mode, it is a graph in NoFlo that you could connect to your network.

Your JSON rule set 

### CommonJS Mode

In CommonJS mode, you simply create a new automaton and call `run`. Assuming the
JSON file described under the section "Why not just CasperJS" above is
available at `rules.json`:

    var Automaton = require('noflo-automaton');
    var rules = require('./rules.json');

    automaton = new Automaton

A promise is returned.

    promise = automaton.run(json);

    promise.then(function(status, output) {
      if (status === true) {
        console.log('SUCCESS!');
      } else {
        console.log('STOPPED AT ' + status);
      }

      console.log('OUTPUT:');
      console.log(output);

    }, function(error) {
      console.log('FAILED TO SET UP');
      console.log(error);
    });

### NoFlo Mode

To use noflo-automaton, you only need to interface with the
`automaton/automaton` graph, which expects:

* Inport **rules**: This is the rule obejct (see below)
* Inport **options**: *optional* A map of options to be passed to
  [Casper.js](http://docs.casperjs.org/en/latest/modules/casper.html). If
  `verbose` set to true, all log from Casper.js will be printed to
  `console.log`.

Options must be passed in before the **RULES** ports disconnect given that it
is optional.

The graph outputs to the OUT port, with the **status** wrapping as group.
**status** is `null` if successful or the offset of the last executed rule if
failed.

* Outport **out**: The accumulated output from executing all the steps. This is
  a stack of all `console.log` output prefixd with `[output] ` from the remote
  browser. For instance, `[output] {"a":"b"}` would be saved while `{"a":"b"}`
  would not.
* Outport **error**: An error packet if the rule or the options object is not
  valid


## The Rule Set

To automate web navigation simply requires a list of rules to tell automaton
what to look for, what to do if it is found, and which rule to execute next.
The object is a simple JavaScript object (i.e. JSON-like) containing an array
of rules. It works virtually the same way as an assembly language does.

### Rule Set API

#### NOTE: The follow API has not been completely implemented. See issues #9

For each **rule**, the automaton expects:

* **action**: see the `components/runners` directory for available actions
* **selector**: *optional* The element to perform the action on. Some actions
  do not require an element selector, like `open`
* **_name**: *optional* An identifier so other rules can refer to this rule
* **_onSuccess**: *optional* The next rule to execute upon success. It refers
  to the rule by its name. Automaton scans forward for the name and does not go
  back in history. In other words, automaton will execute the first instance of
  the rules matching the name. If it's `false`, quit the program successfully.
  If it's `true`, the immediately next rule is executed. Default to `true`
* **_onFailure**: *optional* The next rule to execute upon failure. The same
  properties of determining the next rule to execute as for `on-success` apply.

### Examples

Click on all the row items and test that all item has the content 'Item' except
the one marked with 'you' as ID.

    [
      { "action": "click", "selector": "body #page .row" },
      { "action": "click", "selector": "body #page .row .item" },
      { "action": "test", "selector": "body #page .row", "value": "Item" },
      { "action": "test", "selector": "body #page .row .item#you", "value": "You" }
    ]


## Data Structure

The automaton is essentially a looper that ends when there is a failure in
satisfying the provided conditions or when it completes successfully (i.e. no
more rules to apply).

Each component in the automaton internal loop expects the same
inbound object, which follows the protocol of:

* **spooky**: This is the SppokyJS object to iterate on. It is created on
  demand.
* **rules**: This is the rule set
* **offset**: This is the current rule's offset in the rule set. This is
  used internally as a counter to refer to the the current rule to be applied
  as well as forwarded to OUT upon completion.
* **counts**: This is a map of counters used by components in order to
  track progress. This is the only state the components are allowed to keep


## Action Runners

At the heart of automaton is the action runners. These are the actual
components applying the rules onto a page. An action runner is simply a
component of this repository that accepts a context object.

The runner checks rather it should act on it by examining `rule.action`, which
is the name of the action as displayed in the rule set. If it is qualified to
handle it, it should act on it and not forward the context object.

On the other hand, if it does not know how to handle it, it should forward the
context object as-is to its OUT port. The runner should also check if the OUT
port is attached before sending.

Runners should attach themselves to either the `automaton/Iterate` component or
other runners. This cascading structure allows certain runners to always take
precedence over others.

Note that action runners do not need to be attached back to the system as the
SpookyJS object is passed by reference in the context object.


## Technologies

Automaton can't be an automaton without:

* [NoFlo](http://noflojs.org/)
* [PhantomJS](http://phantomjs.org/)
* [CasperJS](http://casperjs.org/)
* [SpookyJS](https://github.com/WaterfallEngineering/SpookyJS)

I know,

 .-.
(o o) boo!
| O \
 \   \
  `~~~'
