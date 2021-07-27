// Make a couple of passes to collect info. Assumption: no
// author speaks for more than one affiliation in any given
// program.

let success = false;
let authors = { };
let talks = { };

document.querySelectorAll("h2.Speakers").forEach(function(speakers) {
  // There are no talks this year with multiple affiliations for
  // different authors, so we're just going to ignore that case
  let affil = speakers.querySelector("span.affil");
  if (affil) {
    affil = affil.innerHTML;
  } else {
    affil = undefined;
  }
  speakers.querySelectorAll("a.biolink").forEach(function (anchor) {
    let href = anchor.getAttribute("href");
    let speaker = anchor.querySelector("span.SpeakerName").innerHTML;
    authors[speaker] = {
      "affil": affil,
      "href": href
    };
  });
});

document.querySelectorAll("div.ProgramEvent").forEach(function(item) {
  let day = item.querySelector("span.Day").innerHTML;
  let dtstart = item.querySelector("span.timestart").innerHTML;
  let dtend = item.querySelector("span.timeend").innerHTML;
  let title = item.querySelector("h2.EventTitle").innerHTML;
  let blurb = item.querySelector("p.blurb").innerHTML.replace(/\s+/g, " ");

  const talk = {
    "day": day,
    "dtstart": dtstart,
    "dtend": dtend,
    "title": title,
    "blurb": blurb,
    "authors": []
  };

  let speakers = item.querySelectorAll("h2.Speakers a.biolink span.SpeakerName");
  if (speakers) {
    speakers.forEach(function(name) {
      talk.authors.push(name.innerHTML);
    });      
  }

  talks[`${day}/${dtstart}`] = talk;
});

// Populate the table
let table = document.querySelector("#schedule");
let rownum = 1;
let colid = {};
table.querySelectorAll("tr").forEach(function (row) {
  let colnum = 1;
  let rowid = undefined;
  row.querySelectorAll("th,td").forEach(function (td) {
    if (td.tagName === "TH" && td.getAttribute("id")) {
      if (colnum === 1) {
        rowid = td.getAttribute("id");
      } else {
        colid[colnum] = td.getAttribute("id");
      }
    }

    let slot = td.getAttribute("data-slot");
    if (slot) {
      if (slot in talks) {
        success = true; // Assume it all worked if we got this far!

        if (rowid && colnum in colid) {
          td.setAttribute("headers", `${rowid} ${colid[colnum]}`);
        }

        let talk = talks[slot];
        // We're using the title as a cheap and cheerful tooltip, so
        // make sure we strip out the markup.
        let blurb = talk.blurb.replace(/<[^>]+>/g, '');
        let html = "<span class='title' title='" + blurb + "'>";
        html += talk.title + "</span>";

        if (talk.authors.length == 0) {
          td.classList.add("lb");
        }

        talk.authors.forEach(function(author, index) {
          if (index === 0) {
            html += "—﻿";
          } else {
            html += ", ";
          }

          let details = authors[author];
          if (details && details.href) {
            html += "<a href='" + details.href + "' ";
            if (details.affil) {
              html += "title='" + details.affil + "' ";
            }
            html += ">" + author + "</a>";
          } else {
            html += "<span ";
            if (details && details.affil) {
              html += "title='" + details.affil + "' ";
            }
            html += ">" + author + "</span>";
          }
        });
        td.innerHTML = html;
      } else {
        td.classList.add("none");
        td.innerHTML = "No talk scheduled.";
      }
    }

    rownum += 1;
    if (td.getAttribute("colspan")) {
      colnum += parseInt(td.getAttribute("colspan"));
    } else {
      colnum += 1;
    }
  });
});

// Now setup the interactive schedule functionality

let OFSHOURS = 0;
let OFSMINUTES = 0;
let CLOCK24 = false;
const ROCKVILLE_OFFSET = 4;

function adjustOffset(item) {
  let tz = item.options[item.selectedIndex].value;
  let pos = tz.indexOf(":");
  let hours = tz.substring(0, pos);
  let minutes = tz.substring(pos+1);
  OFSHOURS = parseInt(hours) + ROCKVILLE_OFFSET;
  OFSMINUTES = parseInt(minutes);

  if (OFSHOURS > 0) {
    document.querySelector("#clock24").checked = true;
    CLOCK24 = true;
  } else {
    document.querySelector("#clock24").checked = false;
    CLOCK24 = false;
  }

  document.querySelectorAll("time").forEach(adjustTime);
}

function adjustClock24(item) {
  CLOCK24 = item.checked;
  document.querySelectorAll("time").forEach(adjustTime);
}

function adjustTime(item) {
  let timez = item.getAttribute("datetime");
  // We assume timez is in ISO 8601 format
  let hours = timez.substring(11,13);
  let minutes = timez.substring(14, 16);

  hours = parseInt(hours) + OFSHOURS;
  minutes = parseInt(minutes) + OFSMINUTES;

  while (minutes >= 60) {
    hours += 1;
    minutes -= 60;
  }

  let plusday = "";
  if (hours >= 24) {
    plusday = "<br />(the next day)";
    hours -= 24;
  }

  let ampm = 'am';
  if (!CLOCK24 && hours >= 12) {
    if (hours > 12) {
      hours -= 12;
    }
    ampm = 'pm';
  }

  if (CLOCK24) {
    hours = hours.toString().padStart(2, "0");
  } else {
    hours = hours.toString().padStart(2, " ");
  }

  minutes = minutes.toString().padStart(2, "0");

  let timel = hours + ":" + minutes;
  if (!CLOCK24) {
    timel = timel + ampm;
  }

  if (hours == 0 && minutes == 0) {
    timel = "midnight";
    plusday = "";
  }

  if (hours == 12 && minutes == 0) {
    if (CLOCK24) {
      timel = "midday";
    } else {
      timel = "noon";
    }
    plusday = "";
  }

  item.innerHTML = timel + plusday;
}

let timezone = document.querySelector("#tz");
timezone.addEventListener('change', function() {
  adjustOffset(this);
}, false);

let clock = document.querySelector("#clock24");
clock.addEventListener('change', function() {
  adjustClock24(this);
}, false);

document.querySelectorAll("time").forEach(adjustTime);

// Finally, turn it all on if we succeeded
if (success) {
  let link = document.querySelector("#schedlink");
  link.innerHTML = "🌐 <a href='#schedule'>Interactive schedule-at-a-glance</a>";
  link.style.display = "block";
  let sched = document.querySelector("#schedule");
  sched.style.display = "block";
}
