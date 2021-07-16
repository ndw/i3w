"use strict";

function render_schedule() {
  let options = { stylesheetLocation: "xslt/schedule.sef.json" };
  SaxonJS.transform(options, "async");
}

window.onload = render_schedule;
