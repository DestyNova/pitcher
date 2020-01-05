# Pitcher

A set of three small games that teach and test absolute pitch recognition.  At least, that's what I hope it will do.

The apps are:

* Incremental piano, which exercises your estimation of pitch height.
* Quick pitch, which exercises your estimation of pitch chroma, and
* Pitch test, which tests you on 20 random notes with no feedback until the end, where you can see your mean absolute semitone error and results for each note.

Try it [here](https://pitcher.overto.eu)!

## TODO
* [X] When button clicked:
  * [X] select random note (0-88) and add to state
  * [X] convert note number to frequency using exponential rule
  * [X] play note
* [X] Render piano keyboard
* [X] Game starts with range of 24 semitones (max(1, 24 - level))
* [X] Render selected range centred on middle C
* [X] Allow selection start to be moved up/down the piano with cursor keys
* [X] Allow clicking a note to move the guess region to centre on that note
* [X] Clicking OK confirms selection and shows either Success or GameOver state
* [X] Success message increments level, disables OK button, enables Next button
* [X] Next button sends Play msg
* [X] Show max score so far + success indicator when confirming the correct answer
* [X] View: show some kind of mastery icon if level > 24? End game or not?
* [X] [Publish via Github-pages](https://pitcher.overto.eu)
* [X] Write article / docs / etc
* [X] Second game: Quick Pitch identification.
* [X] Quick Pitch: Get rid of the select dropdown to choose the target note; instead, make it so you just click the appropriate score badge.
* [ ] Redesign UI to fit better on mobile (maybe make the note list vertical?)

## Future ideas
* Generate several different timbres of note, rather than the same simple triangle+square wave oscillators
* Shepard tone generator to disrupt short-term memory of the target note and reduce the influence of relative pitch between trials?
* Another tab for perfect pitch *production*
  * show randomly placed range on piano
  * give some kind of control of pitch starting at a random continuous note, maybe a knob, or up/down arrows?
  * clicking OK validates whether chosen pitch is within target range
    * if yes, then next level reduces range as before
    * else game over

## Further reading on the topic
* [Rush's 1989 thesis](https://etd.ohiolink.edu/!etd.send_file?accession=osu1216931520&disposition=inline), a good summary of the literature on absolute pitch training up to that time.
