\version "2.22.0"

\include "frame-engraver.ily"

\score {
  <<
    \new Staff {
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
    }
  >>
}

\score {
  <<
    \new Staff {
      \relative {
        \once \override Frame.extender-length = #8
        \frameStart c'8[ d e \frameEnd f] s2
      }
    }
    \new Staff {
      \relative {
        \once \override Frame.extender-length = #8
        \frameStart c'8[ d e \frameEnd f] s2
      }
    }
  >>
}

\layout {
  \context {
    \Global
    \grobdescriptions #all-grob-descriptions
  }
  \context {
    \Voice
    \consists \Frame_engraver
  }
}
