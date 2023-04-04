\version "2.22.0"

%% the following two definitions create custom properties, on the model of `define-grob-properties.scm'
%% thanks, Harm and Arnold

#(define (define-grob-property symbol type? description)
  (if (not (equal? (object-property symbol 'backend-doc) #f))
      (ly:error (G_ "symbol ~S redefined") symbol))

  (set-object-property! symbol 'backend-type? type?)
  (set-object-property! symbol 'backend-doc description)
  symbol)

#(map
  (lambda (x)
    (apply define-grob-property x))

  `(
    (extender-length ,number? "length of continuation line in frame")
    (extra-padding ,pair? "extra room on left and right of frame")
  ))

%% based on regression test `scheme-text-spanner.ly'
%% Thanks, Mike

#(define-event-class 'frame-event
   'span-event)

#(define frame-types
   '(
     (FrameEvent
      . ((description . "Used to signal where frames start and stop.")
         (types . (general-music frame-event span-event event))
         ))
     ))

#(set!
  frame-types
  (map (lambda (x)
         (set-object-property! (car x)
                               'music-description
                               (cdr (assq 'description (cdr x))))
         (let ((lst (cdr x)))
           (set! lst (assoc-set! lst 'name (car x)))
           (set! lst (assq-remove! lst 'description))
           (hashq-set! music-name-to-property-table (car x) lst)
           (cons (car x) lst)))
       frame-types))

#(set! music-descriptions
       (append frame-types music-descriptions))

#(set! music-descriptions
       (sort music-descriptions alist<?))

#(define (frame-stencil grob)
  (let* ((elts (ly:grob-object grob 'elements))
         (extender-length (ly:grob-property grob 'extender-length))
         (box-padding (ly:grob-property grob 'padding))
         (extra-padding (ly:grob-property grob 'extra-padding))
         (padding-L (car extra-padding))
         (padding-R (cdr extra-padding))
         (height (ly:axis-group-interface::height grob))
         (mid-height (* 0.5 (interval-length height)))
         (axis-group-width (ly:axis-group-interface::width grob))
         (axis-group-width (coord-translate axis-group-width (cons padding-L padding-R)))
         (stencil (ly:make-stencil '() axis-group-width height))
         (extender (make-line-stencil 0.3 0 0 extender-length 0)))

    (set! stencil (box-stencil stencil 0.3 box-padding))
    (set! extender
      (ly:stencil-combine-at-edge extender X RIGHT
        (grob-interpret-markup grob (markup #:arrow-head X RIGHT #t))
        -0.2))
    (set! extender (ly:stencil-translate-axis extender (- (cdr height) mid-height) Y))
    (set! stencil (ly:stencil-combine-at-edge stencil X RIGHT extender -0.2))

    stencil))

#(define (frame-stub::width grob)
  (let* ((elts (ly:grob-object grob 'elements))
         (frame (ly:grob-object grob 'frame))
         (direction (ly:grob-property grob 'direction))
         (box-padding (ly:grob-property frame 'padding))
         (extra-padding (ly:grob-property frame 'extra-padding))
         (padding-L (car extra-padding))
         (padding-R (cdr extra-padding))
         (extender-length (ly:grob-property frame 'extender-length))
         (correction 1) ;; length adjustment for right end.  TODO--
                        ;; will be calculated from offset of arrow/extender
                        ;; length of arrow, extra space before next element
         (axis-group-width (ly:axis-group-interface::width grob))
         (axis-group-width (coord-translate axis-group-width (cons padding-L padding-R))))

  (if (eq? direction LEFT)
      (cons (- (car axis-group-width) 0.3 box-padding) (car axis-group-width))
      (cons (cdr axis-group-width) (+ (cdr axis-group-width) extender-length 0.3 box-padding correction)))))

% https://extending-lilypond.readthedocs.io/en/latest/properties-types.html#new-grob-type
#(define (define-grob! grob-name grob-entry)
   (set! all-grob-descriptions
         (cons ((@@ (lily) completize-grob-entry)
                (cons grob-name grob-entry))
               all-grob-descriptions)))

#(define-grob!
  'Frame
  `(
    (extra-padding . (0 . 0))
    (padding . 0.8)
    (stencil . ,frame-stencil)
    (meta . ((class . Spanner)
             (interfaces . (line-interface))))))

