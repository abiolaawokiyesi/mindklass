#!/usr/bin/env python3
"""
SAT course — BATCH 1 of 4.

Covers Part 1 (Getting Started) and Part 2 (SAT Reading and Writing, modules
2A-2F) from the supplied table of contents. Injected into the `gg` catalogue
(student-facing) under cat "General Courses" so it appears in the General
Courses tab.

Assessment fields are deliberately null/0: the 200-question banks per focal
point are still to come. Once they arrive, passMark, totalQuestions, examMins
and a `questions` array get filled in and the assessment unlocks.

Later batches:
  Batch 2 - Part 3, SAT Math (modules 3A-3F)
  Batch 3 - Parts 4-9: strategy, vocabulary, Desmos, diagnostics,
            question bank structure, full-length practice tests
  Batch 4 - Parts 10-18: study plans, score-improvement programmes, test-day
            preparation, mindset, dashboard, live learning, resources,
            final review, after the SAT
"""
import json
import re
import sys

SRC = "assets/app.js"

def sec(art, h, paras, ex=None):
    s = {"art": art, "h": h, "p": paras}
    if ex:
        s["ex"] = ex
    return s

def q(question, options, answer, why=None):
    d = {"q": question, "o": options, "a": answer}
    if why:
        d["why"] = why
    return d

