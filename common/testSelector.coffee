###
  Given a Spooky instance and a selector, test for selector's existence. Die if
  it doesn't exist; do nothing otherwise

  @param {Spooky} spooky The SpookyJS object
  @param {string} selector The selector to test
  @param {number} step The step number to output on failure
###
module.exports = (spooky, selector, step) ->
  spooky.then [{ selector: selector, step: step }, ->
    # Don't do anything on success
    @waitForSelector selector, (->), =>
      @die "Selector #{selector} does not exist", step
  ]