#(define-grob!
  'FrameStub
  `(
    (X-extent . ,frame-stub::width)
    (Y-extent . ,ly:axis-group-interface::height)
    (meta . ((class . Item)
             (object-callbacks . ((pure-Y-common . ,ly:axis-group-interface::calc-pure-y-common)
                                  (pure-relevant-grobs . ,ly:axis-group-interface::calc-pure-relevant-grobs)))
             (interfaces . ())))))

#(define (add-bound-item spanner item)
   (if (null? (ly:spanner-bound spanner LEFT))
       (ly:spanner-set-bound! spanner LEFT item)
       (ly:spanner-set-bound! spanner RIGHT item)))

frameEngraver =
#(lambda (context)
   (let ((span '())
         (stub '())
         (event-drul (cons '() '())))

     `((listeners
         (frame-event .
           ,(lambda (engraver event)
             (if (= START (ly:event-property event 'span-direction))
                 (set-car! event-drul event)
                 (set-cdr! event-drul event)))))

       (acknowledgers
         (note-column-interface .
           ,(lambda (engraver grob source-engraver)
             (if (ly:spanner? span)
               (begin
                   (ly:pointer-group-interface::add-grob span 'elements grob)
                   (add-bound-item span grob)))
             (if (ly:item? stub)
                   (ly:pointer-group-interface::add-grob stub 'elements grob))))
         (script-interface .
           ,(lambda (engraver grob source-engraver)
             (if (ly:spanner? span)
                 (ly:pointer-group-interface::add-grob span 'elements grob))
             (if (ly:item? stub)
                   (ly:pointer-group-interface::add-grob stub 'elements grob))))
         (dynamic-interface .
           ,(lambda (engraver grob source-engraver)
             (if (ly:spanner? span)
                 (ly:pointer-group-interface::add-grob span 'elements grob))
             (if (ly:item? stub)
                   (ly:pointer-group-interface::add-grob stub 'elements grob))))
         (inline-accidental-interface .
           ,(lambda (engraver grob source-engraver)
             (if (ly:spanner? span)
                 (ly:pointer-group-interface::add-grob span 'elements grob))
             (if (ly:item? stub)
                   (ly:pointer-group-interface::add-grob stub 'elements grob)))))

       (process-music .
         ,(lambda (trans)
           (if (ly:stream-event? (cdr event-drul))
               (if (null? span)
                   (ly:warning "No start to this box.")
                   (ly:engraver-announce-end-grob trans span (cdr event-drul))))
           (if (ly:stream-event? (car event-drul))
               (begin (set! span (ly:engraver-make-grob trans 'Frame (car event-drul)))
                      (set! stub (ly:engraver-make-grob trans 'FrameStub (car event-drul)))
                      (ly:grob-set-object! stub 'frame span)
                      (ly:grob-set-property! stub 'direction LEFT)
                      (set-car! event-drul '())))
           (if (ly:stream-event? (cdr event-drul))
               (begin (set! stub (ly:engraver-make-grob trans 'FrameStub (cdr event-drul)))
                      (ly:grob-set-property! stub 'direction RIGHT)
                      (ly:grob-set-object! stub 'frame span)))))

       (stop-translation-timestep .
         ,(lambda (trans)
             (set! stub '())
             (if (ly:stream-event? (cdr event-drul))
                 (begin
                   (set-cdr! event-drul '())
                   (set! span '()))))))))

frameStart =
#(make-span-event 'FrameEvent START)

frameEnd =
#(make-span-event 'FrameEvent STOP)
