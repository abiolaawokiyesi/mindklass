// MindKlass Avatar Engine -- curriculum types.
// Content lives in code so it is versioned, reviewable and instantly deployable
// (no CMS round-trip inside a Worker request). At runtime it is mirrored into D1
// by `npm run kb:seed` so retrieval can happen in SQL if the corpus grows.

export type Chunk = {
  title: string
  body: string
}

export type Worked = {
  prompt: string
  steps: string[]
}

export type Check = {
  q: string
  options?: string[]
  answer: string
  why: string
}

export type Lesson = {
  id: string
  title: string
  minutes: number
  objectives: string[]
  chunks: Chunk[]
  worked: Worked[]
  checks: Check[]
  glossary: { term: string; meaning: string }[]
  misconceptions: { wrong: string; right: string }[]
  /** Short spoken intro the avatar delivers on lesson open. */
  opening: string
  /** Spoken wrap-up / consolidation. */
  closing: string
}

export type Course = {
  id: string
  title: string
  subject: string
  level: string
  accent: string
  blurb: string
  lessons: Lesson[]
}

export const COURSES: Course[] = [
  {
    id: 'math-quadratics',
    title: 'Quadratic Equations',
    subject: 'Mathematics',
    level: 'SS2',
    accent: '#6366f1',
    blurb: 'Factorising, completing the square and the quadratic formula — with the reasoning behind each step.',
    lessons: [
      {
        id: 'mq-1',
        title: 'What a quadratic really is',
        minutes: 12,
        objectives: [
          'Recognise a quadratic equation from its highest power',
          'Explain why a quadratic can have zero, one or two real solutions',
          'Read the turning point and roots from a sketch'
        ],
        chunks: [
          {
            title: 'The defining feature',
            body:
              'A quadratic equation is any equation that can be written as ax squared plus bx plus c equals zero, where a is not equal to zero. The highest power of the unknown is two. That single fact — one squared term and nothing higher — is what separates a quadratic from a linear equation or a cubic.'
          },
          {
            title: 'Why a cannot be zero',
            body:
              'If a were zero the x squared term would vanish and you would be left with bx plus c equals zero, which is a straight line, not a curve. So the condition a not equal to zero is not a technicality: it is what keeps the equation quadratic.'
          },
          {
            title: 'What the graph tells you',
            body:
              'Plot y equals ax squared plus bx plus c and you get a parabola. When a is positive the parabola opens upward like a valley, and the lowest point is the minimum. When a is negative it opens downward like a hill, and the highest point is the maximum. The solutions of the equation are simply where the curve crosses the x axis.'
          },
          {
            title: 'Zero, one or two answers',
            body:
              'Because a parabola can miss the x axis entirely, touch it once, or cut through it twice, a quadratic can have no real solutions, exactly one repeated solution, or two distinct real solutions. This is why you should never assume a quadratic has an answer just because it was written down.'
          }
        ],
        worked: [
          {
            prompt: 'Is 3x squared minus 5x plus 2 equals zero a quadratic? Identify a, b and c.',
            steps: [
              'The highest power of x is two, so yes — it is quadratic.',
              'Match term by term with ax squared plus bx plus c.',
              'a equals 3, b equals negative 5, c equals 2.',
              'Check: a is not zero, so the equation is genuinely quadratic.'
            ]
          },
          {
            prompt: 'Sketch y equals x squared minus 4x plus 5 and state how many real solutions x squared minus 4x plus 5 equals zero has.',
            steps: [
              'a equals 1, which is positive, so the parabola opens upward.',
              'The turning point is at x equals minus b over 2a, which is 4 over 2, so x equals 2.',
              'Substitute x equals 2: y equals 4 minus 8 plus 5, so y equals 1.',
              'The lowest point is (2, 1), which is above the x axis, so the curve never crosses it.',
              'Conclusion: no real solutions.'
            ]
          }
        ],
        checks: [
          {
            q: 'Which of these is NOT a quadratic equation?',
            options: ['x squared plus 3x equals 10', '2x squared equals 8', '5x plus 7 equals 0', 'x squared equals 0'],
            answer: '5x plus 7 equals 0',
            why: 'The highest power there is one, so it is linear. The others all contain an x squared term.'
          },
          {
            q: 'A parabola opens downward. What does that tell you about a, and about the turning point?',
            answer: 'a is negative, and the turning point is a maximum',
            why: 'A negative leading coefficient flips the parabola into a hill shape, so the vertex is the highest point.'
          }
        ],
        glossary: [
          { term: 'Quadratic', meaning: 'An equation whose highest power of the unknown is two.' },
          { term: 'Parabola', meaning: 'The U-shaped or hill-shaped curve produced by a quadratic.' },
          { term: 'Root', meaning: 'A value of x that makes the equation true — where the curve crosses the x axis.' },
          { term: 'Vertex', meaning: 'The turning point of a parabola: its minimum or maximum.' }
        ],
        misconceptions: [
          { wrong: 'Every quadratic has two solutions.', right: 'It can have two, one, or none in the real numbers — it depends on whether the parabola reaches the x axis.' },
          { wrong: 'a can be anything as long as b or c is present.', right: 'If a is zero the squared term disappears and the equation is no longer quadratic.' }
        ],
        opening:
          'Let us start with the one thing that defines a quadratic: the highest power of the unknown is exactly two. Everything else — the shape, the number of answers — follows from that.',
        closing:
          'So a quadratic is a parabola, and its solutions are where that curve meets the x axis. Remember that a parabola can miss the axis, kiss it once, or cut it twice.'
      },
      {
        id: 'mq-2',
        title: 'Solving by factorising',
        minutes: 15,
        objectives: [
          'Factorise a quadratic with a leading coefficient of one',
          'Use the zero product rule correctly',
          'Factorise quadratics where a is not one'
        ],
        chunks: [
          {
            title: 'The zero product rule',
            body:
              'If two numbers multiply to give zero, at least one of them must be zero. That is the entire foundation of solving by factorising. If you can rewrite the quadratic as a product of two brackets equal to zero, you can set each bracket to zero separately and solve two easy linear equations.'
          },
          {
            title: 'Finding the pair',
            body:
              'For x squared plus bx plus c equals zero with a leading coefficient of one, look for two numbers that multiply to give c and add to give b. In x squared plus 5x plus 6, you need two numbers multiplying to 6 and adding to 5 — that is 2 and 3, so the factorised form is (x plus 2)(x plus 3).'
          },
          {
            title: 'Signs do the work',
            body:
              'The signs tell you a lot before you compute anything. If c is positive and b is positive, both numbers are positive. If c is positive and b is negative, both are negative. If c is negative, one number is positive and the other is negative, and the larger one in size takes the sign of b.'
          },
          {
            title: 'When a is not one',
            body:
              'For 2x squared plus 7x plus 3, multiply a and c to get 6, then find two numbers multiplying to 6 and adding to 7 — that is 6 and 1. Split the middle term into 6x plus x, group into pairs, and factor each pair. You get (2x plus 1)(x plus 3). Always check by expanding back.'
          }
        ],
        worked: [
          {
            prompt: 'Solve x squared minus 7x plus 12 equals 0.',
            steps: [
              'We need two numbers multiplying to 12 and adding to negative 7.',
              'Those numbers are negative 3 and negative 4.',
              'Factorise: (x minus 3)(x minus 4) equals 0.',
              'Zero product rule: x minus 3 equals 0 or x minus 4 equals 0.',
              'So x equals 3 or x equals 4.'
            ]
          },
          {
            prompt: 'Solve 2x squared plus 7x plus 3 equals 0.',
            steps: [
              'Multiply a and c: 2 times 3 equals 6.',
              'Find two numbers multiplying to 6 and adding to 7: 6 and 1.',
              'Rewrite the middle term: 2x squared plus 6x plus x plus 3 equals 0.',
              'Group: 2x(x plus 3) plus 1(x plus 3) equals 0.',
              'Factor out the common bracket: (2x plus 1)(x plus 3) equals 0.',
              'So x equals negative one half or x equals negative 3.'
            ]
          }
        ],
        checks: [
          {
            q: 'Factorise x squared plus 2x minus 15.',
            options: ['(x plus 5)(x minus 3)', '(x minus 5)(x plus 3)', '(x plus 15)(x minus 1)', '(x minus 15)(x plus 1)'],
            answer: '(x plus 5)(x minus 3)',
            why: '5 times negative 3 is negative 15 and 5 plus negative 3 is 2. Expanding gives back x squared plus 2x minus 15.'
          },
          {
            q: 'Why can you set each bracket to zero separately?',
            answer: 'Because a product is zero only when at least one factor is zero',
            why: 'That is the zero product rule, and it is what turns one quadratic into two simple linear equations.'
          }
        ],
        glossary: [
          { term: 'Factorise', meaning: 'Rewrite an expression as a product of simpler expressions.' },
          { term: 'Zero product rule', meaning: 'If AB equals 0 then A equals 0 or B equals 0.' },
          { term: 'Expanding', meaning: 'Multiplying out brackets to check your factorised answer.' }
        ],
        misconceptions: [
          { wrong: 'x squared plus 5x plus 6 equals 0 means x equals 5 and x equals 6.', right: 'The numbers in the brackets are 2 and 3; the solutions are x equals negative 2 and x equals negative 3, because each bracket is set to zero.' },
          { wrong: 'You can factorise by just guessing.', right: 'You use the product and sum of a pair of numbers; guessing only works when you already understand that rule.' }
        ],
        opening:
          'Factorising is just reverse multiplication. If you can find the two brackets, the zero product rule does the rest of the work for you.',
        closing:
          'Find the pair, write the brackets, set each bracket to zero. And always expand back to check — it takes three seconds and catches almost every sign error.'
      },
      {
        id: 'mq-3',
        title: 'The quadratic formula and the discriminant',
        minutes: 18,
        objectives: [
          'Apply the quadratic formula accurately',
          'Use the discriminant to predict the number of real roots',
          'Recognise when factorising is the smarter choice'
        ],
        chunks: [
          {
            title: 'The formula',
            body:
              'The quadratic formula says x equals negative b plus or minus the square root of b squared minus 4ac, all divided by 2a. It solves every quadratic, whether or not it factorises neatly. Because it comes directly from completing the square on the general equation, it is not a magic spell you have to memorise blindly.'
          },
          {
            title: 'The discriminant',
            body:
              'The expression under the square root, b squared minus 4ac, is called the discriminant. If it is positive, there are two distinct real roots. If it is zero, there is exactly one repeated root. If it is negative, there are no real roots, because you cannot take the square root of a negative number in the reals.'
          },
          {
            title: 'Choosing your method',
            body:
              'If the discriminant is a perfect square, factorising is faster. If the numbers are awkward, the formula is more reliable than hunting for a pair. Completing the square is best when you need the vertex or a maximum and minimum value, because the completed form shows the turning point directly.'
          },
          {
            title: 'Sign and arithmetic discipline',
            body:
              'Most errors in this topic are not conceptual, they are arithmetic. Write down a, b and c first with their signs, substitute inside a bracket, and keep the whole numerator over 2a. If b is negative, negative b is positive — that single step is where most marks are lost.'
          }
        ],
        worked: [
          {
            prompt: 'Solve 2x squared minus 4x minus 3 equals 0.',
            steps: [
              'Identify a equals 2, b equals negative 4, c equals negative 3.',
              'Discriminant: b squared minus 4ac equals 16 minus 4 times 2 times negative 3 equals 16 plus 24 equals 40.',
              'The discriminant is positive, so there are two distinct real roots.',
              'x equals the quantity 4 plus or minus the square root of 40, all over 4.',
              'The square root of 40 is 2 root 10, so x equals 1 plus or minus root 10 over 2.',
              'Numerically, x is approximately 2.58 or negative 0.58.'
            ]
          },
          {
            prompt: 'How many real roots does x squared plus 2x plus 5 equals zero have?',
            steps: [
              'a equals 1, b equals 2, c equals 5.',
              'Discriminant equals 4 minus 20 equals negative 16.',
              'A negative discriminant means no real roots.',
              'The parabola sits entirely above the x axis.'
            ]
          }
        ],
        checks: [
          {
            q: 'If the discriminant equals 0, how many real solutions are there?',
            options: ['None', 'Exactly one', 'Two', 'Infinitely many'],
            answer: 'Exactly one',
            why: 'The plus or minus part collapses to a single value, giving one repeated root — the parabola just touches the x axis.'
          },
          {
            q: 'For 3x squared plus 6x plus 3 equals 0, what is the discriminant and what does it mean?',
            answer: '0, so there is one repeated root (x equals negative 1)',
            why: '36 minus 4 times 3 times 3 equals 0. The equation factors as 3(x plus 1) squared, so x equals negative 1 twice.'
          }
        ],
        glossary: [
          { term: 'Discriminant', meaning: 'b squared minus 4ac — it tells you how many real roots exist.' },
          { term: 'Repeated root', meaning: 'A single solution counted twice, occurring when the discriminant is zero.' },
          { term: 'Completing the square', meaning: 'Rewriting the quadratic as a perfect square plus a constant, which reveals the vertex.' }
        ],
        misconceptions: [
          { wrong: 'A negative discriminant means I made a mistake.', right: 'It is a valid result: the parabola simply never reaches the x axis, so there are no real roots.' },
          { wrong: 'negative b means b.', right: 'If b is negative 4 then negative b is positive 4. Substituting the sign correctly is the most common source of lost marks.' }
        ],
        opening:
          'This is the tool that never fails you. Even when factorising is impossible, the quadratic formula still finds the roots — and the discriminant tells you what to expect before you start.',
        closing:
          'Check the discriminant first, then substitute carefully with signs. If the discriminant is a perfect square, factorising would have been quicker — but the formula still gets you there.'
      }
    ]
  },
  {
    id: 'phys-newton',
    title: "Newton's Laws of Motion",
    subject: 'Physics',
    level: 'SS1',
    accent: '#0ea5e9',
    blurb: 'Inertia, F equals ma, and action–reaction — explained through everyday motion you can picture.',
    lessons: [
      {
        id: 'pn-1',
        title: 'Inertia: the first law',
        minutes: 13,
        objectives: [
          'State the first law in your own words',
          'Explain inertia using mass',
          'Identify real situations where the law applies'
        ],
        chunks: [
          {
            title: 'The law itself',
            body:
              'Newton\u2019s first law says an object stays at rest, or keeps moving in a straight line at constant speed, unless a resultant external force acts on it. Notice the word resultant: it is the net force, not any single push or pull, that changes motion.'
          },
          {
            title: 'Inertia is not laziness',
            body:
              'The tendency of an object to resist a change in its motion is called inertia, and its measure is mass. A loaded lorry has far more inertia than a bicycle, which is why it needs a longer distance to stop and a longer distance to get going.'
          },
          {
            title: 'Why you lurch forward',
            body:
              'When a bus brakes sharply, your body keeps moving forward even though the bus has slowed. No forward force pushed you — your body simply continued at its previous velocity because no sufficient backward force acted on it yet. The seatbelt then supplies that force.'
          },
          {
            title: 'Frames and friction',
            body:
              'The law is stated for a frame of reference where no net force acts, called an inertial frame. In practice, friction and air resistance are the external forces that quietly remove motion on Earth, which is exactly why motion seems to need constant effort here.'
          }
        ],
        worked: [
          {
            prompt: 'A book rests on a table. Identify the forces and explain why it does not move.',
            steps: [
              'Weight acts downward, equal to mg.',
              'The normal reaction from the table acts upward.',
              'The two forces are equal in size and opposite in direction, so the resultant is zero.',
              'Zero resultant force means no change in motion, so the book stays at rest.'
            ]
          }
        ],
        checks: [
          {
            q: 'A spacecraft drifts at constant velocity far from any star. What is the resultant force on it?',
            options: ['Large and forward', 'Equal to its weight', 'Zero', 'Increasing with speed'],
            answer: 'Zero',
            why: 'Constant velocity means no acceleration, so by the first law the net force must be zero.'
          },
          {
            q: 'Two trolleys are pushed with the same force. One is empty, one is loaded. Which changes motion more easily and why?',
            answer: 'The empty one, because it has less mass and therefore less inertia',
            why: 'Mass is the measure of inertia, so the smaller mass accelerates more for the same force.'
          }
        ],
        glossary: [
          { term: 'Inertia', meaning: 'Resistance to a change in motion, measured by mass.' },
          { term: 'Resultant force', meaning: 'The single net force after combining all forces on a body.' },
          { term: 'Inertial frame', meaning: 'A reference frame in which the first law holds true.' }
        ],
        misconceptions: [
          { wrong: 'Motion requires a continuous force.', right: 'Constant velocity requires zero net force; a force is needed only to change velocity.' },
          { wrong: 'Inertia and weight are the same.', right: 'Inertia is measured by mass and does not change with location; weight is a force and does change with gravity.' }
        ],
        opening:
          'Here is the idea that overturned two thousand years of thinking: motion does not need a push to continue. What needs a push is a change in motion.',
        closing:
          'Inertia is mass in motion terms. If the resultant force is zero, the velocity does not change — it either stays at rest or stays at constant speed in a straight line.'
      },
      {
        id: 'pn-2',
        title: 'F equals ma',
        minutes: 16,
        objectives: [
          'Apply F equals ma to single and combined forces',
          'Separate mass from weight',
          'Resolve a simple two-force problem with friction'
        ],
        chunks: [
          {
            title: 'The second law',
            body:
              'The second law says the resultant force on a body equals its mass times its acceleration, written F equals ma. Acceleration points in the same direction as the resultant force. Double the force and you double the acceleration; double the mass and you halve it for the same force.'
          },
          {
            title: 'Newtons, the unit',
            body:
              'One newton is the force that gives a one kilogram mass an acceleration of one metre per second squared. So the unit itself is built from the equation, which is a useful check: if your answer is not in newtons, you have probably mixed units.'
          },
          {
            title: 'Mass versus weight',
            body:
              'Mass is the amount of matter, measured in kilograms, and it does not change. Weight is the gravitational force on that mass, equal to mg, measured in newtons. On the Moon your mass is unchanged but your weight is about one sixth as large, because g is smaller.'
          },
          {
            title: 'Working with friction',
            body:
              'When friction is present, the resultant force is the applied force minus friction. A 20 newton push against 5 newtons of friction on a 3 kilogram trolley gives a resultant of 15 newtons, and an acceleration of 15 divided by 3, which is 5 metres per second squared.'
          }
        ],
        worked: [
          {
            prompt: 'A 1200 kilogram car accelerates from rest to 20 metres per second in 8 seconds. Find the resultant force.',
            steps: [
              'Acceleration equals change in velocity over time: 20 minus 0, all over 8, equals 2.5 metres per second squared.',
              'Apply F equals ma: F equals 1200 times 2.5.',
              'F equals 3000 newtons, or 3 kilonewtons.',
              'This is the resultant force; if friction is 400 newtons, the engine must supply 3400 newtons.'
            ]
          },
          {
            prompt: 'A 5 kilogram block is pulled with 30 newtons while friction is 10 newtons. Find its acceleration.',
            steps: [
              'Resultant force equals 30 minus 10 equals 20 newtons.',
              'Use a equals F over m: 20 divided by 5.',
              'Acceleration equals 4 metres per second squared, in the direction of the pull.'
            ]
          }
        ],
        checks: [
          {
            q: 'A force of 24 newtons acts on a 6 kilogram mass. What is the acceleration?',
            options: ['0.25 metres per second squared', '4 metres per second squared', '18 metres per second squared', '144 metres per second squared'],
            answer: '4 metres per second squared',
            why: 'a equals F over m equals 24 divided by 6 equals 4.'
          },
          {
            q: 'Your mass is 50 kilograms. What is your weight on Earth, taking g as 10 metres per second squared?',
            answer: '500 newtons',
            why: 'Weight is mg equals 50 times 10 equals 500 newtons. The mass stays 50 kilograms regardless of location.'
          }
        ],
        glossary: [
          { term: 'Acceleration', meaning: 'Rate of change of velocity, in metres per second squared.' },
          { term: 'Newton', meaning: 'The force giving 1 kg an acceleration of 1 metre per second squared.' },
          { term: 'Weight', meaning: 'The gravitational force on a mass, w equals mg.' }
        ],
        misconceptions: [
          { wrong: 'F equals ma means bigger mass always means bigger force.', right: 'For a fixed acceleration, force scales with mass; but a bigger mass under the same force has a smaller acceleration.' },
          { wrong: 'If an object is moving, the force equals ma in the direction of motion.', right: 'The resultant force is in the direction of the acceleration, which may be opposite to the motion — as in braking.' }
        ],
        opening:
          'The second law is the workhorse of mechanics. Find the resultant force, divide by the mass, and you have the acceleration.',
        closing:
          'F equals ma only ever uses the resultant force. Subtract friction first, keep your units in newtons and kilograms, and the direction of the answer is the direction of the net force.'
      }
    ]
  },
  {
    id: 'bio-cell',
    title: 'The Cell',
    subject: 'Biology',
    level: 'SS1',
    accent: '#10b981',
    blurb: 'Organelles, plant versus animal cells, and how substances move across membranes.',
    lessons: [
      {
        id: 'bc-1',
        title: 'Organelles and what they do',
        minutes: 14,
        objectives: [
          'Name the main organelles and their functions',
          'Explain why the cell is called the unit of life',
          'Link structure to function for two organelles'
        ],
        chunks: [
          {
            title: 'The unit of life',
            body:
              'The cell is the smallest structure that can carry out all the activities of life: taking in nutrients, releasing energy, responding, and reproducing. Cell theory says all living things are made of cells, that the cell is the basic unit of structure and function, and that new cells come from existing cells.'
          },
          {
            title: 'The control centre',
            body:
              'The nucleus contains the genetic material, DNA, which carries the instructions for making proteins. It is separated from the cytoplasm by a nuclear membrane with pores, so that instructions can leave but the DNA itself is protected.'
          },
          {
            title: 'Power and protein',
            body:
              'Mitochondria carry out aerobic respiration, releasing energy from glucose as ATP. Ribosomes build proteins by joining amino acids in the order the DNA instructions specify. A cell that does a lot of work, such as a muscle cell, has many mitochondria; a cell that secretes a lot of protein, such as a pancreas cell, has many ribosomes.'
          },
          {
            title: 'Packaging and boundaries',
            body:
              'The endoplasmic reticulum is a network of membranes where proteins and lipids are made and moved. The Golgi apparatus modifies, packages and dispatches them. The cell membrane is a partially permeable phospholipid bilayer that controls what enters and leaves, holding the cell together without making it a sealed box.'
          }
        ],
        worked: [
          {
            prompt: 'A student says muscle cells contain more mitochondria than skin cells. Explain whether this is expected.',
            steps: [
              'Mitochondria release energy through aerobic respiration.',
              'Muscle cells contract repeatedly and need a large, continuous energy supply.',
              'Skin cells are far less metabolically demanding.',
              'So yes: more mitochondria in muscle cells is exactly what structure following function predicts.'
            ]
          }
        ],
        checks: [
          {
            q: 'Which organelle is the site of protein synthesis?',
            options: ['Mitochondrion', 'Ribosome', 'Golgi apparatus', 'Vacuole'],
            answer: 'Ribosome',
            why: 'Ribosomes assemble amino acids into proteins using the instructions copied from DNA.'
          },
          {
            q: 'Why is the cell membrane described as partially permeable rather than impermeable?',
            answer: 'Because it lets some substances through while blocking others',
            why: 'Small molecules such as water and oxygen pass through, while large or charged particles need transport proteins. A fully impermeable membrane would stop the cell feeding itself.'
          }
        ],
        glossary: [
          { term: 'Organelle', meaning: 'A specialised structure inside a cell carrying out a particular job.' },
          { term: 'ATP', meaning: 'The molecule cells use to store and transfer energy short term.' },
          { term: 'Partially permeable', meaning: 'Allowing some substances through but not others.' }
        ],
        misconceptions: [
          { wrong: 'The nucleus makes the proteins.', right: 'The nucleus holds the instructions; ribosomes actually assemble the proteins.' },
          { wrong: 'Mitochondria make energy.', right: 'They release energy from glucose and store it as ATP — energy is converted, never created.' }
        ],
        opening:
          'Think of the cell as a small factory that also happens to be alive. Every organelle has a job, and the shape of each one follows that job.',
        closing:
          'Nucleus for instructions, ribosomes for building, mitochondria for energy, membranes for control. When you meet an unfamiliar cell, ask which of those jobs it needs most — the structure will tell you.'
      },
      {
        id: 'bc-2',
        title: 'Movement across membranes',
        minutes: 15,
        objectives: [
          'Distinguish diffusion, osmosis and active transport',
          'Predict the direction of water movement',
          'Explain why active transport needs energy'
        ],
        chunks: [
          {
            title: 'Diffusion',
            body:
              'Diffusion is the net movement of particles from a region of higher concentration to a region of lower concentration, down a concentration gradient. It is passive, meaning it needs no energy input from the cell, and it continues until the concentrations even out.'
          },
          {
            title: 'Osmosis',
            body:
              'Osmosis is the diffusion of water across a partially permeable membrane, from a dilute solution to a more concentrated one. A plant cell placed in pure water takes in water, the vacuole swells and the cell becomes turgid. The same cell in a strong salt solution loses water and becomes plasmolysed.'
          },
          {
            title: 'Active transport',
            body:
              'Active transport moves substances against the concentration gradient, from low concentration to high. Because this is the opposite of the natural direction, the cell must spend energy from respiration and use carrier proteins. Root hair cells absorbing mineral ions from dilute soil solution are the classic example.'
          },
          {
            title: 'Why the distinction matters',
            body:
              'Diffusion and osmosis are passive and therefore stop when concentrations equalise or when the cell runs out of gradient. Active transport is the only one of the three that can keep accumulating a substance beyond equilibrium, which is why it costs the cell energy.'
          }
        ],
        worked: [
          {
            prompt: 'A potato strip is placed in distilled water for 30 minutes. Predict and explain the change in mass.',
            steps: [
              'The potato cells contain a concentrated cell sap; distilled water has almost no dissolved solute.',
              'Water potential is higher outside, so water enters by osmosis.',
              'The vacuoles swell and the cells become turgid.',
              'Mass increases, until the cell wall prevents further expansion.'
            ]
          }
        ],
        checks: [
          {
            q: 'Which process requires energy from respiration?',
            options: ['Diffusion', 'Osmosis', 'Active transport', 'All of these'],
            answer: 'Active transport',
            why: 'Only active transport moves substances against the concentration gradient, so it must be paid for with energy.'
          },
          {
            q: 'A red blood cell is placed in pure water. Explain what happens.',
            answer: 'Water enters by osmosis, the cell swells and bursts',
            why: 'The cytoplasm is more concentrated than pure water, so water flows in. Animal cells have no cell wall to resist the pressure, so they can burst — this is haemolysis.'
          }
        ],
        glossary: [
          { term: 'Concentration gradient', meaning: 'The difference in concentration between two regions.' },
          { term: 'Turgid', meaning: 'Swollen with water, giving a plant cell support.' },
          { term: 'Plasmolysed', meaning: 'Having lost water so the membrane pulls away from the cell wall.' }
        ],
        misconceptions: [
          { wrong: 'Osmosis moves solute from high to low concentration.', right: 'Osmosis moves water, from a dilute solution towards a more concentrated one. The solute itself does not cross the membrane.' },
          { wrong: 'Diffusion stops because particles stop moving.', right: 'Particles never stop moving; diffusion stops producing a net change once the concentrations are equal.' }
        ],
        opening:
          'Three processes, one question: which way does the movement go, and does it cost the cell anything?',
        closing:
          'Down the gradient and free — diffusion. Water across a membrane, down the gradient and free — osmosis. Against the gradient — that is active transport, and it must be paid for.'
      }
    ]
  },
  {
    id: 'chem-mole',
    title: 'The Mole Concept',
    subject: 'Chemistry',
    level: 'SS2',
    accent: '#f59e0b',
    blurb: 'Moles, molar mass and concentration — the counting system that makes chemistry quantitative.',
    lessons: [
      {
        id: 'cm-1',
        title: 'Counting by weighing',
        minutes: 14,
        objectives: [
          'Define the mole in terms of particles',
          'Use Avogadro\u2019s number correctly',
          'Convert between mass, moles and particles'
        ],
        chunks: [
          {
            title: 'Why a new unit',
            body:
              'Chemists cannot count atoms one at a time, so they count them in batches. The mole is the amount of substance containing 6.02 times 10 to the power 23 particles — Avogadro\u2019s number. It is exactly the same idea as a dozen: a word for a fixed count, chosen so that the arithmetic with masses becomes simple.'
          },
          {
            title: 'Molar mass',
            body:
              'The mass of one mole of a substance in grams equals its relative formula mass, called the molar mass. For water, the relative formula mass is 18, so one mole of water has a mass of 18 grams. That number comes from adding the relative atomic masses: 2 times 1 for hydrogen plus 16 for oxygen.'
          },
          {
            title: 'The central triangle',
            body:
              'Almost every mole calculation uses one relationship: mass equals moles times molar mass. Rearrange it and you get moles equals mass over molar mass. Write it once, understand it once, and the rest is substitution.'
          },
          {
            title: 'Particles to moles',
            body:
              'To go from a number of particles to moles, divide by Avogadro\u2019s number. So 1.204 times 10 to the power 24 atoms is 1.204 divided by 6.02, which is 0.2 times 10 to the power 1 — that is 2 moles.'
          }
        ],
        worked: [
          {
            prompt: 'How many moles are in 44 grams of carbon dioxide, CO2?',
            steps: [
              'Molar mass of CO2 equals 12 plus 2 times 16 equals 44 grams per mole.',
              'moles equals mass over molar mass equals 44 over 44.',
              'So there is exactly 1 mole of CO2.',
              'That is 6.02 times 10 to the power 23 molecules.'
            ]
          },
          {
            prompt: 'What is the mass of 0.25 moles of sodium chloride, NaCl?',
            steps: [
              'Molar mass of NaCl equals 23 plus 35.5 equals 58.5 grams per mole.',
              'mass equals moles times molar mass equals 0.25 times 58.5.',
              'mass equals 14.625 grams.',
              'Check the units: moles times grams per mole leaves grams, which is right.'
            ]
          }
        ],
        checks: [
          {
            q: 'How many moles are in 36 grams of water? (H2O, molar mass 18)',
            options: ['0.5', '2', '18', '36'],
            answer: '2',
            why: 'moles equals mass over molar mass equals 36 over 18 equals 2.'
          },
          {
            q: 'One mole of oxygen gas, O2, contains how many molecules?',
            answer: "6.02 times 10 to the power 23 molecules — but 1.204 times 10 to the power 24 oxygen atoms",
            why: 'A mole always contains Avogadro\u2019s number of formula units. Each O2 molecule holds two oxygen atoms, so the number of atoms doubles.'
          }
        ],
        glossary: [
          { term: 'Mole', meaning: 'The amount of substance containing Avogadro\u2019s number of particles.' },
          { term: 'Molar mass', meaning: 'The mass of one mole of a substance, in grams per mole.' },
          { term: "Avogadro's number", meaning: '6.02 times 10 to the power 23, the number of particles in one mole.' }
        ],
        misconceptions: [
          { wrong: 'A mole is a unit of mass.', right: 'A mole is an amount of particles. Mass comes from moles multiplied by molar mass.' },
          { wrong: 'One mole of O2 has the same number of atoms as one mole of O.', right: 'They have the same number of particles, but O2 particles each contain two atoms, so the atom count differs.' }
        ],
        opening:
          'The mole is just a counter. Once you accept that, the whole topic reduces to one equation you already understand.',
        closing:
          'Mass, moles, particles: any two give you the third. Get the molar mass right first, then substitute — and always check your units.'
      },
      {
        id: 'cm-2',
        title: 'Concentration and solutions',
        minutes: 15,
        objectives: [
          'Calculate concentration in moles per cubic decimetre',
          'Convert between cubic centimetres and cubic decimetres',
          'Relate dilution to a change in concentration'
        ],
        chunks: [
          {
            title: 'Concentration defined',
            body:
              'Concentration in chemistry is usually measured in moles per cubic decimetre, written moles per dm cubed. It tells you how crowded the particles are in a given volume of solution, which is what actually controls reaction rate and the amount that reacts.'
          },
          {
            title: 'The equation',
            body:
              'Concentration equals moles divided by volume in cubic decimetres. If you are given cubic centimetres, divide by 1000 first, because one cubic decimetre is 1000 cubic centimetres. Forgetting that conversion is the single most common error in this topic.'
          },
          {
            title: 'Rearranging for moles',
            body:
              'Multiply both sides by volume and you get moles equals concentration times volume. This is the form you need when a question gives you a volume and a concentration and asks how much substance is present, which is the setup for most titration problems.'
          },
          {
            title: 'Dilution',
            body:
              'Adding water does not change the number of moles of solute, only the volume. So when you dilute, use concentration one times volume one equals concentration two times volume two. Doubling the volume halves the concentration.'
          }
        ],
        worked: [
          {
            prompt: 'What is the concentration when 0.5 moles of sodium hydroxide is dissolved to make 250 cubic centimetres of solution?',
            steps: [
              'Convert volume: 250 cubic centimetres divided by 1000 equals 0.25 cubic decimetres.',
              'Concentration equals moles over volume equals 0.5 over 0.25.',
              'Concentration equals 2 moles per cubic decimetre.',
              'Sanity check: the volume is a quarter of a cubic decimetre, so the concentration should be four times the mole value.'
            ]
          },
          {
            prompt: '50 cubic centimetres of 2 moles per cubic decimetre hydrochloric acid is diluted to 200 cubic centimetres. Find the new concentration.',
            steps: [
              'Use concentration one times volume one equals concentration two times volume two.',
              '2 times 50 equals concentration two times 200.',
              '100 equals 200 times concentration two.',
              'Concentration two equals 0.5 moles per cubic decimetre — the volume quadrupled, so the concentration quartered.'
            ]
          }
        ],
        checks: [
          {
            q: 'What is the concentration of 0.2 moles of solute in 500 cubic centimetres of solution?',
            options: ['0.1 moles per dm cubed', '0.4 moles per dm cubed', '1.0 mole per dm cubed', '4 moles per dm cubed'],
            answer: '0.4 moles per dm cubed',
            why: '500 cubic centimetres is 0.5 cubic decimetres, and 0.2 divided by 0.5 equals 0.4.'
          },
          {
            q: 'You add water to a solution. What happens to the number of moles of solute and to the concentration?',
            answer: 'The moles stay the same; the concentration decreases',
            why: 'Dilution adds solvent only, so the same particles are spread through a larger volume.'
          }
        ],
        glossary: [
          { term: 'Cubic decimetre', meaning: 'A volume unit equal to 1000 cubic centimetres, roughly one litre.' },
          { term: 'Dilution', meaning: 'Reducing concentration by adding more solvent.' },
          { term: 'Titration', meaning: 'A procedure that uses a known concentration to find an unknown one.' }
        ],
        misconceptions: [
          { wrong: 'Concentration is the same as the amount of substance.', right: 'It is amount per volume. 1 mole in one cubic decimetre is far more concentrated than 1 mole in ten cubic decimetres.' },
          { wrong: 'Cubic centimetres can be used directly in the formula.', right: 'The formula expects cubic decimetres; divide cubic centimetres by 1000 first.' }
        ],
        opening:
          'Concentration is about crowding, not quantity. The same number of particles squeezed into less volume is a stronger solution.',
        closing:
          'Concentration equals moles over volume, with volume in cubic decimetres. And remember: diluting changes the volume and the concentration, never the number of moles.'
      }
    ]
  }
]

export const courseIndex = () =>
  COURSES.map((c) => ({
    id: c.id,
    title: c.title,
    subject: c.subject,
    level: c.level,
    accent: c.accent,
    blurb: c.blurb,
    lessonCount: c.lessons.length,
    minutes: c.lessons.reduce((a, l) => a + l.minutes, 0)
  }))

export const findCourse = (id: string) => COURSES.find((c) => c.id === id)
export const findLesson = (lessonId: string) => {
  for (const c of COURSES) {
    const l = c.lessons.find((x) => x.id === lessonId)
    if (l) return { course: c, lesson: l }
  }
  return null
}
