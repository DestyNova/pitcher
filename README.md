# Pitcher

An interactive exercise that teaches perfect pitch recognition. At least, that's what I suspect it will do.

## TODO
* [ ] When button clicked:
  * [ ] select random note (0-88) and add to state
  * [ ] convert note number to frequency using exponential rule
  * [ ] play note
* [ ] Render piano keyboard
* [ ] Game starts with range of 24 semitones (max(1, 24 - level))
* [ ] Render selected range centred on middle C
* [ ] Allow selection start to be moved up/down the piano with cursor keys
* [ ] Allow clicking a note to move the guess region to centre on that note
* [ ] Clicking OK confirms selection and shows either Success or GameOver state
* [ ] Success message increments level, disables OK button, enables Next button
* [ ] Next button sends Play msg
* [ ] View: show some kind of mastery icon if level > 24? End game or not?
* [ ] Publish via Github-pages
* [ ] Write article / docs / etc

## Future ideas
* Another tab for perfect pitch *production*
  * show randomly placed range on piano
  * give some kind of control of pitch starting at a random continuous note, maybe a knob, or up/down arrows?
  * clicking OK validates whether chosen pitch is within target range
    * if yes, then next level reduces range as before
    * else game over