UNITS = [
# ===========================================================================
{
"id": "sat1", "n": 1, "title": "Getting Started: How the Digital SAT Works",
"mins": 55, "icon": "Target",
"summary": "The test's structure, scoring, adaptive design and question types — plus how to set a target score and build a study plan you will actually follow.",
"keyWords": ["Digital SAT", "Adaptive testing", "Scaled score", "Module", "Target score", "Diagnostic"],
"sections": [
sec("talk", "Welcome to the SAT Course", [
"The SAT is not an intelligence test. It is a test of a narrow, predictable set of skills, asked in a narrow, predictable set of ways. That is genuinely good news, because predictable things can be practised — and practice is what moves scores.",
"This course is built around a simple loop you will repeat all the way through: learn the concept, see it worked, practise it untimed, practise it timed, then check mastery. Skipping straight to timed practice is the single most common way students waste months without improving.",
"Work through the units in order the first time. After that, use the course as a reference — jump to the module covering whatever your error log says is costing you the most points."]),
sec("steps", "How the Digital SAT Works", [
"The digital SAT runs on the Bluebook application and takes about 2 hours 14 minutes, plus a 10-minute break. It is far shorter than the old paper test, and every student sits it on a laptop or tablet.",
"There are two sections: Reading and Writing, then Math. Each section is split into two modules. Reading and Writing gives you 27 questions in 32 minutes per module. Math gives you 22 questions in 35 minutes per module.",
"Reading and Writing questions are short and self-contained — one passage of a few lines, one question. You will never again read a 700-word passage and answer ten questions about it. Math is roughly 75% multiple choice and 25% student-produced response, where you type your own answer."]),
sec("chart", "Adaptive Testing Explained", [
"The digital SAT is multistage adaptive. Everyone gets the same first module in each section. How you perform on that first module decides whether your second module is the easier or the harder version.",
"This matters enormously for strategy. The first module is not a warm-up — it is the gateway. Performing well there routes you to the harder second module, which is the only route to the top of the scoring range. Students who coast through module one cap their own score before they have really started.",
"The harder second module is not a punishment; it is an opportunity. Questions there carry more scoring weight, so a student who reaches it and gets some wrong can still outscore a student who reached the easier module and got everything right.",
"Practical consequence: never sacrifice accuracy in module one to save time. Bank the points early."],
{"t": "What this means in practice", "b": [
"Treat module one as the most important part of the section.",
"If you must rush somewhere, rush at the end of module two, not module one.",
"A student aiming above 1400 must reach the harder second module in both sections."]}),
sec("chart", "The SAT Scoring System", [
"Each section is scored from 200 to 800, giving a total between 400 and 1600. There is no penalty for a wrong answer, which has one absolute consequence: never leave a question blank. A guess is free.",
"Raw scores — the number you got right — are converted to scaled scores in a way that accounts for which module you saw and how hard the questions were. This is why you cannot simply count correct answers and predict a score.",
"Superscoring, offered by many universities, takes your best Reading and Writing score and your best Math score across different sittings and combines them. Check the policy of every institution you are applying to; it changes your retake strategy significantly."]),
sec("read", "SAT Question Types", [
"Reading and Writing draws from four content domains: Information and Ideas, Craft and Structure, Expression of Ideas, and Standard English Conventions. Every question you meet belongs to one of them, and each is covered by its own module in this course.",
"Math draws from four domains too: Algebra, Advanced Math, Problem Solving and Data Analysis, and Geometry and Trigonometry.",
"Learning to name the domain of a question as you read it is a real skill and worth practising early. Once you can say 'this is a Command of Evidence question', you already know what the correct answer has to do — and that halves the work."]),
sec("target", "Setting Your Target Score", [
"A target score should come from evidence, not ambition. Look up the middle 50% range of admitted students at each university on your list. Aim for the 75th percentile of your most competitive realistic choice.",
"Then work backwards. If you scored 1150 on a diagnostic and need 1350, that is 200 points — roughly achievable in 10 to 14 weeks of consistent, structured work. If the gap is 400 points, be honest about the timeline; that usually means two sittings.",
"Write the number down. Vague goals produce vague effort."]),
sec("build", "Your Diagnostic and Study Plan", [
"Before studying anything, sit one full-length practice test under real conditions: timed, no phone, one break. It will feel unpleasant. Do it anyway. Without a baseline you cannot tell what is working.",
"Then categorise every mistake into one of three buckets: I did not know the content, I knew it but made a careless error, or I ran out of time. These need completely different fixes, and treating them the same is why students plateau.",
"Content gaps need lessons. Careless errors need process changes — writing steps down, checking units, re-reading the question stem. Timing problems need drilling and triage practice, not more content.",
"Build your week around consistency rather than heroics. Five focused 45-minute sessions beat one exhausting Saturday every time, because spacing is what moves material into long-term memory."],
{"t": "Recommended weekly rhythm", "b": [
"3 sessions of concept learning and untimed practice.",
"1 session of timed drills on your weakest domain.",
"1 session reviewing your error log — the highest-value hour of your week.",
"One full practice test every 2 to 3 weeks, not more."]})],
"check": [
q("How is the digital SAT adaptive?", ["Every question adapts to your last answer", "Your performance on the first module decides the difficulty of the second module", "The test gets harder every 10 questions regardless of performance", "Only the Math section adapts"], 1, "It is multistage adaptive: module one determines which version of module two you receive."),
q("Why should you never leave a question blank?", ["Blank answers lose two points", "There is no penalty for wrong answers, so guessing is free", "The system flags blanks to universities", "Blanks end the module early"], 1, "No wrong-answer penalty means an unanswered question is a guaranteed zero."),
q("Why is the first module especially important?", ["It is worth double marks", "It decides whether you can reach the harder, higher-scoring second module", "It is the only module that counts", "It is longer than the second module"], 1, "Routing to the harder second module is required to access the top of the scale."),
q("A student keeps missing questions they actually understand. What is the correct fix?", ["Learn more content", "Change process — write steps, re-read the stem, check the question asked", "Take more full-length tests", "Guess faster"], 1, "Careless errors are process failures, not knowledge gaps."),
q("What is superscoring?", ["Averaging all your attempts", "Combining your best section scores from different sittings", "Adding bonus points for improvement", "Scoring above 1500"], 1, "Best Reading and Writing plus best Math across sittings, where the university allows it.")]
},
# ===========================================================================
{
"id": "sat2a", "n": 2, "title": "Reading Fundamentals",
"mins": 50, "icon": "BookOpen",
"summary": "How SAT Reading questions actually work: reading efficiently under pressure, finding the main idea and evidence, inferring, and reading tone and argument.",
"keyWords": ["Main idea", "Supporting evidence", "Inference", "Tone", "Author's purpose", "Function"],
"sections": [
sec("read", "Understanding SAT Reading Questions", [
"Digital SAT reading passages are short — typically 25 to 150 words — and each carries exactly one question. Your job is not to understand everything in the passage. It is to answer the specific question asked.",
"Read the question first. This single habit saves more time than any speed-reading technique, because it tells you what to look for before you start looking.",
"Every correct answer is defensible from the text alone. If you find yourself reasoning 'well, that's probably true in general', you have left the passage and you are about to get it wrong."]),
sec("steps", "Reading Efficiently Under Time Pressure", [
"You have roughly 71 seconds per Reading and Writing question. That is enough — but only if you are not re-reading aimlessly.",
"Use a fixed process: read the question, read the passage once at normal speed, predict your own answer in your head, then look at the options. Predicting before reading the options is the strongest defence against well-designed wrong answers.",
"Resist the urge to read every option carefully in order. Eliminate the clearly wrong ones fast, then spend your time on the two that remain. Almost every SAT reading question comes down to a final two."]),
sec("target", "Main Idea and Supporting Evidence", [
"The main idea is what the passage as a whole is doing, not what its most interesting sentence says. A common trap answer takes a vivid detail and dresses it up as the point.",
"Ask: if this passage had a title, what would it be? Then check that your answer covers the whole passage, not just the first or last line.",
"Supporting-evidence questions ask which quotation best backs a claim. The correct choice must connect directly to the claim as stated — not merely sit near it in the passage, and not merely sound authoritative."]),
sec("mark", "Author's Purpose and the Function of a Sentence", [
"Purpose questions ask why the author wrote something, not what it says. The answer is usually a verb: to challenge, to illustrate, to qualify, to introduce, to contrast.",
"Function questions zoom in further: what job does this particular sentence do for the paragraph around it? Read the sentence before and the sentence after. Function is defined by context, and a sentence read alone will mislead you.",
"A reliable test: delete the sentence mentally. What breaks? Whatever breaks is its function."]),
sec("law", "Inference, Tone and Argument", [
"An SAT inference is small. It is the next logical step from what is stated — never a leap. If your reasoning requires two or three steps, or outside knowledge, it is wrong.",
"Tone questions are usually decided by a handful of loaded words. Scan for evaluative language: 'merely', 'remarkable', 'so-called', 'admittedly'. Note that academic tone is rarely extreme — answers like 'contemptuous' or 'euphoric' are almost always traps.",
"When a passage presents a claim and a counterclaim, track who says what. Confusing the author's position with a view they are describing is one of the most costly errors in the section."],
{"t": "Wrong answers usually fail in predictable ways", "b": [
"Too extreme — 'always', 'never', 'proves', 'the only'.",
"Half right — one clause matches the passage, the other quietly does not.",
"True but irrelevant — accurate about the world, unsupported by this text.",
"Right idea, wrong scope — describes one line when the question asks about the whole passage."]})],
"check": [
q("What should you do before reading the passage?", ["Skim all four options", "Read the question", "Read the last sentence first", "Time yourself"], 1, "Reading the question first tells you what to look for."),
q("An SAT inference should be:", ["A creative leap beyond the text", "One small logical step from what is stated", "Based on your background knowledge", "The most surprising option"], 1, "SAT inferences are deliberately small and text-bound."),
q("Which is the strongest sign of a trap answer?", ["It is the longest option", "It uses absolute words like 'always' or 'proves'", "It appears second", "It repeats a word from the passage"], 1, "Extreme language rarely survives contact with a carefully hedged academic passage."),
q("How do you determine the function of a sentence?", ["Read it in isolation", "Read the sentences immediately before and after it", "Look for its longest word", "Check if it is the topic sentence"], 1, "Function is defined by surrounding context."),
q("A supporting-evidence answer is correct when it:", ["Sounds most authoritative", "Sits closest to the claim in the passage", "Connects directly to the claim as stated", "Contains a statistic"], 2, "Proximity and tone are irrelevant; the logical link is what counts.")]
},
# ===========================================================================
{
"id": "sat2b", "n": 3, "title": "Information and Ideas",
"mins": 45, "icon": "Search",
"summary": "Central ideas, command of evidence in both text and data form, drawing conclusions, and handling questions built on graphs and tables.",
"keyWords": ["Central idea", "Command of evidence", "Quantitative evidence", "Conclusion", "Two-way data"],
"sections": [
sec("target", "Central Ideas and Details", [
"Central idea questions test whether you can separate the argument from its decoration. Examples, dates and names support the idea; they are not the idea.",
"A useful discipline is to summarise the passage in one clause before looking at the options. If your clause and an option say the same thing in different words, you have found it.",
"Detail questions are the opposite: they reward precision. Locate the exact line, and read one sentence either side of it before committing."]),
sec("law", "Command of Evidence: Textual", [
"These questions give you a claim, hypothesis or argument and ask which finding would most strengthen or weaken it. The word 'most' is doing real work — several options will be relevant, only one will be decisive.",
"Before looking at the options, articulate what the claim actually predicts. Then ask which option confirms or contradicts that prediction directly.",
"Strengthening means supporting the specific mechanism claimed, not merely being good news for the researcher. Weakening means undermining the link, not simply describing a limitation."]),
sec("chart", "Command of Evidence: Quantitative", [
"Data questions pair a short text with a graph or table. Read the axis labels, the units and the legend before reading anything else. A shocking proportion of errors here come from misreading the axis, not from misreading the argument.",
"The correct answer must be both true according to the data and relevant to the claim in the text. Wrong options are usually true-but-irrelevant, or relevant-but-not-what-the-data-shows.",
"Never bring in outside knowledge about the topic. If the graph shows something implausible, the graph wins."]),
sec("build", "Inferences, Conclusions and Comparing Information", [
"Completion questions end with a blank and ask you to finish the logical thought. Treat these as inference questions with extra structure: identify the direction the argument is travelling, then choose the option that continues it.",
"Watch the connective before the blank. 'However' reverses direction; 'therefore' continues it; 'although' signals concession. These little words decide the answer more often than the content does.",
"When two studies or viewpoints are presented, get clear on whether they agree, disagree, or address different questions entirely — the third case is common and frequently missed."])],
"check": [
q("On a data question, what should you read first?", ["The answer options", "The axis labels, units and legend", "The final sentence of the text", "The title of the study"], 1, "Most data errors are axis-reading errors, not reasoning errors."),
q("To weaken a hypothesis, an option must:", ["Mention a limitation of the study", "Undermine the specific link the hypothesis claims", "Introduce a new topic", "Be negative in tone"], 1, "Generic limitations are not the same as decisive counter-evidence."),
q("The word 'however' before a blank signals that the completion should:", ["Continue the same direction", "Reverse or qualify the previous idea", "Introduce a statistic", "Repeat the main idea"], 1, "Connectives control the logical direction of the completion."),
q("If a graph contradicts what you know about the real world, you should:", ["Trust your knowledge", "Trust the graph", "Skip the question", "Choose the most extreme option"], 1, "SAT data questions are closed-world: the data provided is authoritative.")]
},
# ===========================================================================
{
"id": "sat2c", "n": 4, "title": "Craft and Structure",
"mins": 45, "icon": "BookText",
"summary": "Words in context, text structure, rhetorical purpose, point of view and the connections between paired texts.",
"keyWords": ["Words in context", "Text structure", "Rhetorical choice", "Point of view", "Paired texts"],
"sections": [
sec("read", "Words in Context", [
"These are the most common questions in the section, and they are not vocabulary tests. The tested word is usually familiar; what is tested is whether you can read the sentence precisely enough to pin down which shade of meaning fits.",
"Cover the options. Read the sentence with a blank where the word goes, and supply your own word. Then find the option closest to yours. Doing this before reading the options is the difference between a reliable 90% and a coin flip.",
"Beware the most common meaning of a word being offered as a trap when the sentence demands a secondary sense. 'Sustain' can mean support, endure, or suffer — the sentence decides."]),
sec("steps", "Text Structure and Purpose", [
"Structure questions ask how a passage is organised: problem then solution, claim then counterexample, general principle then specific case. Name the shape before you look at the options.",
"Purpose questions about a whole text are answered by the verb again: does the passage explain, argue, describe, compare, or correct a misconception?",
"When a passage begins with a widely held belief, the author is almost always about to complicate or overturn it. That is a structural convention worth recognising instantly."]),
sec("talk", "Rhetorical Choices and Point of View", [
"Rhetorical-choice questions ask why the author used a particular device — an analogy, a concession, a rhetorical question, a specific example. The answer explains the effect on the reader or the argument.",
"Point of view means the author's stance toward the material: enthusiastic, sceptical, neutral, cautiously supportive. As with tone, the SAT rewards moderate readings. Academic writers hedge.",
"Distinguish carefully between the author's voice and voices the author reports. 'Critics have argued' is a signpost that what follows is not the author's own view."]),
sec("law", "Paired Texts and Connections Between Ideas", [
"Paired-text questions give you two short passages and ask how the second relates to the first. The relationship is usually one of: agreement, disagreement, qualification, or extension to a new case.",
"Read text one, state its claim in your own words, then read text two asking only one question: does this support, challenge, refine or redirect what I just read?",
"The most common wrong answer overstates the disagreement. Two researchers differing on a detail are not in fundamental opposition, and the SAT loves to test whether you noticed."])],
"check": [
q("The best first move on a words-in-context question is to:", ["Read all four options carefully", "Cover the options and supply your own word", "Choose the most sophisticated word", "Look for the word's most common meaning"], 1, "Predicting first neutralises the trap options."),
q("A passage opens with a widely held belief. What usually follows?", ["Further supporting evidence", "A complication or correction of that belief", "An unrelated example", "A summary"], 1, "This is a standard structural convention in SAT passages."),
q("'Critics have argued that...' signals that what follows is:", ["The author's own view", "A view the author is reporting", "A proven fact", "The main idea"], 1, "Reported views must not be mistaken for authorial position."),
q("The most common error on paired-text questions is:", ["Overstating the disagreement between the texts", "Reading too slowly", "Ignoring the second text", "Choosing the shortest option"], 0, "Mild qualification is regularly misread as fundamental opposition.")]
},
# ===========================================================================
{
"id": "sat2d", "n": 5, "title": "Expression of Ideas",
"mins": 45, "icon": "PenLine",
"summary": "Transitions, organisation, relevance and concision, and the rhetorical-synthesis questions that ask you to combine notes to meet a stated goal.",
"keyWords": ["Transitions", "Rhetorical synthesis", "Concision", "Relevance", "Logical flow"],
"sections": [
sec("build", "Transitions", [
"Transition questions are among the most learnable points on the entire test, because the logic is mechanical. Cover the transition, read the sentence before and the sentence after, and decide the relationship between them.",
"There are only a handful of relationships: addition (moreover, furthermore), contrast (however, nevertheless, by contrast), cause and effect (therefore, consequently, as a result), example (for instance, specifically), and concession (admittedly, granted).",
"Decide the relationship in your own words first — 'these two ideas disagree' — then pick the transition that expresses it. Choosing by ear is what produces errors; the wrong options are chosen precisely because they sound plausible.",
"Watch for transitions that are the right type but the wrong strength, and for sentences where no transition is needed at all."],
{"t": "The four-step transition method", "b": [
"1. Cover the blank entirely.",
"2. Summarise the sentence before in three words.",
"3. Summarise the sentence after in three words.",
"4. Name the relationship, then match it to an option."]}),
sec("steps", "Rhetorical Synthesis", [
"These questions give you a bulleted list of notes and a stated goal — for example, 'to emphasise a similarity between the two methods'. Your task is to choose the sentence that accomplishes exactly that goal using the notes.",
"The goal statement is the whole question. Read it twice. Three of the four options will be factually accurate according to the notes and will still be wrong, because they do not do what the goal asks.",
"Underline the key verb in the goal: emphasise, contrast, introduce, explain, illustrate. Then check each option against that verb specifically."]),
sec("mark", "Relevance, Concision and Flow", [
"Where the SAT offers you a shorter option that preserves the meaning, it is usually correct. Redundancy is the most heavily tested stylistic fault: 'annual yearly report', 'combined together', 'the reason is because'.",
"Relevance questions ask whether a sentence belongs. If it introduces a topic the paragraph does not develop, it goes — however interesting it is.",
"Order questions are settled by pronouns and connectives. A sentence containing 'this approach' must follow the sentence that introduces the approach. Track the references and the sequence assembles itself."])],
"check": [
q("What is the correct first step on a transition question?", ["Read the options aloud to see which sounds right", "Cover the blank and summarise the sentences either side", "Choose the most formal transition", "Look at the paragraph's first sentence"], 1, "Choosing by ear is the main cause of errors here."),
q("On a rhetorical-synthesis question, three wrong options are usually:", ["Factually false", "Factually accurate but failing the stated goal", "Grammatically incorrect", "Too short"], 1, "The goal statement, not accuracy, separates right from wrong."),
q("'The annual yearly report' is an example of:", ["A transition error", "Redundancy", "A pronoun error", "A tense error"], 1, "'Annual' and 'yearly' say the same thing."),
q("A sentence beginning 'This approach...' must be placed:", ["First in the paragraph", "After the sentence introducing the approach", "Last in the paragraph", "Anywhere"], 1, "Pronoun references dictate order.")]
},
# ===========================================================================
{
"id": "sat2e", "n": 6, "title": "Standard English Conventions",
"mins": 70, "icon": "ClipboardCheck",
"summary": "The grammar and punctuation rules the SAT tests repeatedly: sentence boundaries, commas, semicolons, colons, dashes, agreement, tense, modifiers, parallel structure and possessives.",
"keyWords": ["Independent clause", "Semicolon", "Colon", "Subject-verb agreement", "Modifier", "Parallelism", "Possessive"],
"sections": [
sec("law", "Sentence Boundaries: The Foundation", [
"Almost half of all punctuation questions reduce to one skill: telling an independent clause from a dependent one. An independent clause has a subject and a verb and could stand alone as a sentence.",
"Two independent clauses cannot be joined by a comma alone — that is a comma splice, and it is always wrong on the SAT. They can be joined by a semicolon, by a comma plus a coordinating conjunction (for, and, nor, but, or, yet, so), by a colon where the second explains the first, or by a full stop.",
"A fragment is the opposite failure: a group of words punctuated as a sentence without a subject or a working verb. Watch for '-ing' words posing as verbs — 'The student walking to school' is not a sentence.",
"Get this one distinction solid and a large block of the Writing section becomes mechanical."],
{"t": "Test both sides of the punctuation", "b": [
"Cover the punctuation mark. Read what is on the left. Could it stand alone?",
"Read what is on the right. Could it stand alone?",
"Both independent: semicolon, colon, full stop, or comma + FANBOYS.",
"Only one independent: comma or no punctuation — never a semicolon."]}),
sec("mark", "Commas: The Four Jobs", [
"The SAT tests commas doing exactly four jobs. First, separating items in a list. Second, joining an independent clause to a dependent one. Third, setting off non-essential information. Fourth, following an introductory element.",
"Non-essential information takes commas on both sides — and this is where students lose points. If you open with a comma you must close with one. Test by deleting the phrase: if the sentence still works and still means the same thing, it is non-essential and needs the pair.",
"Never place a comma between a subject and its verb, and never use one merely because you would pause when speaking. 'Pause' is not a grammatical rule."]),
sec("law", "Semicolons, Colons and Dashes", [
"A semicolon joins two independent clauses that are closely related. On the SAT it is functionally interchangeable with a full stop — which gives you a powerful shortcut: if a semicolon works, a full stop works too, so if both are offered, neither can be the answer.",
"A colon introduces an explanation, a list or an elaboration, and what comes before the colon must be a complete sentence. What follows need not be.",
"Dashes work in pairs like commas for non-essential information, or singly like a colon to introduce. Crucially, the SAT does not allow you to mix — you cannot open with a comma and close with a dash."]),
sec("build", "Agreement, Clarity and Tense", [
"Subject-verb agreement questions almost always separate the subject from the verb with a prepositional phrase: 'The collection of rare manuscripts is valuable.' Cross out the phrase and the agreement becomes obvious.",
"Pronoun agreement follows the same logic. A singular noun takes a singular pronoun — 'each student submitted his or her essay', not 'their essay', in formal SAT usage. Pronoun clarity questions test whether 'it' or 'they' has exactly one possible referent.",
"Verb tense is decided by context, not by preference. Look for time markers elsewhere in the passage — 'in 1923', 'currently', 'by the time' — and match. Keep tense consistent unless the meaning requires a shift."]),
sec("steps", "Modifiers and Parallel Structure", [
"A modifier must sit next to what it modifies. When a sentence opens with a descriptive phrase, the noun immediately after the comma must be the thing being described. 'Walking through the museum, the paintings impressed her' claims the paintings were walking.",
"The fix is always the same: identify who or what is performing the opening action, and make sure that noun comes first after the comma.",
"Parallel structure requires items in a list or comparison to share grammatical form: 'reading, writing and arithmetic', not 'reading, writing and to do arithmetic'. Comparisons must also compare like with like — 'her score was higher than his', not 'higher than him'."]),
sec("mark", "Possessives and Apostrophes", [
"Three forms are constantly confused and constantly tested. 'Its' is possessive; 'it's' means it is. 'Their' is possessive, 'they're' means they are, 'there' is a place. 'Whose' is possessive; 'who's' means who is.",
"Singular possessive adds apostrophe-s: the student's book. Plural possessive adds the apostrophe after the s: the students' books. Plural with no possession takes no apostrophe at all: the students arrived.",
"Ask two questions in order: is anything being possessed, and is the owner singular or plural? That resolves nearly every apostrophe question on the test."])],
"check": [
q("Two independent clauses joined by only a comma is called:", ["A fragment", "A comma splice", "A modifier error", "Parallelism"], 1, "Always incorrect on the SAT."),
q("If both a semicolon and a full stop are offered as options, then:", ["The semicolon is correct", "The full stop is correct", "Neither can be correct, since they are interchangeable", "It depends on clause length"], 2, "Two identical-function options cannot both be right, so neither is."),
q("What must come before a colon?", ["A dependent clause", "A complete sentence", "A list", "A conjunction"], 1, "The colon requires an independent clause to its left."),
q("'Walking through the museum, the paintings impressed her.' The error is:", ["Subject-verb agreement", "A dangling modifier", "Verb tense", "A comma splice"], 1, "The opening phrase must describe the noun that follows the comma."),
q("'The students' books' indicates:", ["One student, many books", "Many students, possession", "Many students, no possession", "It is a contraction"], 1, "Apostrophe after the s marks a plural possessive."),
q("In 'The collection of rare manuscripts ___ valuable', the correct verb is:", ["are, because manuscripts is plural", "is, because the subject is 'collection'", "were", "have been"], 1, "The prepositional phrase is not the subject.")]
},
# ===========================================================================
{
"id": "sat2f", "n": 7, "title": "Reading & Writing Practice and Error Analysis",
"mins": 55, "icon": "TrendingUp",
"summary": "How to practise so that it actually raises your score: difficulty progression, timed sets, module simulations, and the error log that drives everything.",
"keyWords": ["Error log", "Timed practice", "Triage", "Module simulation", "Deliberate practice"],
"sections": [
sec("steps", "Working Through the Difficulty Levels", [
"Practise in stages. Start untimed on easy questions until your process is automatic, then move to medium, then hard. Students who jump straight to hard questions learn to feel bad rather than to improve.",
"Easy questions are worth real practice time because they are where careless errors hide. A student losing four easy questions per module is losing more points than one missing the hardest question in the section.",
"Only once accuracy is stable at a difficulty level should you add the clock. Speed built on shaky accuracy collapses under pressure."]),
sec("target", "Timed Practice and Triage", [
"Aim for roughly 71 seconds per question, but do not treat it as a rule for every question. Some take 30 seconds; some deserve 100.",
"Triage means deciding fast whether a question is worth your time right now. If you have not made progress in about 30 seconds, mark it, guess, and move. Return if time allows. A hard question is worth the same as an easy one — spending three minutes on it is a losing trade.",
"Practise triage deliberately during drills. It is a skill, and students who have never practised it freeze on test day."]),
sec("chart", "Module Simulations", [
"Once a fortnight, do a full 27-question module in 32 minutes with no interruptions. This builds the specific stamina the real test demands, which shorter drills cannot.",
"Simulate the digital environment: work on a screen, use the on-screen tools, do not annotate on paper if you would not have paper.",
"Record your score, your timing at the halfway point, and how many questions you marked for review. Patterns in these numbers tell you more than the raw score does."]),
sec("mark", "Error Analysis: The Highest-Value Habit", [
"For every question you get wrong — and every one you got right while unsure — write four things: the question type, why the right answer is right, why your answer was wrong, and what you will do differently next time.",
"That fourth item is what makes this work. 'I misread it' is not a plan. 'I will read the question stem twice before looking at options' is.",
"Review your log weekly and count the categories. The category with the highest count is your study plan for the following week. This one habit separates students who improve from students who simply accumulate practice hours.",
"Expect the log to feel tedious. It is the most reliable score-raising activity in this entire course."],
{"t": "Error log template", "b": [
"Question type / domain:",
"Why the correct answer is correct:",
"Why I chose what I chose:",
"The specific change I will make next time:"]})],
"check": [
q("When should you add time pressure to your practice?", ["Immediately, to build speed", "Once accuracy is stable at that difficulty level", "Only in the final week", "Never"], 1, "Speed built on unstable accuracy collapses under pressure."),
q("You have made no progress on a question after 30 seconds. You should:", ["Keep working — persistence pays", "Mark it, guess, and move on", "Skip it and leave it blank", "Restart the module"], 1, "All questions score the same; time spent must be traded rationally."),
q("The most important part of an error log entry is:", ["The question number", "The correct answer", "The specific change you will make next time", "How long the question took"], 2, "Without an action, logging is just record-keeping."),
q("Why do easy questions deserve real practice time?", ["They appear most often", "Careless errors there cost as much as hard-question errors", "They are worth more points", "They are always in module one"], 1, "Every question carries equal raw weight.")]
}]

