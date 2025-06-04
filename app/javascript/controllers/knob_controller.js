import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "wrapper" ]

  optionChanged(e) {
    const input = e.target
    const value = input.value
    const index = (input.getAttribute("data-index"))
    this.wrapperTarget.style.setProperty("--knob-index", `${index}`);
  }

  sliderChanged(e) {
    const sliderIndex = e.target.value
  }
}


// The slider has a range of 0-4. We can't add day values statically.
// These 0-4 values are used to set the angle via css.
// but, that if the range was simply used to set the value of the radio input.
// OK, what if we get the knob and radio inputs working as expected, then…
// When radio input changes, update the slider
// when the slider changes, update the radio input

// knob need an index, options have the index.
// when option is changed, set i on main component
