# noflo-automaton
[![Build Status](https://secure.travis-ci.org/kenhkan/noflo-automaton.png?branch=master)](http://travis-ci.org/kenhkan/noflo-automaton) [![Dependency Status](https://gemnasium.com/kenhkan/noflo-automaton.png)](https://gemnasium.com/kenhkan/noflo-automaton) [![NPM version](https://badge.fury.io/js/noflo-automaton.png)](http://badge.fury.io/js/noflo-automaton) [![Stories in Ready](https://badge.waffle.io/kenhkan/noflo-automaton.png)](http://waffle.io/kenhkan/noflo-automaton)

Automate navigation on the web. This component library is built for NoFlo using
Casper.js.

Given a URL and a rule object (structure described below), noflo-automaton
would go through the rule object and try to reach the end, at which point the
automaton would forward the accumulated output to its OUT port with the status
number of 'true'.

If at any point it fails, the automaton would still forward the accumulated
output but with the status number being the rule number in the provided rule
object.

## The Rule Object

To automate web navigation simply requires a list of rules to tell automaton
what to look for, what to do if it is found, and which rule to execute next.
The object is a simple JavaScript object containing an array of rules. It works
virtually the same way as an assembly language does.

### Rule Object API

For each **rule**, the automaton expects:

* **selector**: The CSS3 selector to operate on
* **actions**: An array of actions to perform (see below)
* **conditions**: An array of conditions to test for success before moving on
  (see below)
* **name**: *optional* An identifier so other rules can refer to this rule
* **on-success**: *optional* The next rule to execute upon success. It refers
  to the rule by its name. Automaton scans forward for the name and does not go
  back in history. In other words, automaton will execute the first instance of
  the rules matching the name. If it's `false`, quit the program successfully.
  If it's `true`, the immediately next rule is executed. Default to `true`
* **on-failure**: *optional* The next rule to execute upon failure. The same
  properties of determining the next rule to execute as for `on-success` apply.
* **test-timeout**: *optional* Number of milliseconds to timeout before
  applying 'conditions'. Default to 0 miliseconds (i.e. immediately calling
  `setTimeout()` with `0` milliseconds)
* **retry-timeout**: *optional* Number of milliseconds to timeout before
  retrying upon failure. Default to `0` milliseconds
* **retry-count**: *optional* How many times to retry before giving up? Default
  to no retry (i.e. quit the program with a failure status number)

For each **action** in the actions array:

* **action**: One of [mouse and form
  events](http://www.w3schools.com/jsref/dom_obj_event.asp) without the 'on'
  prefix. It also accepts 'value' which would change the value of an input and
  trigger the 'change' event.
* **selector**: *optional* The element to perform the action on. Default to the
  element specified by the rule selector.

For each **condition** in the conditions array:

* **condition**: The value to match on the element. This is a RegExp string.
  For instance, when `class="page row item"` and `property` is `class`, the
  condition is not going to match with `^row$`. However, it would match with
  `row`.
* **name**: *optional* An identifier for other conditions to refer to this
* **property**: *optional* The attribute name (e.g. 'class') to test.  Default
  to the content of the HTML element
* **selector**: *optional* The selector to test the condition on. Default to
  the element specified by the rule selector.
* **on-success**: *optional* The next condition by its name to test on success.
  If it's `false`, stop testing and assume success. If it's `true`, move on to
  the next condition. Default to `true`
* **on-failure**: *optional* The next condition by its name to test on failure.
  If it's `false`, stop testing and assume failure. If it's `true`, move on to
  the next condition. Default to `false`

### Examples

Click on all the row items and test that all item has the content 'Item' except
the one marked with 'you' as ID.

    [
      {
        "selector": "body #page .row",
        "actions": [
          { "action": "click" },
          { "action": "click", "selector": "body #page .row .item" }
        ],
        "conditions": [
          { "condition": "Item" },
          { "condition": "You", "selector": "body #page .row .item#you" }
        ]
      }
    ]

## Data Structure

The automaton is essentially a looper that ends when there is a failure in
satisfying the provided conditions or when it completes successfully (i.e. no
more rules to apply). Along with the expectation that after each test and rule,
there is a timeout to allow DOM events to fire, the flow must be completely
stateless.

Therefore, each component in the automaton, including the graph
`automaton/automaton` itself, expects the same inbound object, which follows
the protocol of:

* **page**: The DOM element of the page against which all selectors are
  executed.
* **rules**: This is the rule obejct.
* **status**: *internal* This is the current rule's offset in the rule object.
  This is used internally as a counter to refer to the the current rule to be
  applied as well as forwarded to OUT upon completion.
* **counts**: *internal* This is a hash of counters used by some components in
  order to track when to quit upon repeated failures.

On OUT port from the graph `automaton/automaton` it outputs an object following
this protocol:

* **status**: `true` if it's successful. `false` if the provided page or rule
  object is not valid. The position of the rule in the rule object otherwise.
* **error**: *optional* An error object or a string indicating the error
  message if any
* **page**: The DOM element passed to the graph in the beginning
* **rules**: The rule object passed to the graph in the beginning
