#!/usr/bin/env python3
"""
Introduction to Vibe Coding — course injection.

Built from the "Introduction to Vibe Coding — Detailed Course Content"
document: 15 modules, mapped one-to-one onto 15 units.

NOTE ON THE SECOND DOCUMENT (the "true-life story" module openers):
those narratives were NOT used. They present invented scenes and quotes
attributed to real, named people (Karpathy, Willison, Hightower, Rauch,
Montani, Masad and others) as though they were documented fact, and they
carry several verifiable errors — the term "vibe coding" was coined in
February 2025, not October 2024, and some of the cited source links point
at unrelated organisations. Publishing fabricated biography under real
names on a paid learning platform is a real liability, so the course is
built from the teaching content instead. One accurate, sourced sentence
about the term's origin appears in unit 1.
"""
import json
import sys

SRC = "assets/app.js"


def q(question, options, answer, why=None):
    d = {"q": question, "o": options, "a": answer}
    if why:
        d["why"] = why
    return d


def sec(art, h, paras, ex=None):
    s = {"art": art, "h": h, "p": paras}
    if ex:
        s["ex"] = ex
    return s


UNITS = [
# 1 ---------------------------------------------------------------------------
{"id": "vibe1", "n": 1, "title": "What Is Vibe Coding?", "mins": 45, "icon": "Sparkles",
"summary": "What coding is, what vibe coding adds, how the two differ, why the approach spread so quickly — and, just as importantly, what vibe coding is not.",
"keyWords": ["Vibe coding", "AI assistant", "Natural language", "Iteration", "Traditional coding"],
"sections": [
sec("talk", "Coding, In One Sentence", [
"Coding is giving instructions to a computer. That is the whole of it. When you tell a machine \"when the user clicks this button, show a message\", you are coding — the only question is what language you use to say it.",
"Programming languages such as JavaScript, Python and Java exist because computers need instructions in a form they can execute exactly. Learning one traditionally meant months spent on syntax before you could build anything a person would actually use.",
"That barrier is what has changed. The instruction still has to be precise; it no longer has to be typed by you in a specific language."]),
sec("chart", "What Vibe Coding Means", [
"Vibe coding is building software using AI as a coding partner. Instead of writing every line by hand, you describe what you want in ordinary language and the AI produces the code.",
"You might say: \"Build a website for a clothing brand. Make it modern, use black and white, and add a section showing our products.\" The AI generates it. You look at the result and say \"make the buttons bigger\" or \"add a contact form\", and it adjusts.",
"The term was coined by Andrej Karpathy, a founding member of OpenAI and former director of AI at Tesla, in a short post in February 2025. It caught on because it named something many developers had already started doing.",
"The shift is in your role. You move from typist to director: you set the direction, judge the result, and steer."]),
sec("chart", "Traditional Coding vs Vibe Coding", [
"Traditional coding runs: idea, learn syntax, write code, debug, test, improve. Vibe coding runs: idea, describe idea, AI generates code, test, give feedback, improve.",
"Notice what is identical in both — testing and improving. The AI removes typing, not judgement.",
"And vibe coding does not make programming knowledge worthless. The opposite: knowing roughly how software fits together makes you far better at working with AI, because you can tell when an answer is wrong and describe what you actually want."]),
sec("law", "What Vibe Coding Is Not", [
"It is not copying AI output without checking it. It is not assuming the AI is correct. It is not avoiding learning entirely, building without testing, or ignoring security.",
"AI generates confident, fluent, plausible code — including when that code is wrong, insecure, or refers to a library that does not exist. Fluency is not accuracy.",
"Hold on to one line for the rest of this course: **AI is your assistant, not your brain.** You remain responsible for what you ship."],
{"t": "The loop you will repeat all course", "b": [
"Think — what am I actually trying to build?",
"Describe — say it clearly enough for the AI to act on.",
"Build — let the AI generate.",
"Test — check it does what you meant.",
"Fix — feed back what went wrong.",
"Improve — then repeat."]})],
"check": [
q("Vibe coding is best described as:", ["Letting AI build software with no human involvement", "Building software using AI as a coding partner while you direct and verify", "A programming language", "Copying code from the internet"], 1, "The human directs, judges and verifies; the AI generates."),
q("Does vibe coding make programming knowledge useless?", ["Yes, it replaces it entirely", "No — knowing how software works makes you better at directing AI", "Only for websites", "Only for beginners"], 1, "Understanding lets you spot wrong answers and describe what you want."),
q("Which is the correct mindset?", ["AI is always right", "AI is your assistant, not your brain", "Never check AI output", "Testing is optional"], 1),
q("What stays the same in both traditional and vibe coding?", ["Memorising syntax", "Testing and improving", "Writing every line by hand", "Debugging alone"], 1, "AI removes typing, not judgement.")]},
# 2 ---------------------------------------------------------------------------
{"id": "vibe2", "n": 2, "title": "The Vibe Coding Mindset", "mins": 40, "icon": "Lightbulb",
"summary": "Thinking in outcomes rather than syntax, briefing AI like a partner, experimenting freely, iterating in small steps, and treating errors as information.",
"keyWords": ["Outcome thinking", "Context", "Experimentation", "Iteration", "Problem solving"],
"sections": [
sec("target", "Think About the Outcome", [
"Beginners think \"I need to write JavaScript.\" Builders think \"I need a button that lets users submit their information.\"",
"The second framing is more useful because it describes a result. The AI can work out the language; only you know what the thing is for.",
"Practise stating what should be true when the feature works, before touching any tool."]),
sec("talk", "Brief AI Like a Partner", [
"\"Build an app\" gives the AI almost nothing, so it invents the missing details — and its invention will not match the picture in your head.",
"Compare: \"Build a simple task-management app for university students. Users should be able to add, complete, edit and delete tasks.\" Now there is a user, a purpose and a feature list.",
"You are not writing a magic incantation. You are briefing a capable colleague who cannot read your mind."]),
sec("build", "Experiment and Iterate", [
"Your first version will not be right. That is the normal case, not a failure — great applications are built through many small improvements rather than one perfect attempt.",
"A realistic sequence: basic site, then better colours, then navigation, then a contact form, then mobile-friendly. Five small steps, each verifiable.",
"Small steps also make problems easy to locate. If you change one thing and it breaks, you know exactly what broke it. Change fifteen things and you are guessing."]),
sec("mark", "Errors Are Information", [
"\"My project is broken\" is a dead end. \"I found something I need to fix\" is a task.",
"This is not just positive thinking. An error message is data — usually the most specific data you will get about what is actually wrong.",
"The learners who improve fastest are the ones who stop flinching at red text and start reading it."])],
"check": [
q("Which framing is more useful when starting a feature?", ["I need to write JavaScript", "I need a button that lets users submit their information", "I need to learn React first", "I need a better computer"], 1, "Describe the outcome; the AI handles the language."),
q("Why brief the AI with user, purpose and features?", ["It makes the prompt longer", "Without them the AI invents details that won't match your intent", "It is required by the tool", "It speeds up the computer"], 1),
q("Why change one thing at a time?", ["It looks more professional", "If something breaks you know exactly what caused it", "AI can only handle one change", "It uses less electricity"], 1),
q("An error message is best treated as:", ["A sign you should start over", "The most specific information available about what is wrong", "Something to ignore", "Proof that AI failed"], 1)]},
# 3 ---------------------------------------------------------------------------
{"id": "vibe3", "n": 3, "title": "Setting Up Your AI Coding Environment", "mins": 50, "icon": "Cpu",
"summary": "The tools you need and what each one does: AI assistant, code editor, browser, terminal, version control and hosting — plus how a project is organised on disk.",
"keyWords": ["Code editor", "Terminal", "Git", "Project folder", "Deployment", "Workflow"],
"sections": [
sec("steps", "The Six Tools", [
"An AI coding assistant generates and explains code. A code editor is where files live and get changed. A browser shows the result. A terminal lets you type commands to your computer. Git records the history of your project. A hosting platform puts it on the internet for other people.",
"You do not need to master all six today. You need to know what each is for, so that when something goes wrong you know which one to look at.",
"Learn the workflow rather than one particular product. Tools change; the shape of the work does not."]),
sec("read", "Choosing an AI Coding Tool", [
"Useful questions when comparing tools: can it generate code, understand your existing project files, edit code that already exists, explain errors, work across several files at once, and is it approachable for a beginner?",
"Web-based tools remove most setup, which is genuinely valuable when you are starting. Desktop editors give more control. Either is a reasonable place to begin.",
"Avoid building your skills entirely around one product's quirks. The transferable skill is knowing what to ask for and how to check the answer."]),
sec("build", "Inside a Project", [
"A project is many files working together. A simple site might contain an index.html for structure, a style.css for appearance, a script.js for behaviour, and an images folder for pictures.",
"Understanding this layout matters more than it appears. When an AI says \"I updated the stylesheet\", you want to know which file that is and where to look.",
"Messy folders also confuse AI tools. A clean structure is partly for you and partly for your assistant."]),
sec("talk", "The Terminal", [
"The terminal is a way to talk to your computer using typed commands instead of clicking. It looks intimidating and is genuinely simple.",
"Early on you need very little: move between folders, list what is in one, and start your project. That is enough to be functional.",
"You will meet it again in the units on Git and deployment, so a small amount of comfort now pays off later."])],
"check": [
q("What is a terminal?", ["A type of website", "A way to talk to your computer using typed commands", "A code editor", "A database"], 1),
q("Why does a clean project folder matter?", ["It looks tidy", "Both you and AI tools get confused by messy structures", "It makes files smaller", "It is required by law"], 1),
q("What should you focus on when choosing tools?", ["The most expensive option", "Learning the workflow rather than one product", "Whichever is newest", "The one with most features"], 1),
q("What does Git do?", ["Hosts your website", "Records the history of your project", "Writes code for you", "Designs interfaces"], 1)]},
# 4 ---------------------------------------------------------------------------
{"id": "vibe4", "n": 4, "title": "Your First Vibe-Coded Project", "mins": 55, "icon": "Rocket",
"summary": "Build a working personal portfolio website from a single prompt: choosing a small first project, writing the prompt, reading what was generated, running it and making changes.",
"keyWords": ["First project", "Portfolio", "Prompt", "Running a project", "Making changes"],
"sections": [
sec("target", "Start Small", [
"Your first project should be small enough to finish. A personal portfolio site is ideal: name, photo, an About section, skills, projects and contact details.",
"It is small, visual, genuinely useful to own, and every change you make is immediately visible — which is exactly what you want while learning.",
"Resist starting with a social network. Ambition is good; an unfinished first project teaches very little."]),
sec("build", "Your First Prompt", [
"Something like: \"Create a modern personal portfolio website for a young software developer. Use a dark background with bright accent colours, responsive design, and include About, Skills, Projects and Contact sections.\"",
"Notice what that prompt contains: who it is for, how it should look, how it should behave on phones, and what sections it needs.",
"Write yours before you open any tool. Thinking on paper is faster than thinking in a chat window."]),
sec("read", "Reading What You Got", [
"Do not try to understand every line. Ask four questions instead: what files were created, what does each one do, where is the appearance controlled, and where would I change the text?",
"That is enough to work with. Deeper understanding accumulates naturally as you make changes and watch what moves.",
"If a file confuses you, ask the AI to explain it in simple words. That is a completely legitimate use of the tool."]),
sec("steps", "Run It, Then Change It", [
"Open the project in your browser. This moment — idea, to AI, to code, to a working product on your screen — is the point of the whole course.",
"Then start changing things: colours, text, a new section, better mobile layout, a small animation. Each request is a chance to see how your words map to results.",
"Change one thing, look, then change the next. You are training your instinct for how much detail a request needs."])],
"check": [
q("Why should your first project be small?", ["Small projects are more impressive", "You need to finish it — an unfinished project teaches little", "AI can't build large projects", "It costs less"], 1),
q("What four things should you look for in generated code?", ["Every single line explained", "Which files exist, what each does, where design lives, where to change text", "Only the HTML", "The file sizes"], 1),
q("When should you write your first prompt?", ["Directly into the tool without thinking", "Before opening any tool", "After the AI generates something", "It doesn't matter"], 1),
q("What's the best way to make changes?", ["All at once to save time", "One at a time, checking after each", "Only at the end", "Ask someone else"], 1)]},
# 5 ---------------------------------------------------------------------------
{"id": "vibe5", "n": 5, "title": "How to Prompt AI for Code", "mins": 55, "icon": "PenLine",
"summary": "Weak versus strong prompts, the six parts of a good coding prompt, giving context when something breaks, asking AI to explain itself, and building reusable templates.",
"keyWords": ["Prompt", "Context", "Specificity", "Templates", "Explanation"],
"sections": [
sec("chart", "Weak and Strong Prompts", [
"Weak: \"Make my website better.\" Better according to whom, in what respect? The AI will guess, and its guess is unlikely to be yours.",
"Strong: \"Make the homepage look more modern. Increase spacing between sections, improve the button design, use a dark blue background, and make sure the layout works well on phones.\"",
"The strong version is not longer for the sake of it. Every extra clause removes a decision the AI would otherwise have made blindly."]),
sec("law", "The Six Parts of a Good Coding Prompt", [
"A complete request answers six questions: what are you building, who is it for, what should it do, what should it look like, what technology should it use, and what rules or limits should the AI follow?",
"That last one is the most commonly skipped and often the most valuable. \"Do not add new libraries\" or \"keep the existing colour scheme\" prevents a great deal of unwanted rework.",
"You will not need all six every time. Knowing which one you have left out is the skill."],
{"t": "Prompt checklist", "b": [
"What am I building?",
"Who is it for?",
"What should it do?",
"What should it look like?",
"What technology should it use?",
"What must it not do?"]}),
sec("mark", "Give Context When Something Breaks", [
"\"Fix this\" gives the AI nothing to work with. It cannot see your screen, run your app, or know what you just changed.",
"Instead: \"The login button is not working. When I click it, nothing happens. Please check the login-related code and explain what is causing the problem before making the fix.\"",
"That last clause matters — asking for the diagnosis before the change stops the AI from silently rewriting things you did not want touched."]),
sec("talk", "Make the AI Explain Itself", [
"Two questions to use constantly: \"Explain this code in simple words\" and \"What did you change?\"",
"The first builds your understanding at whatever pace you need. The second protects you from changes you did not ask for and would not have approved.",
"Over time, collect the prompts that work into your own templates for building, improving, debugging, explaining and testing. A personal prompt library is one of the most practical assets you will build."])],
"check": [
q("Which is the strongest prompt?", ["Make it better", "Fix the design", "Increase spacing between sections, improve button design, use a dark blue background, and ensure it works on phones", "Add stuff"], 2),
q("Which part of a prompt is most often skipped?", ["What you're building", "What rules or limits the AI should follow", "Who it's for", "What it should do"], 1, "Constraints prevent unwanted rework."),
q("Why ask AI to explain the problem before fixing it?", ["It takes longer", "It stops the AI silently rewriting things you didn't want touched", "It's more polite", "It uses fewer tokens"], 1),
q("Why ask 'What did you change?'", ["To be thorough", "To catch changes you didn't ask for and wouldn't approve", "To make conversation", "It's required"], 1)]},
# 6 ---------------------------------------------------------------------------
{"id": "vibe6", "n": 6, "title": "Building Without Knowing Everything About Code", "mins": 60, "icon": "BookOpen",
"summary": "The minimum you genuinely need: HTML as structure, CSS as appearance, JavaScript as behaviour, the frontend/backend split, and how to read AI-generated code.",
"keyWords": ["HTML", "CSS", "JavaScript", "Frontend", "Backend", "Reading code"],
"sections": [
sec("build", "HTML, CSS and JavaScript", [
"HTML is the structure of a page — headings, paragraphs, images, buttons, forms. Think of it as the skeleton.",
"CSS controls how things look: colours, fonts, sizes, spacing, layout, animation. Think of it as the clothes.",
"JavaScript makes things happen: clicking buttons, opening menus, calculating numbers, showing messages, loading data. Think of it as the brain.",
"Almost every web page you have ever used is these three working together. Knowing which is which tells you where to look when something is wrong."]),
sec("chart", "Frontend and Backend", [
"The frontend is what the user sees. The backend is what happens behind the scenes.",
"When you log into an app: the frontend is the login form, the backend checks your account, and a database stores your account information.",
"This distinction becomes essential later. \"The button looks wrong\" is a frontend problem; \"my login says the wrong password when it is right\" is usually a backend one."]),
sec("read", "Reading AI-Generated Code", [
"You do not need to understand everything immediately. Aim to recognise a handful of things: variables (stored values), functions (named actions), components (reusable pieces), conditions (if this, then that), loops (repeat this), and errors.",
"Recognition is enough to navigate. Full comprehension follows from use, not from studying in advance.",
"The fastest way to build this: take a small piece of code the AI generated and ask it to explain the code line by line in simple language. Do that a few times a week and your reading ability climbs quickly."])],
"check": [
q("HTML is best described as:", ["The clothes of a website", "The skeleton or structure", "The brain", "The database"], 1),
q("A button looks wrong on the page. This is most likely:", ["A backend problem", "A frontend problem", "A database problem", "An internet problem"], 1),
q("What does JavaScript do?", ["Controls colours and fonts", "Provides structure", "Makes things happen — clicks, calculations, loading data", "Stores data permanently"], 2),
q("How do you improve at reading code fastest?", ["Study a textbook cover to cover", "Ask AI to explain small pieces line by line, regularly", "Memorise syntax", "Avoid reading it"], 1)]},
# 7 ---------------------------------------------------------------------------
{"id": "vibe7", "n": 7, "title": "Iterating and Debugging With AI", "mins": 55, "icon": "AlertTriangle",
"summary": "What a bug is, how to read an error, what information the AI actually needs, testing the fix yourself, and escaping the endless debugging loop.",
"keyWords": ["Bug", "Error message", "Debugging", "Root cause", "Testing the fix"],
"sections": [
sec("talk", "What Is a Bug?", [
"A bug is a problem in software: a button that does nothing, a page that will not load, wrong information on screen, a login that fails, an app that crashes.",
"Every piece of software ever written has had them. Their presence says nothing about your ability.",
"What does distinguish people is what happens next."]),
sec("read", "Read the Error", [
"The instinct on seeing red text is to panic or paste it straight into the AI without looking. Read it first.",
"Error messages usually name the file, the line and the kind of problem. Even when the wording is impenetrable, those three details narrow the search enormously.",
"You do not have to fully understand it to use it."]),
sec("steps", "What the AI Actually Needs", [
"\"It doesn't work\" is unusable. Give the AI six things: what you expected, what actually happened, the error message, the relevant code, what you changed recently, and how to reproduce it.",
"A worked example: \"My signup form should create a new account, but clicking Submit produces an error. Here is the error message and the relevant code. Please identify the likely cause, explain it simply, and suggest the safest fix.\"",
"\"What changed recently\" is the most frequently omitted and most frequently decisive item on that list."],
{"t": "Debugging report template", "b": [
"What I expected to happen:",
"What actually happened:",
"The exact error message:",
"The relevant code:",
"What I changed just before this:",
"How to reproduce it:"]}),
sec("mark", "Test the Fix, and Escape the Loop", [
"Never assume the AI fixed it. It will say it did. Check yourself, using the same steps that produced the problem.",
"Sometimes AI keeps changing things without solving anything — each fix introducing a new fault. This loop can consume hours.",
"Break it deliberately. Stop, and ask: \"Let's step back. What is the root cause of this problem?\" Forcing a diagnosis before another change is usually what ends the cycle."])],
"check": [
q("What should you do first when you see an error message?", ["Paste it into AI immediately", "Read it — it names the file, line and kind of problem", "Restart your computer", "Undo everything"], 1),
q("Which piece of debugging information is most often left out?", ["The error message", "What you changed recently", "What you expected", "The code"], 1),
q("The AI says it fixed your bug. You should:", ["Move on to the next feature", "Test it yourself using the steps that caused it", "Trust it", "Ask again"], 1),
q("How do you escape an endless debugging loop?", ["Keep asking for fixes", "Stop and ask for the root cause before any more changes", "Start the project over", "Change tools"], 1)]},
# 8 ---------------------------------------------------------------------------
{"id": "vibe8", "n": 8, "title": "Building a Complete Mini-Application", "mins": 65, "icon": "Layers",
"summary": "Combine everything so far into a working Task Manager: plan features first, build the interface, add functionality one piece at a time, test each, then improve the design.",
"keyWords": ["Planning", "Interface", "Functionality", "Feature-by-feature", "Task manager"],
"sections": [
sec("target", "Plan Before Building", [
"Write your feature list before you open anything. For a student task manager: add tasks, edit tasks, delete tasks, mark complete, search, filter, and save between sessions.",
"A written list is a definition of done. Without one, projects drift — you keep adding and never finish.",
"Mark which features are essential and which are optional. First versions should be small on purpose."]),
sec("build", "Interface First, Then Behaviour", [
"Build the visible shell first: header, an input box, buttons, task cards, navigation. Something you can look at and click.",
"Then add behaviour one feature at a time: add a task, then delete, then mark complete, then edit.",
"Building the interface first gives you somewhere to attach each function, and gives you a working thing to look at early — which matters more for motivation than it sounds."]),
sec("mark", "Test Each Feature As You Go", [
"Do not build everything and then test. If six features go in at once and something breaks, you have six suspects.",
"Add one, test it properly, then move on. Slower per step, dramatically faster overall.",
"Test the awkward cases too: an empty task, a very long one, deleting the last remaining task. Those are where real applications fail."]),
sec("steps", "Then Improve the Design", [
"Once it works, ask the AI to improve colours, spacing, typography, mobile responsiveness and accessibility.",
"Do this last deliberately. Polishing something whose behaviour is still changing means polishing twice.",
"When it works and looks right, you have built a complete application — plan, interface, function, test, polish. That is the full cycle, and every later project is the same shape at a larger size."])],
"check": [
q("What should you do before opening any tool?", ["Choose colours", "Write a feature list", "Pick a name", "Set up hosting"], 1),
q("Why build the interface before the functionality?", ["It looks better", "It gives you somewhere to attach each function and something to see early", "It's faster to type", "AI requires it"], 1),
q("Why test each feature as you add it?", ["To slow down", "If you add six at once and something breaks, you have six suspects", "To use more time", "It's traditional"], 1),
q("When should you polish the design?", ["First, to stay motivated", "Last, once behaviour has stopped changing", "Halfway through", "Never"], 1)]},
# 9 ---------------------------------------------------------------------------
{"id": "vibe9", "n": 9, "title": "Working With APIs and Data", "mins": 55, "icon": "Globe",
"summary": "How applications talk to other services: what an API is, requests and responses, JSON, using AI to integrate one, and reading API documentation.",
"keyWords": ["API", "Request", "Response", "JSON", "Endpoint", "API key"],
"sections": [
sec("talk", "What Is an API?", [
"An API is a messenger between applications. Your weather app asks a weather service \"what is the weather in Lagos?\" and the service sends the answer back.",
"This is how software stops being an island. Maps, payments, weather, messaging, sports scores — all of it arrives through APIs.",
"You do not need to own the data. You need to know how to ask for it."]),
sec("build", "Requests, Responses and JSON", [
"A request is what you send. A response is what comes back. An endpoint is the specific address you send it to. An API key identifies you, and is often required.",
"Data usually arrives as JSON — a simple, readable way of organising information. Something like: city Lagos, temperature 29. Names paired with values.",
"JSON looks technical and is not. If you can read a labelled list, you can read JSON."]),
sec("read", "Reading the Documentation", [
"Every API has documentation. You are looking for six things: the URL, the required parameters, how to authenticate, an example request, an example response, and the rate limits.",
"Rate limits are the one beginners skip and then get blocked by — most free APIs cap how many requests you may make per hour or per day.",
"You can ask AI to read documentation with you: \"Show me how to connect my application to this API, and explain each step in simple language.\" That is one of the highest-value uses of an AI assistant."]),
sec("target", "Project: Weather Dashboard", [
"Build an application where a user searches for a city and sees the temperature and conditions.",
"It is the ideal first API project: one clear input, one clear output, a free service, and instantly obvious when it works.",
"Handle the failure cases too — a city that does not exist, a network that drops, a key that is rejected. Real applications spend much of their code on things going wrong."])],
"check": [
q("An API is best described as:", ["A programming language", "A messenger between applications", "A database", "A type of website"], 1),
q("What is JSON?", ["A programming language", "A simple, readable way of organising information", "A type of API key", "A security protocol"], 1),
q("Which documentation detail do beginners most often skip?", ["The URL", "Rate limits", "Example requests", "The response format"], 1, "Most free APIs cap requests per hour or day."),
q("What should a good API project also handle?", ["Only the success case", "Failure cases — bad city, dropped network, rejected key", "Nothing extra", "Only the design"], 1)]},
# 10 --------------------------------------------------------------------------
{"id": "vibe10", "n": 10, "title": "Databases and Backend Basics", "mins": 60, "icon": "Landmark",
"summary": "Why applications need to remember things: what a database is, how frontend, backend and database fit together, authentication, and the security basics that matter from day one.",
"keyWords": ["Database", "Backend", "Authentication", "Sessions", "Security", "Persistence"],
"sections": [
sec("talk", "Why Databases Exist", [
"Imagine a task app where closing the tab deletes every task. It works perfectly and is completely useless.",
"A database is what lets an application remember. Without one you have a toy; with one you have a product.",
"This is usually the moment a first project becomes something other people could actually use."]),
sec("chart", "Frontend, Backend, Database", [
"A database stores information in an organised way — think of a table with an ID, a name and an email address for each person.",
"The flow runs: user, to frontend, to backend, to database. The frontend is what people see, the backend is the middleman that decides what is allowed, and the database holds the information.",
"The backend is where the rules live. It is what stops one user reading another user's data — which is why it cannot be skipped."]),
sec("law", "Authentication", [
"Authentication covers signing up, logging in, passwords, sessions and logging out.",
"A session is how the application remembers you are still logged in as you move between pages, without asking for your password each time.",
"Use established authentication systems rather than inventing your own. This is not a beginner limitation — experienced engineers follow the same rule, because authentication is unusually easy to get subtly and dangerously wrong."]),
sec("mark", "Security Basics From Day One", [
"Four rules to adopt immediately. Never store passwords as plain readable text. Never put secret API keys in code that ships to the browser. Never trust input from users without checking it. Always use proper authentication rather than a homemade version.",
"AI-generated code will sometimes violate these. It optimises for working, not for safe, and the two are not the same.",
"Ask explicitly: \"Review this code for security problems and explain any you find.\" Make it a habit now, while the projects are small and the stakes are low."])],
"check": [
q("Why does an application need a database?", ["To look professional", "So information survives after the app is closed", "To make it faster", "To connect to the internet"], 1),
q("What is the backend's most important job?", ["Making things look good", "Deciding what is allowed — stopping one user reading another's data", "Storing images", "Running the browser"], 1),
q("Should you build your own authentication system?", ["Yes, it's good practice", "No — use established systems; it's easy to get dangerously wrong", "Only for large apps", "Only if you know JavaScript"], 1),
q("AI-generated code sometimes has security flaws because:", ["AI is malicious", "It optimises for working, not for safe", "It's always outdated", "It can't write secure code"], 1)]},
# 11 --------------------------------------------------------------------------
{"id": "vibe11", "n": 11, "title": "Git, Version Control and Safe Vibe Coding", "mins": 50, "icon": "Shield",
"summary": "Protecting your work: what Git is, why it matters more when AI is editing your files, commits, branches, and how to review AI changes before accepting them.",
"keyWords": ["Git", "Commit", "Branch", "Version control", "Reviewing changes", "Rollback"],
"sections": [
sec("talk", "What Git Is", [
"Git tracks changes to your project. Think of it as a save-history system that lets you return to any earlier version.",
"Games have save points. Git is a save point you create deliberately, whenever the project is in a state worth keeping.",
"A commit is essentially saying: \"Save this version. It works.\""]),
sec("law", "Why Git Matters More With AI", [
"An AI assistant can rewrite many files in seconds. Most of the time that is exactly what you wanted. Occasionally it destroys a working feature.",
"Without version control, your only options are to remember what changed or rebuild it. Neither works well.",
"With it, you return to the last good version in a moment. Commit before letting AI make any large change — this single habit prevents most catastrophic losses."]),
sec("build", "Branches", [
"A branch is a separate line of work. Your main version stays untouched while you experiment.",
"This is where AI becomes genuinely freeing. Try an ambitious change on a branch; if it works, keep it, and if it does not, delete the branch and nothing is lost.",
"Experiments stop being risky, so you attempt more of them."]),
sec("mark", "Reviewing AI Changes", [
"Before accepting a large AI change, ask five questions: which files changed, what did it change, why did it change them, could this break something, and did it introduce a security problem?",
"This is not distrust; it is the same review a professional team applies to any contributor's work.",
"Accepting changes you have not looked at is how projects become code nobody understands — including you."],
{"t": "Before accepting an AI change", "b": [
"Which files changed?",
"What exactly changed in each?",
"Why did it make these changes?",
"Could this break existing features?",
"Does it introduce a security problem?"]})],
"check": [
q("What is a commit?", ["A type of branch", "A saved version — 'save this, it works'", "An error message", "A deployment"], 1),
q("When should you commit?", ["Once a month", "Before letting AI make any large change", "Only when finished", "Never"], 1),
q("What is a branch for?", ["Storing images", "Experimenting without risking your main working version", "Making code faster", "Hosting"], 1),
q("Reviewing AI changes before accepting them is:", ["A sign you don't trust AI", "The same review any professional team applies to a contributor's work", "Unnecessary", "Only for large teams"], 1)]},
# 12 --------------------------------------------------------------------------
{"id": "vibe12", "n": 12, "title": "From Prototype to Production", "mins": 55, "icon": "Zap",
"summary": "Turning something that works on your machine into something real people can use: testing, security, environment variables, deployment and performance.",
"keyWords": ["Prototype", "Production", "Deployment", "Environment variables", "Performance", "Testing"],
"sections": [
sec("chart", "Prototype and Production", [
"A prototype is an early version of an idea. It does not need to be perfect — its job is to prove the concept.",
"Production means real users depend on it. The standard rises: it must handle mistakes, protect data, work on slow connections and stay up when you are asleep.",
"Most first projects never make this crossing, and that is fine. Knowing what the crossing requires is what separates a hobbyist from a builder."]),
sec("mark", "Test Before You Launch", [
"Work through the list: buttons, forms, login, mobile layout, links, API connections, and error situations.",
"That last one is what people skip. What happens when someone submits an empty form, loses connection halfway, or types text where a number belongs?",
"Test on a real phone, not just a narrow browser window. They are not the same, and your users are mostly on phones."]),
sec("law", "Security and Environment Variables", [
"Before launch: protect passwords, protect API keys, validate user input, keep software updated, and use secure connections.",
"An environment variable is a safe place to keep secret information your application needs — kept outside your code so it is never published.",
"Publishing a secret key in public code is one of the most common and most expensive beginner mistakes. Automated bots scan for exposed keys constantly, and the bill arrives fast."]),
sec("steps", "Deploy, Then Make It Fast", [
"Deployment means putting your application online. The shape is always the same: build, test, deploy, share.",
"Then performance. Optimise images, remove unnecessary code, reduce unnecessary requests, keep pages simple.",
"This matters especially where mobile data is expensive or connections are slow. A heavy page is not just slow — for some users it never loads at all."])],
"check": [
q("What is an environment variable?", ["A type of database", "A safe place for secret information, kept outside your code", "A design setting", "A browser feature"], 1),
q("Which test do people most often skip?", ["Buttons", "Error situations — empty forms, lost connections, wrong input types", "Links", "Login"], 1),
q("Why does page weight matter especially in some regions?", ["It looks unprofessional", "Where data is expensive or connections slow, heavy pages may never load", "It affects colours", "It doesn't"], 1),
q("Publishing a secret API key in public code is dangerous because:", ["It looks untidy", "Automated bots scan for exposed keys constantly", "It slows the app", "It breaks the build"], 1)]},
# 13 --------------------------------------------------------------------------
{"id": "vibe13", "n": 13, "title": "Common Vibe Coding Mistakes", "mins": 45, "icon": "TrendingDown",
"summary": "The eight failure patterns that catch people using AI to build software, and the specific habit that prevents each one.",
"keyWords": ["Over-trust", "Code bloat", "Hallucination", "Security", "Understanding your project"],
"sections": [
sec("law", "Trusting AI Too Much", [
"AI can be wrong while sounding completely certain. There is no hesitation in its voice when it invents something.",
"The habit: check anything that matters. Anything touching money, personal data, security or permanent deletion gets verified independently.",
"Related trap: copying error messages without understanding them. If you do not know why a fix worked, you cannot fix it next time."]),
sec("mark", "Building Too Much At Once", [
"Large requests produce sprawling, tangled applications. Ask for a whole social network and you get something that half works in ways nobody can trace.",
"The habit: one feature at a time, tested before the next.",
"Related trap: not understanding your own project. If AI built everything and you understand none of it, you are stuck the moment something breaks — and something always breaks."]),
sec("read", "Bloat and Hallucination", [
"AI sometimes writes elaborate solutions to simple problems, and sometimes confidently recommends libraries or features that do not exist at all.",
"For bloat, ask directly: \"Is there a simpler way to do this?\" You will be surprised how often there is.",
"For hallucination, verify anything unfamiliar. If the AI suggests a package you have not heard of, check it is real before building on it."]),
sec("target", "Ignoring Security", [
"A website can work perfectly and still be unsafe. Working and secure are separate properties, and only one of them is visible.",
"The habit: make security part of building, not a step at the end. Ask for a security review as you go.",
"Bad prompts underlie several of these failures. Vague instructions produce confusing results — and then people blame the AI."],
{"t": "The eight mistakes", "b": [
"Trusting AI too much · Giving bad prompts",
"Building everything at once · Not understanding your own project",
"Copying errors without understanding · Creating too much code",
"Using fake libraries · Ignoring security"]})],
"check": [
q("Why is AI being wrong especially dangerous?", ["It happens constantly", "It sounds completely certain while doing it", "It only happens with hard problems", "It doesn't happen"], 1),
q("What is a 'hallucinated library'?", ["A slow package", "A package or feature the AI confidently recommends that doesn't exist", "An outdated library", "A paid library"], 1),
q("Can a working website be unsafe?", ["No, if it works it's fine", "Yes — working and secure are separate properties", "Only on mobile", "Only with databases"], 1),
q("What's the fix for AI producing overly complex code?", ["Accept it", "Ask directly: is there a simpler way to do this?", "Start over", "Use another tool"], 1)]},
# 14 --------------------------------------------------------------------------
{"id": "vibe14", "n": 14, "title": "Advanced Vibe Coding Workflows", "mins": 55, "icon": "LayoutDashboard",
"summary": "Moving from simple prompting to an organised process: breaking big ideas into tasks, planning before building, AI agents, managing context, and reusable prompts.",
"keyWords": ["Task decomposition", "Development plan", "AI agents", "Context", "Prompt library"],
"sections": [
sec("steps", "Break Big Ideas Into Small Tasks", [
"\"Build Facebook\" is not a task; it is a wish. Broken down it becomes: homepage, signup, login, user profile, post system, comments, database, security.",
"Now each piece is buildable, testable and finishable. Progress becomes visible.",
"This is the single most transferable skill in the course, and it applies far beyond software."]),
sec("build", "Plan Before You Build", [
"Before writing any code, ask AI to help produce a plan: features, pages, components, database structure, API requirements and a testing plan.",
"Planning with AI is quick and catches problems while they are still cheap. Discovering a structural flaw after building is expensive; discovering it in a plan costs nothing.",
"Keep the plan somewhere you can return to. It becomes the reference point when you lose your thread — and on a long project you will."]),
sec("chart", "Assistants and Agents", [
"An AI assistant helps with a task you give it. An AI agent can plan and carry out multiple steps using tools — reading files, running commands, checking results.",
"Agents are powerful and require more oversight, not less. A wider blast radius means mistakes travel further.",
"Review changes before accepting them, particularly when several files were touched at once."]),
sec("law", "Managing Context", [
"AI needs to understand your project to make good decisions. Useful context includes requirements, file structure, coding rules, design guidelines and existing features.",
"But more is not automatically better. Irrelevant material distracts the model. Give what is relevant to this task.",
"Then build a personal prompt library — reusable prompts for planning, building, debugging, testing, security review, code explanation and UI improvement. Your best prompts are worth keeping."])],
"check": [
q("What's the difference between an AI assistant and an AI agent?", ["Nothing", "An agent can plan and carry out multiple steps using tools", "Agents are cheaper", "Assistants are newer"], 1),
q("Why plan before building?", ["It's traditional", "Structural flaws are free to fix in a plan and expensive after building", "It impresses people", "AI requires it"], 1),
q("Is more context always better?", ["Yes, always", "No — irrelevant material distracts the model", "Only for large projects", "Only for agents"], 1),
q("Why do agents need more oversight?", ["They're less capable", "A wider blast radius means mistakes travel further", "They're slower", "They cost more"], 1)]},
# 15 --------------------------------------------------------------------------
{"id": "vibe15", "n": 15, "title": "Capstone — Build Your Own AI-Assisted App", "mins": 90, "icon": "Trophy",
"summary": "The final project: choose a real problem, define it, plan it, build it with AI, test, debug, deploy and present it.",
"keyWords": ["Capstone", "Problem definition", "Must-have features", "Deployment", "Presentation"],
"sections": [
sec("target", "Choose a Real Problem", [
"Pick something you actually want to exist: a study planner, a small business manager, an event booking system, a finance tracker, a job application tracker, a school resource platform.",
"Then answer three questions honestly. What problem am I solving? Who has this problem? Why does this application matter?",
"Projects built for a real problem get finished. Projects built to demonstrate skill usually do not."]),
sec("steps", "Define, Then Plan", [
"List your features and split them firmly into must-have and nice-to-have. Everything feels essential until you write it down.",
"Then plan: user flow, pages, features, data, technology choices, and the development tasks in order.",
"Deliberately keep version one small. A finished small application beats an abandoned ambitious one, every time."]),
sec("build", "Build, Test, Debug, Deploy", [
"Build one feature at a time using everything from this course. Test each before moving on.",
"Test properly: features, user experience, mobile layout, errors, security, performance. Then debug systematically rather than by repeatedly asking for a fix.",
"Then deploy it. An application nobody can reach is an exercise; an application on the internet is a product."]),
sec("talk", "Present It", [
"Your presentation covers eight things: the problem, the solution, the target users, how you built it, the AI tools you used, the challenges you hit, what you learned, and a live demonstration.",
"Include what went wrong. The debugging story is usually the most interesting part and the clearest evidence of what you can actually do.",
"By this point you should be able to take an idea and carry it through: idea, plan, prompt, code, test, debug, improve, deploy. You will not know every language or have memorised much code. You will know how to think, how to ask, how to check, and how to finish.",
"That is the outcome that matters: \"I have an idea, and I know how to start building it.\""])],
"check": [
q("What kind of capstone project gets finished?", ["The most technically impressive", "One built for a problem you actually want solved", "The largest", "The one using newest tools"], 1),
q("How should you split your feature list?", ["By difficulty", "Into must-have and nice-to-have", "Alphabetically", "By file size"], 1),
q("Why deploy the capstone?", ["It's required", "An app nobody can reach is an exercise; one on the internet is a product", "It's faster", "For the grade"], 1),
q("Why include what went wrong in your presentation?", ["To seem humble", "The debugging story is the clearest evidence of what you can actually do", "To fill time", "You shouldn't"], 1)]},
]

