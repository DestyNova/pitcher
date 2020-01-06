# Pitcher

A set of three small games that teach and test absolute pitch recognition.  At least, that's what I hope it will do.

The apps are:

* Incremental piano, which exercises your estimation of pitch height.
* Quick pitch, which exercises your estimation of pitch chroma, and
* Pitch test, which tests you on a series of random notes with no feedback until the end, where you can see your mean absolute semitone error and results for each note.

Try it [here](https://pitcher.overto.eu)!

## Further reading on the topic
* [Rush's 1989 thesis](https://etd.ohiolink.edu/!etd.send_file?accession=osu1216931520&disposition=inline), a good summary of the literature on absolute pitch training up to that time.
* [Wong's 2018 paper](https://www.biorxiv.org/content/10.1101/355933v1.full.pdf), showing positive results for a small fraction of the experimental group after between 12 and 40 hours of training each.
* [Hedger's 2019 paper](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6759182/) showing impressive results after about 40 hours of training for each student in the experimental group.

## TODO
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
