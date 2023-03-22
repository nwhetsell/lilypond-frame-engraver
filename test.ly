\version "2.22.0"

\include "frameEngraver3.ly"

\relative c'' {
  \override Stem.transparent = ##t
  \override Beam.transparent = ##t
  \once \override Frame.extender-length = #8
  \frameStart dis'8[ e f \frameEnd ges] s2
  \once \override Frame.extender-length = #11
  \frameStart d,8[ e f \frameEnd g] s2
  s2
  \once \override Frame.extender-length = #3.5
  \frameStart fis'8[ bes,, aes, \frameEnd e'']
}

\layout {
  \context {
    \Global
    \grobdescriptions #all-grob-descriptions
  }
  \context {
    \Voice
    \consists \frameEngraver
  }
}