COURSE = {
"code": "SAT-Y1",
"subject": "SAT (Digital) Preparation",
"group": "Test Preparation",
"cat": "General Courses",
"year": "All years",
"term": 1,
"termLabel": "Digital SAT · self-paced",
"title": "SAT Preparation: The Complete Digital SAT Course",
"tagline": "A full Digital SAT preparation programme — Reading and Writing, Math, strategy, Desmos, full-length practice and test-day readiness. Learn the concept, see it worked, practise it, then prove mastery.",
"months": "12 weeks (self-paced; shorter and longer plans included)",
"passMark": None,
"totalQuestions": 0,
"examMins": 0,
"materials": [],
"units": UNITS,
}

def main():
    with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
        d = fh.read()

    if '"SAT-Y1"' in d:
        sys.exit("FAIL: SAT course already present")

    anchor = 'var gg={'
    if d.count(anchor) != 1:
        sys.exit(f"FAIL: gg catalogue anchor found {d.count(anchor)}x")

    payload = json.dumps({"SAT-Y1": COURSE}, ensure_ascii=False, separators=(",", ":"))
    inner = payload[1:-1]  # strip the outer braces
    d = d.replace(anchor, anchor + inner + ",", 1)

    with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
        fh.write(d)

    words = sum(len(" ".join(s["p"]).split()) for u in UNITS for s in u["sections"])
    checks = sum(len(u["check"]) for u in UNITS)
    print(f"  units injected      : {len(UNITS)}")
    print(f"  lesson word count   : ~{words:,}")
    print(f"  practice questions  : {checks}")
    print(f"  payload size        : {len(inner):,} chars")

if __name__ == "__main__":
    main()
