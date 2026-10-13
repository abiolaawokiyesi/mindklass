#!/usr/bin/env python3
"""
SAT course — BATCH 2 of 4: Part 3, SAT Math (modules 3A-3F).

Appends six units to the existing SAT-Y1 course injected by batch 1.
Numbering continues from unit 7, so these become units 8-13.

Remaining:
  Batch 3 - Parts 4-9: strategy, vocabulary, Desmos, diagnostics,
            question bank structure, full-length practice tests
  Batch 4 - Parts 10-18: study plans, score-improvement programmes,
            test day, mindset, dashboard, live learning, resources,
            final review, after the SAT
"""
import json
import sys

SRC = "assets/app.js"

def q(question, options, answer, why=None):
    d = {"q": question, "o": options, "a": answer}
    if why:
        d["why"] = why
    return d

UNITS = [
# ===========================================================================
{
"id": "sat3a", "n": 8, "title": "Math Foundations",
"mins": 55, "icon": "Calculator",
"summary": "How SAT Math is structured, calculator and Desmos strategy, mental-maths shortcuts, fractions and percentages, ratios, units and estimation.",
"keyWords": ["Student-produced response", "Desmos", "Ratio", "Unit conversion", "Estimation", "Modelling"],
"sections": [
{"art": "chart", "h": "SAT Math Question Types", "p": [
"SAT Math gives you two modules of 22 questions in 35 minutes each — about 95 seconds per question, noticeably more generous than the Reading and Writing sections. Use that time; rushing Math is rarely necessary and usually costly.",
"Roughly three quarters of questions are multiple choice. The remaining quarter are student-produced responses, where you type your own answer into a box rather than choosing from options. There are no answer choices to work backwards from, and no partial credit.",
"Student-produced responses have strict formatting rules worth learning now rather than discovering on test day: no commas in large numbers, no percent signs, no units. Fractions and decimals are both accepted. If a decimal doesn't terminate, give at least four digits — truncated or rounded both work, but three digits may be marked wrong.",
"Negative answers are allowed in these boxes; answers with a mix of a whole number and a fraction are not. Write 5/2 or 2.5, never 2 1/2, which the system reads as 21/2."]},
{"art": "steps", "h": "Calculator Rules and Strategy", "p": [
"The calculator is permitted on every Math question on the digital SAT — the old no-calculator module is gone. Desmos is built into the Bluebook app, and you may also bring your own approved calculator.",
"Permission is not obligation. Reaching for a calculator to compute 40% of 200 wastes more time than doing it in your head, and every unnecessary keystroke is a chance to mistype. The strongest scorers use the calculator selectively, not constantly.",
"Use it for: messy arithmetic, graphing to find intersections, checking a result you're unsure of. Skip it for: simple arithmetic, algebraic manipulation, anything where setting up the expression is the actual difficulty."]},
{"art": "build", "h": "Desmos Fundamentals", "p": [
"Desmos turns many algebra questions into reading exercises. Type an equation and it graphs instantly; type two and the intersection point is a click away.",
"Four moves cover most of what you need. To solve an equation, graph each side separately and read the intersection. To find zeros or roots, graph the expression and click where it crosses the x-axis. To solve a system, graph both equations and click the intersection. To handle a table of values, enter it as a table and let Desmos fit a line.",
"Unit 12 covers Desmos in depth. For now, open it in Bluebook and get comfortable with typing equations, because fluency here is worth real points.",
"One caution: Desmos gives you a picture, not an interpretation. It will happily show you a graph that answers a question you weren't asked."]},
{"art": "target", "h": "Mental Maths and Estimation", "p": [
"A handful of conversions should be automatic: 1/2 = 50%, 1/4 = 25%, 1/5 = 20%, 1/3 ≈ 33.3%, 3/4 = 75%. Recognising these instantly saves time on percentage and ratio questions throughout the section.",
"Percentage increase and decrease are worth internalising as multipliers rather than two-step calculations. Increasing by 20% means multiplying by 1.2. Decreasing by 20% means multiplying by 0.8. Two successive 10% increases multiply by 1.21, not 1.2 — compounding is regularly tested.",
"Estimation is a checking tool, not a solving tool. Before entering an answer, ask whether it is roughly the right size. If a question asks for a percentage and you have 340, something has gone wrong."]},
{"art": "law", "h": "Ratios, Proportions and Units", "p": [
"A ratio compares parts; a fraction compares a part to the whole. If the ratio of boys to girls is 3:2, then boys are 3/5 of the class, not 3/2. Confusing these two is one of the most common ratio errors on the test.",
"Set up proportions as equal fractions and cross-multiply. Keep the same quantity in the same position on both sides — miles over hours on the left means miles over hours on the right, never hours over miles.",
"Unit conversion questions are almost always solvable by writing the conversion as a fraction and cancelling. To convert 5 metres per second to kilometres per hour, multiply by 3600 seconds per hour and by 1 kilometre per 1000 metres; the seconds and metres cancel, leaving 18 km/h.",
"Always check what unit the answer requires. A question giving data in minutes and asking for an answer in hours is testing whether you noticed."]},
{"art": "read", "h": "Mathematical Modelling", "p": [
"Modelling questions describe a real situation in words and ask you to represent it algebraically. The skill is translation, not computation.",
"Work phrase by phrase. A starting amount becomes a constant. A rate of change per unit becomes a coefficient on the variable. 'Total' signals addition, 'each' or 'per' signals multiplication, 'less than' signals subtraction with the order reversed.",
"A gym charges a £30 joining fee plus £15 per month: C = 15m + 30. The joining fee is fixed, so it stands alone; the monthly rate attaches to the number of months.",
"Once you have the equation, sanity-check it by substituting a simple value. At m = 0, cost should be £30. If your equation gives something else, the translation is wrong before any arithmetic begins."]}],
"check": [
q("On a student-produced response, how should you enter two and a half?", ["2 1/2", "5/2 or 2.5", "2.50%", "2,5"], 1, "Mixed numbers are misread; 2 1/2 is interpreted as 21/2."),
q("Is a calculator allowed on SAT Math?", ["Only in module two", "On every question", "Only on the harder module", "Never"], 1, "The digital SAT permits a calculator throughout; the no-calculator module was removed."),
q("If the ratio of boys to girls is 3:2, boys make up what fraction of the class?", ["3/2", "2/3", "3/5", "2/5"], 2, "Ratios compare parts; the whole is 3 + 2 = 5."),
q("Decreasing a value by 20% means multiplying by:", ["0.2", "0.8", "1.2", "-20"], 1, "The remaining 80% is the multiplier."),
q("A gym charges £30 to join plus £15 monthly. Which models total cost?", ["C = 30m + 15", "C = 45m", "C = 15m + 30", "C = 15(m + 30)"], 2, "The fixed fee is a constant; the monthly rate attaches to m.")]
},
# ===========================================================================
{
"id": "sat3b", "n": 9, "title": "Algebra",
"mins": 65, "icon": "Percent",
"summary": "Linear equations and inequalities, systems, slope and intercepts, equivalent expressions, and translating word problems into linear models.",
"keyWords": ["Linear equation", "Slope", "y-intercept", "System", "Inequality", "Equivalent expression"],
"sections": [
{"art": "law", "h": "Linear Equations in One Variable", "p": [
"Solving means isolating the variable while keeping both sides balanced: whatever you do to one side, do to the other. Undo operations in reverse order — addition and subtraction first, then multiplication and division.",
"Distribute before combining. In 3(x + 4) = 24, expand to 3x + 12 = 24, then subtract and divide. Attempting shortcuts before distributing is where careless errors cluster.",
"Some questions ask not for x but for an expression containing it — 'what is the value of 3x + 1?' Solve for x, then answer the question actually asked. Solving correctly and then answering the wrong question is a surprisingly common way to lose a point you had earned.",
"Watch for equations with no solution or infinitely many. If the variables cancel and you're left with a false statement like 3 = 5, there is no solution. If you're left with a true statement like 4 = 4, every value works."]},
{"art": "chart", "h": "Slope, Intercepts and Linear Functions", "p": [
"Slope-intercept form, y = mx + b, is the workhorse of SAT algebra. m is the slope — the rate of change — and b is the y-intercept, the value when x is zero.",
"Slope is the change in y divided by the change in x between any two points on the line. A positive slope rises left to right; a negative slope falls. A horizontal line has slope zero; a vertical line has undefined slope.",
"In a word problem, slope is always the 'per' quantity: cost per item, metres per second, degrees per hour. The intercept is the starting value before anything changes. Identifying which number in a scenario is which is often the entire question.",
"Parallel lines have equal slopes. Perpendicular lines have slopes that are negative reciprocals — if one is 2/3, the other is -3/2."]},
{"art": "build", "h": "Systems of Linear Equations", "p": [
"A system asks for the values satisfying two equations at once — graphically, the point where the lines cross. Three methods are available and worth having all three.",
"Substitution suits systems where one variable is already isolated. Elimination suits systems where adding or subtracting the equations cancels a variable cleanly. Graphing in Desmos suits everything else, and is often fastest on the digital test.",
"Some questions never require solving. If two equations describe parallel lines — same slope, different intercept — there is no solution. If they describe the same line, there are infinitely many. Recognising this from the coefficients alone saves considerable time.",
"When a question asks for x + y rather than x and y separately, adding the two equations directly often produces the answer in one step."]},
{"art": "mark", "h": "Inequalities", "p": [
"Inequalities follow the same rules as equations with one critical exception: multiplying or dividing both sides by a negative number reverses the direction of the sign. Forgetting this is the single most common inequality error.",
"On a number line, a filled circle means the endpoint is included (≤ or ≥); an open circle means it is excluded (< or >).",
"Systems of inequalities describe a region rather than a point. Graphing in Desmos shades the region automatically, which makes 'which point satisfies both' questions almost trivial.",
"Word problems signal inequalities with phrases like 'at least' (≥), 'at most' (≤), 'no more than' (≤) and 'more than' (>). Translate these carefully; 'at least 5' includes 5."]},
{"art": "steps", "h": "Equivalent Expressions and Manipulation", "p": [
"Many questions ask which expression is equivalent to another. The reliable approach is to simplify both and compare, but there is a faster check: substitute a convenient number such as x = 2 into the original and into each option, and eliminate anything that doesn't match.",
"Avoid substituting 0 or 1 — they make too many expressions coincidentally equal and eliminate nothing.",
"When rearranging a formula to isolate a different variable, treat every other letter as a constant and apply the same balancing rules. Solving A = lw for w gives w = A/l.",
"Common manipulations worth automating: combining like terms, factoring out a common factor, and expanding a product of two binomials."]},
{"art": "read", "h": "Word Problems and Linear Models", "p": [
"Translate one phrase at a time rather than attempting the whole sentence at once. Define your variable explicitly in writing — 'let x = number of hours' — before doing anything else. Undefined variables are how students end up solving for the wrong quantity.",
"'Is', 'are', 'was' and 'gives' all become the equals sign. 'More than' and 'increased by' become addition. 'Less than' reverses the order: '5 less than x' is x - 5, not 5 - x.",
"After solving, reread the question. If you defined x as hours but the question asks for minutes, one more step remains.",
"Check your answer against the original scenario rather than against your own equation — if the equation was mis-set-up, checking against it will confirm an error rather than catch it."]}],
"check": [
q("When solving an inequality, when must you flip the sign?", ["When adding a negative", "When multiplying or dividing by a negative", "When subtracting", "Never"], 1, "Only multiplication or division by a negative reverses direction."),
q("In y = mx + b, what does b represent?", ["The slope", "The rate of change", "The value of y when x = 0", "The x-intercept"], 2, "b is the y-intercept, the starting value."),
q("Two equations describe lines with the same slope but different intercepts. The system has:", ["One solution", "No solution", "Infinitely many solutions", "Two solutions"], 1, "Parallel lines never intersect."),
q("A line has slope 2/3. A line perpendicular to it has slope:", ["2/3", "3/2", "-3/2", "-2/3"], 2, "Perpendicular slopes are negative reciprocals."),
q("'5 less than x' translates to:", ["5 - x", "x - 5", "5x", "x/5"], 1, "'Less than' reverses the order of subtraction."),
q("When testing equivalent expressions by substitution, which value is a poor choice?", ["x = 2", "x = 3", "x = 1", "x = 5"], 2, "0 and 1 make too many expressions coincidentally equal.")]
},
# ===========================================================================
{
"id": "sat3c", "n": 10, "title": "Advanced Math",
"mins": 70, "icon": "Zap",
"summary": "Quadratics in every form, factoring, the quadratic formula, exponential growth and decay, polynomials, rational and radical expressions, function notation and transformations.",
"keyWords": ["Quadratic", "Factoring", "Vertex", "Discriminant", "Exponential", "Function notation", "Transformation"],
"sections": [
{"art": "law", "h": "Quadratic Expressions and Factoring", "p": [
"A quadratic has the form ax² + bx + c. Factoring rewrites it as a product of two binomials, which immediately reveals where the expression equals zero.",
"To factor x² + bx + c, find two numbers that multiply to c and add to b. For x² + 7x + 12, the numbers are 3 and 4, giving (x + 3)(x + 4).",
"Three patterns recur often enough to memorise: the difference of squares, a² - b² = (a + b)(a - b); and the two perfect square trinomials, a² + 2ab + b² = (a + b)² and a² - 2ab + b² = (a - b)².",
"Always check for a common factor first. 2x² + 10x + 12 factors much more easily after pulling out the 2."]},
{"art": "build", "h": "Solving Quadratic Equations", "p": [
"Three methods, each with its moment. Factoring is fastest when the numbers are friendly. Completing the square is what converts to vertex form. The quadratic formula always works.",
"The quadratic formula gives x = (-b ± √(b² - 4ac)) / 2a. Memorise it; it is not supplied on the test.",
"The discriminant, b² - 4ac, tells you the number of real solutions before you solve. Positive means two real solutions, zero means exactly one, negative means none. Questions asking 'for what value of k does this have exactly one solution' are discriminant questions in disguise — set b² - 4ac = 0.",
"On the digital test, graphing in Desmos and reading the x-intercepts is frequently the fastest route to the solutions."]},
{"art": "chart", "h": "Graphs of Quadratics and the Three Forms", "p": [
"Every quadratic graphs as a parabola. It opens upward when a is positive and downward when a is negative.",
"Each of the three forms hands you a different fact for free. Standard form, ax² + bx + c, gives the y-intercept as c. Factored form, a(x - p)(x - q), gives the x-intercepts as p and q. Vertex form, a(x - h)² + k, gives the vertex as (h, k).",
"The exam very often asks which form 'displays' a particular feature. The answer is whichever form states it without further work — vertex form for the minimum or maximum, factored form for the zeros.",
"The axis of symmetry runs vertically through the vertex, at x = -b/2a. The vertex is the maximum point on a downward parabola and the minimum on an upward one — which is what makes it the answer to 'greatest height' and 'lowest cost' questions."]},
{"art": "target", "h": "Exponential Functions, Growth and Decay", "p": [
"Linear growth adds a fixed amount each period; exponential growth multiplies by a fixed factor. Recognising which a scenario describes is often the whole question.",
"Exponential functions take the form y = a·bˣ, where a is the starting value and b is the growth factor. If b is greater than 1 the quantity grows; if b is between 0 and 1 it decays.",
"Convert percentages to factors carefully. Growth of 5% per year means b = 1.05. Decay of 5% means b = 0.95. Doubling means b = 2; halving means b = 0.5.",
"Exponent rules are assumed knowledge: multiplying powers of the same base adds the exponents, dividing subtracts them, a power raised to a power multiplies them, a negative exponent means a reciprocal, and anything to the power zero is 1."]},
{"art": "steps", "h": "Polynomials, Rational and Radical Expressions", "p": [
"A polynomial's zeros are the values making it equal zero — the x-intercepts of its graph. If (x - 3) is a factor, then 3 is a zero and the graph crosses at x = 3. This connection between factors, zeros and intercepts is tested constantly.",
"Rational expressions are fractions containing variables. Simplify by factoring numerator and denominator and cancelling common factors. Any value making the denominator zero is excluded from the domain, and questions often ask exactly this.",
"Radical equations are solved by isolating the radical and squaring both sides — but squaring can introduce extraneous solutions that don't satisfy the original equation. Always substitute your answers back to check.",
"Fractional exponents and radicals are the same thing: x^(1/2) is √x, and x^(2/3) is the cube root of x squared."]},
{"art": "mark", "h": "Function Notation and Transformations", "p": [
"f(x) is a name, not multiplication. f(3) means substitute 3 for x. If f(x) = 2x + 1, then f(3) = 7.",
"Composite functions work from the inside out. f(g(2)) means evaluate g(2) first, then feed the result into f.",
"Transformations follow rules worth memorising because they are counterintuitive in one direction. f(x) + k shifts the graph up by k. f(x + k) shifts it left by k — inside the brackets moves the opposite way to what the sign suggests. -f(x) reflects across the x-axis; f(-x) reflects across the y-axis.",
"A question giving a table of values and asking for f(a) is simply asking you to read the table. Some function questions require no algebra at all."]}],
"check": [
q("The discriminant of a quadratic is negative. How many real solutions?", ["Two", "One", "None", "Infinitely many"], 2, "A negative discriminant means no real solutions."),
q("Which form of a quadratic displays the vertex directly?", ["ax² + bx + c", "a(x - p)(x - q)", "a(x - h)² + k", "All forms"], 2, "Vertex form gives the vertex as (h, k)."),
q("A population decays 5% per year. The growth factor b is:", ["0.05", "0.5", "0.95", "1.05"], 2, "95% remains each year."),
q("f(x + 3) shifts the graph of f:", ["Right 3", "Left 3", "Up 3", "Down 3"], 1, "Changes inside the brackets move the graph opposite to the sign."),
q("If (x - 4) is a factor of a polynomial, then:", ["4 is a y-intercept", "4 is a zero of the polynomial", "-4 is a zero", "The graph never crosses the x-axis"], 1, "Factors give zeros, which are the x-intercepts."),
q("After solving a radical equation, why substitute answers back?", ["To check arithmetic only", "Squaring can create extraneous solutions", "It is required for marks", "To find the domain"], 1, "Squaring both sides can introduce solutions the original equation rejects.")]
},
# ===========================================================================
{
"id": "sat3d", "n": 11, "title": "Problem Solving and Data Analysis",
"mins": 60, "icon": "BarChart2",
"summary": "Rates and percentages, scatterplots and lines of best fit, mean, median and spread, probability, two-way tables, sampling and statistical reasoning.",
"keyWords": ["Unit rate", "Scatterplot", "Line of best fit", "Median", "Standard deviation", "Probability", "Margin of error"],
"sections": [
{"art": "chart", "h": "Rates, Unit Rates and Percentages", "p": [
"A unit rate expresses a quantity per single unit — miles per hour, cost per item. Dividing to reach 'per one' makes comparison between options straightforward, which is what most rate questions are really asking.",
"Percentage change is (new − old) ÷ old, expressed as a percentage. The denominator is always the original value. Using the new value there is a frequent and costly error.",
"Percent of versus percent more than are different questions. 120 is 150% of 80, but it is 50% more than 80.",
"Successive percentage changes multiply rather than add. A 20% rise followed by a 20% fall gives 1.2 × 0.8 = 0.96 — a net 4% loss, not a return to the start. This scenario appears regularly."]},
{"art": "build", "h": "Scatterplots and Lines of Best Fit", "p": [
"A scatterplot shows the relationship between two variables. A line of best fit summarises the trend, and questions typically ask you to interpret its slope, predict a value, or identify the point furthest from it.",
"Interpret the slope in context, always with units. A line of best fit with slope 3 on a plot of study hours against test score means roughly 3 additional points per additional hour.",
"Predicting within the range of the data is interpolation and is reasonably reliable. Predicting beyond it is extrapolation and is not — a question asking whether a prediction is trustworthy is usually testing this distinction.",
"Correlation is not causation. Two variables moving together does not establish that one causes the other, and answer options claiming causation from observational data are almost always wrong."]},
{"art": "law", "h": "Mean, Median, Mode and Spread", "p": [
"The mean is the average, the median is the middle value when ordered, and the mode is the most frequent. For an even count, the median is the average of the two middle values.",
"The mean is pulled by outliers; the median is not. A single very large value drags the mean upward while leaving the median untouched. Questions about which measure 'better represents' skewed data are testing exactly this.",
"Range is the largest value minus the smallest. Standard deviation measures how spread out the values are around the mean — you will never be asked to calculate it, only to compare two datasets and say which has the greater spread. More tightly clustered means smaller standard deviation.",
"Adding a constant to every value shifts the mean and median by that constant but leaves the standard deviation unchanged, since the spread hasn't altered."]},
{"art": "steps", "h": "Probability and Two-Way Tables", "p": [
"Probability is favourable outcomes divided by total possible outcomes, always between 0 and 1.",
"Two-way tables organise data by two categories at once, and nearly every SAT probability question uses one. The entire difficulty lies in identifying the correct denominator from the wording.",
"'The probability that a randomly selected student is left-handed' uses the grand total as the denominator. 'The probability that a randomly selected girl is left-handed' uses only the total number of girls. Read the conditioning phrase carefully — it tells you which row or column you are confined to.",
"Underline the group the question restricts you to before doing any arithmetic. Nearly all errors here are denominator errors, not calculation errors."]},
{"art": "read", "h": "Sampling, Surveys and Statistical Reasoning", "p": [
"A conclusion can only be generalised to the population the sample was actually drawn from. A survey of one school's students supports claims about that school, not about students nationally.",
"Random selection is what permits generalisation. A sample that is self-selected — people who chose to respond — is biased, and questions frequently ask you to identify why a conclusion is unreliable.",
"Establishing cause requires a randomised experiment with a control group. An observational study can only establish association. Answer options claiming causation from a survey are wrong by construction.",
"Margin of error describes the precision of an estimate. A result of 45% with a 3% margin of error means the plausible range is 42% to 48%. Larger samples produce smaller margins of error."]}],
"check": [
q("Percentage change is calculated as:", ["(new − old) ÷ new", "(new − old) ÷ old", "new ÷ old", "old ÷ new"], 1, "The original value is always the denominator."),
q("A 20% increase followed by a 20% decrease results in:", ["No net change", "A 4% net loss", "A 4% net gain", "A 40% loss"], 1, "1.2 × 0.8 = 0.96."),
q("Which measure is most affected by a single extreme outlier?", ["Median", "Mode", "Mean", "Range of the middle half"], 2, "The mean is pulled toward outliers; the median resists them."),
q("'The probability a randomly selected girl is left-handed' uses which denominator?", ["The grand total", "The total number of girls", "The total left-handed students", "The total number of boys"], 1, "The conditioning phrase restricts you to that row or column."),
q("A survey finds ice cream sales and drowning rates rise together. This shows:", ["Ice cream causes drowning", "An association, not causation", "Drowning causes ice cream sales", "The data is invalid"], 1, "Observational data establishes association only."),
q("Adding 5 to every value in a dataset changes:", ["The standard deviation only", "The mean and median, not the spread", "Nothing", "The spread only"], 1, "Shifting all values leaves the spread unchanged.")]
},
# ===========================================================================
{
"id": "sat3e", "n": 12, "title": "Geometry and Trigonometry",
"mins": 60, "icon": "Layers",
"summary": "Lines and angles, triangles and similarity, the Pythagorean theorem and special right triangles, circles, area and volume, coordinate geometry and right-triangle trigonometry.",
"keyWords": ["Similar triangles", "Pythagorean theorem", "Special right triangles", "Arc", "Radian", "SOH-CAH-TOA", "Midpoint"],
"sections": [
{"art": "law", "h": "Lines, Angles and Triangles", "p": [
"Angles on a straight line sum to 180°; angles around a point sum to 360°. When two lines cross, vertical angles are equal.",
"When a transversal crosses parallel lines, corresponding angles are equal, alternate angles are equal, and co-interior angles sum to 180°. In practice, every angle in such a diagram is either equal to a given angle or supplementary to it — which reduces most of these questions to one subtraction.",
"A triangle's interior angles sum to 180°. An exterior angle equals the sum of the two non-adjacent interior angles.",
"Isosceles triangles have two equal sides and two equal base angles; equilateral triangles have three 60° angles. Recognising an isosceles triangle in a diagram often supplies the missing angle immediately."]},
{"art": "steps", "h": "Similarity, Congruence and Right Triangles", "p": [
"Similar triangles have equal angles and proportional sides. Two triangles sharing two equal angles are similar, which is the most common route into these questions.",
"With similar triangles, set up a proportion matching corresponding sides and cross-multiply. Getting the correspondence right matters more than the arithmetic — pair the sides opposite equal angles.",
"The Pythagorean theorem, a² + b² = c², applies to right triangles only, with c the hypotenuse — always the longest side, opposite the right angle.",
"Two special right triangles recur so often they are worth memorising. A 45-45-90 triangle has sides in ratio 1 : 1 : √2. A 30-60-90 triangle has sides in ratio 1 : √3 : 2, with the shortest side opposite the 30° angle. Recognising these skips the calculation entirely.",
"The Pythagorean triples 3-4-5 and 5-12-13, and their multiples such as 6-8-10, appear frequently."]},
{"art": "chart", "h": "Circles", "p": [
"Circumference is 2πr and area is πr². The diameter is twice the radius — questions supplying the diameter and expecting you to halve it are common and easy to rush past.",
"Arc length and sector area are fractions of the whole, determined by the central angle over 360°. A 90° sector is one quarter of the circle.",
"Radians are an alternative angle measure: π radians equals 180°, so a full circle is 2π radians. Convert by multiplying by 180/π or π/180.",
"The equation of a circle centred at (h, k) with radius r is (x − h)² + (y − k)² = r². If a question presents an expanded equation, completing the square recovers the centre and radius.",
"An inscribed angle is half the central angle subtending the same arc."]},
{"art": "build", "h": "Area, Volume and Coordinate Geometry", "p": [
"Area formulas for rectangles, triangles, circles and trapezoids, and volume formulas for prisms, cylinders, cones, spheres and pyramids, are provided in the reference sheet on test day — but looking them up costs time, so knowing the common ones cold is still worth it.",
"Volume scaling is regularly tested and regularly missed. Doubling every dimension of a solid multiplies the volume by 8, not 2, because volume scales with the cube of the scale factor. Area scales with the square.",
"On the coordinate plane, the distance between two points is the Pythagorean theorem applied to the horizontal and vertical differences. The midpoint is simply the average of the x-coordinates and the average of the y-coordinates.",
"Many coordinate geometry questions become trivial by sketching the points, and Desmos will plot them for you."]},
{"art": "target", "h": "Right-Triangle Trigonometry", "p": [
"SOH-CAH-TOA covers everything the SAT requires. Sine is opposite over hypotenuse, cosine is adjacent over hypotenuse, tangent is opposite over adjacent.",
"'Opposite' and 'adjacent' are defined relative to the angle in question, not fixed to particular sides. Reorienting for a different angle changes which side is which.",
"One relationship appears repeatedly: the sine of an angle equals the cosine of its complement. Since the two non-right angles in a right triangle sum to 90°, sin(x) = cos(90° − x). Questions stating sin(a) = cos(b) are telling you a + b = 90°.",
"Ensure your calculator is in degree mode unless a question explicitly uses radians. This single setting has cost many students several questions at once."]}],
"check": [
q("A 30-60-90 triangle has sides in the ratio:", ["1 : 1 : √2", "1 : √3 : 2", "3 : 4 : 5", "1 : 2 : 3"], 1, "The shortest side is opposite the 30° angle."),
q("Doubling every dimension of a cylinder multiplies its volume by:", ["2", "4", "6", "8"], 3, "Volume scales with the cube of the scale factor."),
q("If sin(a) = cos(b), then a and b are:", ["Equal", "Complementary, summing to 90°", "Supplementary, summing to 180°", "Both 45°"], 1, "Sine and cosine of complementary angles are equal."),
q("The equation (x − 2)² + (y + 3)² = 25 describes a circle with centre:", ["(2, 3)", "(−2, 3)", "(2, −3)", "(−2, −3)"], 2, "The signs inside the brackets reverse."),
q("π radians is equal to:", ["90°", "180°", "270°", "360°"], 1, "A full circle is 2π radians."),
q("In a right triangle, the hypotenuse is always:", ["The vertical side", "The shortest side", "The side opposite the right angle", "The base"], 2, "It is opposite the right angle and always longest.")]
},
# ===========================================================================
{
"id": "sat3f", "n": 13, "title": "SAT Math Practice and Error Analysis",
"mins": 55, "icon": "TrendingUp",
"summary": "Practising math by difficulty, mixed and timed sets, Desmos-based drilling, adaptive practice, and the math error log that turns mistakes into points.",
"keyWords": ["Mixed practice", "Timed sets", "Desmos drilling", "Careless errors", "Math error log"],
"sections": [
{"art": "steps", "h": "Working Through the Difficulty Levels", "p": [
"Progress from easy to medium to hard, untimed before timed. The purpose of easy questions is not the points; it is making your setup process automatic so that harder questions have your full attention available.",
"Practise topic by topic first, then mix topics. Topic practice teaches the method; mixed practice teaches recognition — deciding which method a question calls for. Both are necessary, and students who only ever do topic sets are often blindsided by a real module.",
"Keep a running list of question types you consistently get right. Confidence built on evidence is more durable than encouragement."]},
{"art": "build", "h": "Desmos-Based Practice", "p": [
"Set aside dedicated practice specifically for Desmos. Fluency with the tool is a genuine score lever, and it is entirely learnable in a few sessions.",
"Drill four things until automatic: solving an equation by graphing both sides and reading the intersection; finding zeros by clicking x-intercepts; solving systems by graphing both lines; and entering a table of values to fit a line.",
"Equally important is knowing when not to use it. Questions asking you to manipulate an expression, or to interpret what a coefficient means in context, gain nothing from a graph.",
"Practise typing quickly and accurately. A mistyped exponent produces a confident, wrong graph — the most dangerous kind of error, because it looks like an answer."]},
{"art": "target", "h": "Timed Sets and Pacing", "p": [
"You have roughly 95 seconds per question in Math. Most questions take considerably less, which builds a reserve for the harder ones.",
"Do a full 22-question module in 35 minutes every fortnight. Note where you are at the halfway mark: at 17 minutes you should be around question 11. Being significantly behind there is a pacing signal worth acting on.",
"Triage applies here as it does in Reading and Writing. If you have no route into a question after 45 seconds, mark it, enter a plausible answer, and move. There is no penalty for a wrong answer, so every student-produced response should still be filled with something.",
"Return to marked questions with whatever time remains. Fresh eyes solve a surprising proportion of them in under thirty seconds."]},
{"art": "mark", "h": "Math Error Analysis", "p": [
"Sort every math error into one of three types, because each demands a different response. A content error means you didn't know the rule — go back to the relevant unit. A setup error means you knew the maths but translated the problem wrongly — practise translation specifically. A careless error means you knew everything and slipped — this is a process problem.",
"Careless errors are the most frustrating and the most fixable, and for many students they are the largest single source of lost points. The fixes are unglamorous and effective: write each step down rather than working in your head, circle what the question actually asks before solving, and check units and reasonableness before entering an answer.",
"For every wrong question, record the topic, the error type, the correct method, and one specific change for next time. Review weekly and count the types. If setup errors dominate, more content revision will not help — targeted translation practice will.",
"Track your student-produced response errors separately. A meaningful number of these are formatting mistakes rather than mathematical ones, and formatting is fixed in a single sitting."]}],
"check": [
q("What is the main purpose of practising easy questions?", ["To feel confident", "To make your setup process automatic", "They appear most often", "They are worth more"], 1, "Automatic process frees attention for harder questions."),
q("Topic practice teaches method. What does mixed practice teach?", ["Speed only", "Recognising which method a question calls for", "Nothing extra", "Calculator skills"], 1, "Recognition is a separate skill from execution."),
q("You knew the maths but translated the problem wrongly. This is a:", ["Content error", "Setup error", "Careless error", "Formatting error"], 1, "Setup errors need translation practice, not more content revision."),
q("At the halfway point of a 35-minute Math module you should be around:", ["Question 5", "Question 11", "Question 18", "Question 22"], 1, "22 questions in 35 minutes means roughly question 11 at 17 minutes."),
q("Why fill in every student-produced response, even when unsure?", ["Blanks lose points", "There is no wrong-answer penalty, so a guess is free", "It looks better", "The system requires it"], 1, "An unanswered question is a guaranteed zero.")]
}]