COURSE = {
    "code": "VIBE-Y1",
    "subject": "Introduction to Vibe Coding",
    "group": "Digital & Technology",
    "cat": "General Courses",
    "year": "All years",
    "term": 1,
    "termLabel": "8–12 weeks · self-paced",
    "title": "Introduction to Vibe Coding: Build Software With AI",
    "tagline": "Turn an idea into a working, deployed application using AI as your coding partner. No prior programming required — you will learn to think, describe, build, test, fix and ship.",
    "months": "8–12 weeks (self-paced)",
    "passMark": None,
    "totalQuestions": 0,
    "examMins": 0,
    "materials": [],
    "units": UNITS,
}


def main():
    with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
        d = fh.read()
    if '"VIBE-Y1"' in d:
        sys.exit("FAIL: course already present")
    anchor = "var gg={"
    if d.count(anchor) != 1:
        sys.exit(f"FAIL: gg catalogue anchor found {d.count(anchor)}x")
    payload = json.dumps({"VIBE-Y1": COURSE}, ensure_ascii=False, separators=(",", ":"))
    d = d.replace(anchor, anchor + payload[1:-1] + ",", 1)
    with open(SRC, "w", encoding="utf-8", errors="surrogateescape") as fh:
        fh.write(d)
    words = sum(len(" ".join(s["p"]).split()) for u in UNITS for s in u["sections"])
    print(f"  units      : {len(UNITS)}")
    print(f"  sections   : {sum(len(u['sections']) for u in UNITS)}")
    print(f"  questions  : {sum(len(u['check']) for u in UNITS)}")
    print(f"  words      : ~{words:,}")


if __name__ == "__main__":
    main()