def main():
    with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
        d = fh.read()

    if '"sat3a"' in d:
        sys.exit("FAIL: batch 2 already injected")
    if '"SAT-Y1"' not in d:
        sys.exit("FAIL: SAT course not found — run batch 1 first")

    # Batch 1's final unit ends the units array of SAT-Y1. Append after it.
    anchor = '{"q":"Why do easy questions deserve real practice time?","o":["They appear most often","Careless errors there cost as much as hard-question errors","They are worth more points","They are always in module one"],"a":1,"why":"Every question carries equal raw weight."}]}]'
    if d.count(anchor) != 1:
        sys.exit(f"FAIL: end-of-units anchor found {d.count(anchor)}x")

    payload = json.dumps(UNITS, ensure_ascii=False, separators=(",", ":"))
    d = d.replace(anchor, anchor[:-1] + "," + payload[1:-1] + "]", 1)

    with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
        fh.write(d)

    words = sum(len(" ".join(s["p"]).split()) for u in UNITS for s in u["sections"])
    print(f"  units appended     : {len(UNITS)} (now units 8-13)")
    print(f"  sections           : {sum(len(u['sections']) for u in UNITS)}")
    print(f"  practice questions : {sum(len(u['check']) for u in UNITS)}")
    print(f"  lesson words       : ~{words:,}")

if __name__ == "__main__":
    main()
