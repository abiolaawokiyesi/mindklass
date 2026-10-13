#!/usr/bin/env python3
"""
Advanced Vibe Coding — course injection (20 units).

Built from the "Advanced Vibe Coding" course document. Sits alongside
VIBE-Y1 in the General Courses catalogue under the Digital & Technology
group, and assumes the introductory course as background.
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
{"id": "avibe1", "n": 1, "title": "Advanced Vibe Coding Foundations", "mins": 60, "icon": "Target",
"summary": "The three levels of AI-assisted development, the shift from prompting to engineering, the habits that define the advanced practitioner, and why speed without understanding creates debt.",
"keyWords": ["Engineering", "Specification", "Technical debt", "Developer judgement", "Complexity"],
"sections": [
sec("chart", "Three Levels of AI-Assisted Development", [
"Level one is code generation. You ask for a login form and get one. Useful, but the AI knows nothing about your architecture, security requirements, database or business rules.",
"Level two is AI-assisted development. You give the AI context about the project and use it to create features, explain code, debug, generate tests, refactor, write documentation and design APIs. You stay actively involved throughout.",
"Level three is AI-assisted engineering. The AI participates across the whole lifecycle — requirements, architecture, planning, implementation, testing, debugging, security analysis, review, deployment and optimisation — while you direct, validate and govern.",
"This course lives at level three. The distinction is not how much the AI does; it is how much you are responsible for."]),
sec("law", "From Prompting to Engineering", [
"Compare \"build me an ecommerce application\" with an engineering specification: purpose, users, roles, functional requirements, non-functional requirements, technology choices, database and API requirements, security constraints, performance expectations, acceptance criteria and testing requirements.",
"Better software usually comes from better problem definition, not longer prompts. This is the central claim of the course, and most of what follows is a consequence of it.",
"A vague request forces the AI to invent the missing decisions. It will invent confidently, and its inventions will be generic."]),
sec("mark", "Managing Complexity", [
"AI can generate thousands of lines quickly, which creates a new and specific problem: development speed can outrun understanding.",
"The symptoms are recognisable — technical debt, duplicated logic, inconsistent naming, oversized components, unnecessary dependencies, unclear architecture, dead code, fragile integrations and undocumented assumptions.",
"\"The AI made it work\" is not the same claim as \"the software is well engineered.\" Only one of those survives contact with a second developer, a traffic spike, or your own attention six months later."]),
sec("target", "Developer Judgement", [
"AI will suggest technologies, architectures, algorithms, libraries, database structures and security approaches. Your job is to evaluate them.",
"Ask: does this actually solve the problem? Is it unnecessarily complex? Is it secure? Could another developer maintain it? What happens when traffic increases, when input is invalid, when an external service fails? What assumptions is the AI making?",
"That last question is the most valuable and the least asked. Every generated solution rests on assumptions the AI did not state."],
{"t": "The seven habits", "b": [
"Think before generating · Break large problems into smaller ones",
"Give AI enough context to decide well · Never assume generated code is correct",
"Verify important decisions independently · Test everything that matters",
"Keep humans responsible for final decisions"]})],
"check": [
q("What distinguishes level-three AI-assisted engineering?", ["The AI writes more code", "AI participates across the full lifecycle while you direct, validate and govern", "No human involvement", "It uses better models"], 1),
q("Better software usually comes from:", ["Longer prompts", "Better problem definition", "More powerful models", "Faster typing"], 1),
q("What new problem does fast AI generation create?", ["Higher costs", "Development speed outrunning understanding", "Slower computers", "Fewer features"], 1),
q("Which question about AI suggestions is most valuable and least asked?", ["Is it fast?", "What assumptions is the AI making?", "Is it popular?", "Is it free?"], 1)]},
# 2 ---------------------------------------------------------------------------
{"id": "avibe2", "n": 2, "title": "AI Coding Agents & Autonomous Workflows", "mins": 60, "icon": "Cpu",
"summary": "What an agent is, the agent loop, how to delegate work safely, project-level instructions, tool permissions as a security concern, and reviewing autonomous changes.",
"keyWords": ["Coding agent", "Agent loop", "Delegation", "Tool permissions", "Review process"],
"sections": [
sec("chart", "What Is an AI Coding Agent?", [
"Distinguish four things: chat-based AI answers questions; code completion suggests the next lines; a coding assistant works on tasks you specify; a coding agent can act.",
"An agent can inspect files, search a repository, create and modify files, execute commands, run tests, read errors, make corrections and repeat.",
"Your role shifts from writing every instruction to orchestrating a process. That is more leverage and more responsibility at the same time."]),
sec("steps", "The Agent Loop", [
"Understand the task, inspect the environment, create a plan, modify the project, run tools, observe results, identify problems, make corrections, test, then report what changed.",
"Knowing this loop matters because it tells you where an agent goes wrong. Most failures are a bad plan built on an incomplete inspection — not a bad edit.",
"When an agent is thrashing, intervene at the plan, not at the code."]),
sec("law", "Delegating Well", [
"Good agent tasks look like: create the database model; implement the authentication API; add validation to the registration endpoint; write integration tests for checkout; investigate why these tests fail.",
"Each needs a clear objective, relevant context, boundaries, constraints, expected outputs and acceptance criteria.",
"Then give the project standing instructions: coding conventions, folder structure, architectural rules, testing requirements, forbidden practices, naming conventions, dependency policies and security requirements. Written once, applied every time."]),
sec("mark", "Tool Permissions and Review", [
"Agents interact with file systems, terminals, package managers, testing frameworks, Git, databases and APIs. Treat those permissions as part of your security model, because that is exactly what they are.",
"An agent that can run arbitrary commands can do arbitrary damage — usually by accident, occasionally because something in its input told it to.",
"Review before committing: inspect changed files, understand the reason for each change, review the diff, run tests, test important user flows, look for unintended side effects, check security implications, and only then commit."])],
"check": [
q("Where do most agent failures originate?", ["Bad individual edits", "A bad plan built on incomplete inspection", "Slow models", "Missing tools"], 1),
q("Tool permissions for agents should be treated as:", ["A convenience setting", "Part of your security model", "Irrelevant", "A performance option"], 1),
q("A good agent task needs all of these EXCEPT:", ["A clear objective", "Acceptance criteria", "As much of the repository as possible", "Boundaries and constraints"], 2),
q("When an agent is thrashing, you should intervene at:", ["The code", "The plan", "The model choice", "The test suite"], 1)]},
# 3 ---------------------------------------------------------------------------
{"id": "avibe3", "n": 3, "title": "Advanced Prompt Engineering for Developers", "mins": 55, "icon": "PenLine",
"summary": "Why developer prompts differ, the anatomy of a strong coding prompt, context engineering, explicit constraints, specification prompts, and a reusable prompt library.",
"keyWords": ["Prompt anatomy", "Context engineering", "Constraints", "Specification prompt", "Templates"],
"sections": [
sec("law", "The Anatomy of a Strong Coding Prompt", [
"A reusable structure: role, context, objective, requirements, constraints, inputs, expected output, acceptance criteria.",
"Worked example: \"You are working inside an existing TypeScript API. Add password-reset functionality. Use the existing authentication architecture. Do not introduce a new framework. Tokens must expire. Do not expose whether an email exists. Add unit and integration tests.\"",
"Note how short that is. The aim is precision, not verbosity — every clause removes a decision the model would otherwise guess at."]),
sec("read", "Context Engineering", [
"Provide what the AI actually needs: relevant source files, database schema, API contracts, architectural decisions, existing patterns, error messages, tests, documentation.",
"Equally important is what to leave out. More context is not automatically better — irrelevant material dilutes attention and can actively mislead the model.",
"Curating context is a real skill and it is the one that most separates capable practitioners from frustrated ones."]),
sec("target", "Constraints and Specification Prompts", [
"State explicitly what to use and what not to use: technologies, performance requirements, security requirements, coding conventions, backward compatibility, API behaviour, database rules.",
"Then use specification prompts that force a plan before implementation. Ask the AI to analyse the requirement, identify ambiguities, list assumptions, propose an architecture, identify affected files, describe implementation steps, identify risks, define tests — and wait for approval before coding.",
"That final instruction is the whole technique. It converts an unpredictable generation into a reviewable proposal."]),
sec("build", "Build a Prompt Library", [
"Maintain reusable templates for feature implementation, debugging, refactoring, code review, test generation, security review, performance analysis, documentation and architecture evaluation.",
"A good prompt is an asset. Rewriting it each time is waste, and inconsistent prompts produce inconsistent code.",
"Treat the library as living: when a prompt produces a poor result, fix the prompt rather than just the output."])],
"check": [
q("The aim of a strong coding prompt is:", ["Maximum length", "Precision — each clause removes a guessed decision", "Politeness", "Technical vocabulary"], 1),
q("Is more context always better?", ["Yes", "No — irrelevant material dilutes attention and can mislead", "Only for small projects", "Only with agents"], 1),
q("What makes a specification prompt work?", ["Its length", "It ends by requiring approval before any code is written", "It uses formal language", "It names the model"], 1),
q("When a prompt produces a poor result you should:", ["Fix the output only", "Fix the prompt", "Change models", "Accept it"], 1)]},
# 4 ---------------------------------------------------------------------------
{"id": "avibe4", "n": 4, "title": "Planning Complex Applications With AI", "mins": 60, "icon": "ClipboardList",
"summary": "Requirements gathering, using AI as a requirements analyst, architecture planning, feature decomposition, technical specifications and phased roadmaps.",
"keyWords": ["Functional requirements", "Non-functional requirements", "Decomposition", "Specification", "Roadmap"],
"sections": [
sec("chart", "Functional and Non-Functional Requirements", [
"Functional requirements describe what the system must do: users can register, users can log in, customers can create orders, administrators can manage products.",
"Non-functional requirements describe how it must behave: secure authentication, acceptable response time, accessibility, reliability, scalability, observability.",
"Teams routinely capture the first and neglect the second, then discover in production that \"it works\" and \"it works acceptably\" were different requirements all along."]),
sec("talk", "AI as Requirements Analyst", [
"Before asking for code, ask the AI to interrogate the requirements: what is missing, what language is ambiguous, which requirements conflict, what edge cases exist, what user roles are implied, what workflows and business rules follow.",
"This is one of the highest-value and least-used applications of AI in software work. Requirements defects are the most expensive kind, because everything downstream is built on them.",
"Spending twenty minutes here regularly saves days."]),
sec("steps", "Decomposition", [
"Large features must be divided. \"Online checkout\" becomes: cart management, order creation, inventory verification, payment initialisation, payment confirmation, order status updates, email confirmation, failure handling, refund handling, testing.",
"Ten tasks, each independently buildable and verifiable. Note that three of them concern things going wrong — that ratio is normal and beginners consistently underestimate it.",
"Decomposition is also what makes agent delegation safe: a small task has a small blast radius."]),
sec("build", "Specifications and Roadmaps", [
"A technical specification contains purpose, requirements, architecture, data models, APIs, UI behaviour, error handling, security requirements and testing strategy.",
"Then sequence the work in phases: foundation, authentication, core data model, business logic, frontend, integrations, testing, security, deployment.",
"Order matters. Authentication before business logic, and data model before the features that depend on it, avoids the expensive rework of retrofitting foundations."])],
"check": [
q("Which is a non-functional requirement?", ["Users can register", "Acceptable response time", "Admins can manage products", "Customers can create orders"], 1),
q("Why are requirements defects the most expensive?", ["They take longest to write", "Everything downstream is built on them", "They need more meetings", "They're hardest to find"], 1),
q("In the checkout decomposition, what proportion concerned failures?", ["None", "Three of ten — and that ratio is normal", "All of them", "One"], 1),
q("Why does phase order matter?", ["It looks organised", "It avoids expensive rework retrofitting foundations", "It's faster to type", "It doesn't"], 1)]},
# 5 ---------------------------------------------------------------------------
{"id": "avibe5", "n": 5, "title": "Context Engineering & AI Memory", "mins": 50, "icon": "FileText",
"summary": "Context windows and their limits, project knowledge as persistent memory, documentation as an external memory system, codebase indexing, and maintaining a single source of truth.",
"keyWords": ["Context window", "Project knowledge", "Documentation", "Indexing", "Source of truth"],
"sections": [
sec("law", "Context Windows", [
"AI models operate within a finite context. Long conversations exceed it, and detail degrades — often silently, which is worse than failing loudly.",
"The practical consequence: critical information must not live only inside a chat. Anything you would be upset to lose belongs in a file.",
"Assume every conversation is temporary. Build so that it does not matter."]),
sec("build", "Documentation as AI Memory", [
"Maintain persistent project documentation: overview, architecture, database schema, API documentation, coding conventions, important decisions, business rules, setup instructions, deployment information.",
"Well-structured documentation is an external memory system. Rather than re-explaining your authentication architecture in every session, point the AI at the document.",
"This has a pleasant side effect. Documentation written for an AI is documentation written for the next human, including future you."]),
sec("read", "Indexing and Consistency", [
"AI tools can locate relevant files, functions, classes, components, database models and API routes. Understanding how yours does this helps you feed it well.",
"Blindly handing over an entire repository is rarely effective — it is the context-dilution problem again, at scale.",
"Establish a single source of truth for architectural decisions, naming, APIs, database rules, business logic and component patterns. Where two documents disagree, the AI will pick one arbitrarily, and you will not be told which."])],
"check": [
q("Why is context degradation dangerous?", ["It's slow", "It often happens silently rather than failing loudly", "It costs more", "It breaks the build"], 1),
q("Where should critical project information live?", ["In the chat conversation", "In persistent project documentation", "In your memory", "In commit messages"], 1),
q("Why not hand the AI your entire repository?", ["It's too slow", "Context dilution — irrelevant material misleads", "It costs too much", "Tools forbid it"], 1),
q("If two project documents disagree, the AI will:", ["Ask you", "Pick one arbitrarily without telling you", "Refuse to proceed", "Merge them correctly"], 1)]},
# 6 ---------------------------------------------------------------------------
{"id": "avibe6", "n": 6, "title": "AI-Assisted Software Architecture", "mins": 60, "icon": "Layers",
"summary": "Architecture styles and when each fits, separation of concerns, modularity, evaluating trade-offs, and selecting technology against requirements rather than popularity.",
"keyWords": ["Monolith", "Microservices", "Separation of concerns", "Modularity", "Trade-offs"],
"sections": [
sec("chart", "Architecture Styles", [
"The main options: monolithic, modular monolith, service-oriented, microservices, serverless and event-driven.",
"The emphasis belongs on why an architecture is selected rather than what it is called. Each solves particular problems and imposes particular costs.",
"For most applications built by small teams, a well-structured modular monolith is the right answer and microservices are an expensive mistake dressed as sophistication."]),
sec("law", "Separation of Concerns and Modularity", [
"Separate presentation, business logic, data access, external integrations and infrastructure. This stops one part of the application becoming responsible for everything.",
"Then think in modules, interfaces, services, reusable components and dependency boundaries. A boundary you can name is a boundary you can change behind.",
"Poor separation is the most common structural flaw in AI-generated applications, because each request is answered locally without regard for the overall shape."]),
sec("target", "Trade-offs and Technology Selection", [
"AI will often propose sophisticated architecture when something simpler would serve better. It has read a great deal of writing about large systems.",
"Interrogate every proposal: does the application need this complexity, what is the operational cost, how difficult is debugging, how difficult is deployment, what happens if one service fails?",
"When comparing frameworks, databases, cloud platforms, authentication providers or hosting, compare against your actual requirements. Popularity is not a requirement, and neither is what a company a thousand times your size chose."])],
"check": [
q("For most small-team applications, the right default is:", ["Microservices", "A well-structured modular monolith", "Serverless everything", "Event-driven"], 1),
q("The most common structural flaw in AI-generated applications is:", ["Slow code", "Poor separation of concerns", "Too few features", "Bad naming"], 1, "Each request is answered locally without regard for overall shape."),
q("Why does AI often propose sophisticated architecture?", ["It's programmed to", "It has read a great deal of writing about large systems", "It's more profitable", "Simple options don't exist"], 1),
q("Technology should be selected against:", ["Popularity", "Your actual requirements", "What large companies use", "Newest release date"], 1)]},
# 7 ---------------------------------------------------------------------------
{"id": "avibe7", "n": 7, "title": "Full-Stack Vibe Coding", "mins": 75, "icon": "Globe",
"summary": "Bringing frontend, backend, APIs, databases, authentication and state management together into one coherent working system.",
"keyWords": ["Component architecture", "Controllers", "REST", "Authentication", "State management"],
"sections": [
sec("build", "Frontend and Backend", [
"On the frontend: component architecture, routing, forms, validation, loading states, error states, responsive design and reusable UI.",
"Loading and error states are the ones people skip. An interface that shows nothing while waiting and nothing when failing is not finished — it just looks finished on a fast connection with everything working.",
"On the backend: routes, controllers, services, validation, business logic and error handling. Validation belongs on both sides, for different reasons: the frontend for helpfulness, the backend for safety."]),
sec("chart", "APIs and Databases", [
"Frontend and backend communicate over HTTP using JSON, generally following REST patterns, with authentication and error handling throughout.",
"The database layer covers creating records, querying them, relationships, transactions and validation.",
"Transactions deserve attention. When an operation must either fully succeed or fully fail — such as taking payment and creating an order — a transaction is what prevents half-completed states that are painful to clean up."]),
sec("law", "Authentication and State", [
"Build registration, login, logout, protected routes, sessions or tokens, and role-based access. Role-based access is where most AI-generated authentication is weakest: it usually checks whether you are logged in, not whether you are allowed.",
"Then state management: local state, server state, global state, caching and synchronisation.",
"Confusing server state with local state is a leading cause of subtle bugs — data displayed that no longer matches what the database holds."])],
"check": [
q("Which frontend states do people most often skip?", ["Success states", "Loading and error states", "Form fields", "Buttons"], 1),
q("Why validate on both frontend and backend?", ["Redundancy for its own sake", "Frontend for helpfulness, backend for safety", "It's traditional", "AI requires it"], 1),
q("What is the weakest point of most AI-generated authentication?", ["Password hashing", "It checks whether you're logged in, not whether you're allowed", "Login forms", "Logout"], 1),
q("What prevents half-completed states in a payment-and-order operation?", ["Caching", "A transaction", "An index", "A webhook"], 1)]},
# 8 ---------------------------------------------------------------------------
{"id": "avibe8", "n": 8, "title": "Working With Existing Codebases", "mins": 60, "icon": "Search",
"summary": "Understanding software you did not write: codebase discovery, using AI to explore before changing, safe modification, refactoring, and why legacy code deserves respect.",
"keyWords": ["Codebase discovery", "Exploration", "Safe modification", "Refactoring", "Legacy code"],
"sections": [
sec("read", "Discovery Before Change", [
"Investigate first: directory structure, package configuration, entry points, routing, database models, environment variables, tests and build configuration.",
"Ask the AI to explain rather than edit — how the application starts, where authentication happens, where database queries occur, where API requests are handled, how components communicate.",
"The instinct to start changing immediately is strong and almost always wrong."]),
sec("steps", "The Safe Sequence", [
"Explore, understand, plan, modify, test, review. Every step earns the next one.",
"Skipping straight to modify is how a small requested change breaks three features nobody mentioned, because the code that looked unused was not.",
"On an unfamiliar codebase, small verified changes beat large confident ones every time."]),
sec("law", "Refactoring and Legacy Code", [
"AI is good at spotting duplication, oversized functions, complex components, outdated patterns, unnecessary dependencies and poor naming.",
"But legacy code should not be rewritten reflexively. It usually encodes hard-won knowledge about edge cases nobody documented — the strange condition in the middle of that function may be the only thing handling a real customer scenario.",
"The disciplined approach: document existing behaviour, add tests first, make small changes, refactor incrementally, preserve functionality. Tests before refactoring are what make the whole thing safe."])],
"check": [
q("What should you ask AI to do first with an unfamiliar codebase?", ["Refactor it", "Explain how it works", "Add features", "Delete dead code"], 1),
q("The safe sequence for modifying unfamiliar code is:", ["Modify, test, hope", "Explore, understand, plan, modify, test, review", "Rewrite from scratch", "Ask AI to do everything"], 1),
q("Why not rewrite legacy code reflexively?", ["It's slow", "It usually encodes undocumented edge cases", "It's expensive", "Tools don't support it"], 1),
q("What makes refactoring safe?", ["Working quickly", "Adding tests before you refactor", "Using a better model", "Doing it all at once"], 1)]},
# 9 ---------------------------------------------------------------------------
{"id": "avibe9", "n": 9, "title": "Advanced Debugging & Problem Solving", "mins": 60, "icon": "AlertTriangle",
"summary": "Systematic debugging: the observe-to-verify cycle, reading every class of error, root-cause analysis, what AI needs to help, and regression testing.",
"keyWords": ["Root cause", "Stack trace", "Reproduction", "Hypothesis", "Regression"],
"sections": [
sec("steps", "The Debugging Cycle", [
"Observe, reproduce, isolate, hypothesise, test, fix, verify. Each step in order.",
"Reproduce is the one people skip, and skipping it makes everything after it guesswork. A bug you cannot reproduce is a bug you cannot confirm you have fixed.",
"Isolation is what turns a large mystery into a small one. Halve the search space repeatedly rather than staring at the whole system."]),
sec("read", "Reading Every Kind of Error", [
"You will meet compiler errors, runtime errors, HTTP errors, database errors, stack traces, browser console errors and build failures. Each has its own conventions and reading them is a learnable skill.",
"A stack trace is a history: the sequence of calls that led to the failure. The top frame is where it broke; further down is how it got there. Often the real fault is not at the top.",
"Feed the AI the exact error, the relevant code, reproduction steps, expected behaviour, actual behaviour and environment information."]),
sec("target", "Root Cause, Not Symptom", [
"A checkout button fails. The cause could be frontend validation, the API request, authentication, a database transaction, the payment provider, or a wrong environment variable.",
"Patching the symptom leaves the cause in place, so the same fault reappears wearing different clothes.",
"After every fix, run regression checks: confirm the fix worked and confirm nothing else broke. AI-generated fixes have a particular tendency to solve locally and break elsewhere, because the model sees the fragment you showed it and not the system."])],
"check": [
q("Which debugging step do people most often skip?", ["Observe", "Reproduce", "Fix", "Verify"], 1, "Without reproduction, everything after is guesswork."),
q("In a stack trace, the real fault is:", ["Always at the top", "Often further down than the top frame", "Always at the bottom", "Never visible"], 1),
q("Why do AI-generated fixes tend to break other things?", ["The models are poor", "The model sees the fragment you showed it, not the system", "They're too fast", "They ignore tests"], 1),
q("Patching a symptom rather than the cause means:", ["The bug is resolved", "The same fault reappears in a different form", "Performance improves", "Tests pass permanently"], 1)]},
# 10 --------------------------------------------------------------------------
{"id": "avibe10", "n": 10, "title": "Database Design & Data Workflows", "mins": 65, "icon": "BarChart2",
"summary": "Schema fundamentals, data modelling from requirements, relationships, migrations, query patterns, layered validation and verifying AI optimisation advice.",
"keyWords": ["Schema", "Foreign key", "Relationships", "Migration", "Indexes", "Transactions"],
"sections": [
sec("build", "Fundamentals and Modelling", [
"Tables, columns, primary keys, foreign keys, indexes, constraints and relationships are the vocabulary. Constraints in particular are underused — a rule enforced by the database cannot be bypassed by a bug in application code.",
"Turn requirements into models. An ecommerce application typically needs users, products, categories, carts, orders, order items and payments.",
"Note that order items exists separately from orders. Recognising when a relationship needs its own table is the core skill of data modelling."]),
sec("chart", "Relationships and Migrations", [
"Three shapes: one-to-one, one-to-many and many-to-many. Many-to-many always requires a joining table, which is where the order-items example comes from.",
"Migrations make schema changes controlled and reproducible. Editing a production database by hand is how teams end up with environments that quietly differ.",
"Every schema change should be a migration, in version control, applied the same way everywhere."]),
sec("law", "Queries, Validation and Optimisation", [
"Query work covers filtering, sorting, joins, aggregation, pagination and transactions. Pagination is not decoration — a query that returns everything works fine on your test data and falls over on real data.",
"Validation belongs at three levels: frontend for user experience, backend for security, database constraints for integrity. They serve different purposes and none replaces another.",
"AI can suggest indexes, query improvements, schema changes and caching strategies. Verify against real performance data — an index that helps one query can slow every write, and that trade-off depends on your actual usage, which the AI cannot see."])],
"check": [
q("Why are database constraints valuable?", ["They're faster", "A rule enforced by the database can't be bypassed by an application bug", "They save space", "They're required"], 1),
q("A many-to-many relationship requires:", ["A foreign key only", "A joining table", "An index", "A transaction"], 1),
q("Why does pagination matter?", ["It looks better", "A query returning everything works on test data and fails on real data", "It's faster to write", "It's required by REST"], 1),
q("Why verify AI index suggestions against real data?", ["AI is unreliable", "An index helping one query can slow every write — the trade-off depends on your usage", "Indexes are expensive", "They're always wrong"], 1)]},
# 11 --------------------------------------------------------------------------
{"id": "avibe11", "n": 11, "title": "API & Third-Party Integrations", "mins": 60, "icon": "Share2",
"summary": "REST methods and status codes, API contracts, webhooks, SDK choices, payment architecture, and designing for external failure.",
"keyWords": ["REST", "API contract", "Webhook", "SDK", "Idempotency", "Rate limits"],
"sections": [
sec("chart", "REST and API Contracts", [
"The verbs — GET, POST, PUT or PATCH, DELETE — plus status codes, headers, authentication, request bodies and response formats.",
"An API contract defines the endpoint, method, parameters, request schema, response schema, errors and authentication requirements. Writing it before implementation means frontend and backend can proceed in parallel without guessing at each other.",
"Contracts also give AI something precise to build against, which measurably improves what it generates."]),
sec("build", "Webhooks and Payments", [
"A webhook is how an external service notifies your application that something happened: a payment succeeded, a subscription was cancelled, a delivery updated, an email bounced.",
"Payment integration follows a specific architecture: initialisation, confirmation, webhook verification, failed payments, refunds and transaction records.",
"Webhook verification is the security-critical step. An unverified webhook endpoint is a public URL where anyone can claim a payment succeeded — and applications have been drained exactly that way."]),
sec("law", "Designing for External Failure", [
"External services will time out, rate-limit you, go down, return invalid responses, and receive your request twice.",
"Handle each deliberately. Idempotency in particular: if a request arrives twice, the outcome must be the same as if it arrived once. Otherwise a retried payment charges the customer twice.",
"AI-generated integration code routinely handles only the success path. Ask specifically: what happens when this service fails, and what happens when this request is duplicated?"])],
"check": [
q("What makes webhook verification security-critical?", ["It's slow otherwise", "Unverified, anyone can claim a payment succeeded", "It's required by REST", "It improves performance"], 1),
q("What does idempotency guarantee?", ["Faster requests", "A duplicated request has the same outcome as a single one", "Better security headers", "Lower cost"], 1),
q("Why write an API contract before implementation?", ["It's traditional", "Frontend and backend proceed in parallel without guessing", "It's faster to type", "Tools require it"], 1),
q("AI-generated integration code typically handles:", ["All failure modes", "Only the success path", "Only failures", "Nothing"], 1)]},
# 12 --------------------------------------------------------------------------
{"id": "avibe12", "n": 12, "title": "Building AI-Powered Applications", "mins": 70, "icon": "Sparkles",
"summary": "Applications that themselves use AI: model APIs, chat interfaces, structured outputs, embeddings, retrieval-augmented generation, agents and overall architecture.",
"keyWords": ["LLM API", "Structured output", "Embeddings", "RAG", "Streaming", "Tokens"],
"sections": [
sec("build", "Model APIs and Chat Interfaces", [
"Working with an LLM API means model requests, prompts, system instructions, user messages, responses, token usage and model selection.",
"A usable chat interface needs conversation history, streaming responses, loading states, error handling and message persistence. Streaming matters more than it appears — a response that appears word by word feels dramatically faster than the same response delivered whole.",
"Token usage is your cost model. Understand it before you launch, not after the first invoice."]),
sec("law", "Structured Outputs", [
"For extracting data, classification, generating objects or automating workflows, you need predictable machine-readable responses rather than prose.",
"Request a specific format explicitly, then validate what comes back. Never assume the model returned valid structured data — it usually does, and your application must survive the times it does not.",
"This single discipline separates AI features that work in production from demos that break in front of users."]),
sec("chart", "Embeddings, RAG and Agents", [
"Embeddings let applications compare meaning rather than exact words, which is what makes semantic search possible.",
"The RAG workflow: documents, to chunks, to embeddings, to vector search, to relevant context, to the model, to an answer. Its limitation is that retrieval quality caps everything — if the wrong passages are retrieved, no model can rescue the answer.",
"Agent systems reason about tasks, select tools, retrieve information, perform actions and observe results. Architecturally you will end up with a frontend, backend, model layer, prompt layer, retrieval layer, data storage, observability and security controls."])],
"check": [
q("Why does streaming matter in a chat interface?", ["It's cheaper", "A response appearing word by word feels dramatically faster", "It's more accurate", "It uses fewer tokens"], 1),
q("When requesting structured output you must:", ["Trust the format", "Validate what comes back", "Use a larger model", "Avoid JSON"], 1),
q("The main limitation of RAG is:", ["Model size", "Retrieval quality caps everything downstream", "Cost", "Speed"], 1),
q("Embeddings allow applications to:", ["Compress files", "Compare meaning rather than exact words", "Encrypt data", "Speed up queries"], 1)]},
# 13 --------------------------------------------------------------------------
{"id": "avibe13", "n": 13, "title": "Testing AI-Generated Software", "mins": 60, "icon": "ClipboardCheck",
"summary": "Why testing matters more with AI, the unit-integration-end-to-end pyramid, judging AI-generated tests, edge cases, and test-driven AI workflows.",
"keyWords": ["Unit test", "Integration test", "End-to-end", "Edge cases", "Test-driven"],
"sections": [
sec("law", "Why Testing Matters More, Not Less", [
"AI makes development faster. It also makes producing incorrect software faster. Volume rises; the error rate does not fall to zero.",
"Testing is what converts speed into reliable speed. Without it you are simply generating unverified code more efficiently.",
"This is the module people skip and later wish they had not."]),
sec("chart", "The Three Levels", [
"Unit tests cover individual functions, services, utilities and business rules. Integration tests cover interactions — API and database, services, authentication, external integrations. End-to-end tests simulate complete journeys: register, log in, create item, checkout, receive confirmation.",
"Each catches a different class of failure. Unit tests will not notice that two correct components disagree about a data format.",
"Weight toward the cheap fast levels, but do not skip end-to-end entirely: it is the only level that tests what the user actually experiences."]),
sec("mark", "AI-Generated Tests and Edge Cases", [
"AI generates test cases readily. Judge whether they test meaningful behaviour — it is entirely possible to produce a suite with excellent coverage numbers that asserts almost nothing of value.",
"Test the awkward cases explicitly: empty values, invalid inputs, duplicate records, unauthorised access, network failure, missing data, extreme values, concurrent requests.",
"Unauthorised access belongs on that list and is routinely absent from AI-generated suites. A test that confirms the right user can see their data is only half the test; the other half confirms the wrong user cannot.",
"Consider working test-first: define the tests, then ask AI to implement code satisfying them. It gives the model an unambiguous target and gives you an objective completion signal."])],
"check": [
q("Why does testing matter more with AI, not less?", ["Models are unreliable", "AI makes producing incorrect software faster too", "Tests are cheaper now", "It doesn't"], 1),
q("Which failure would unit tests typically miss?", ["A broken function", "Two correct components disagreeing about data format", "A syntax error", "A bad calculation"], 1),
q("What is commonly absent from AI-generated test suites?", ["Happy-path tests", "Unauthorised access tests", "Unit tests", "Assertions"], 1),
q("What is the benefit of writing tests first?", ["It's faster", "It gives the model an unambiguous target and you an objective completion signal", "It's required", "Fewer tests needed"], 1)]},
# 14 --------------------------------------------------------------------------
{"id": "avibe14", "n": 14, "title": "Security for Vibe Coders", "mins": 70, "icon": "ShieldCheck",
"summary": "Authentication versus authorisation, secret handling, input validation, the common vulnerability classes, the specific flaws AI code tends to introduce, and a review workflow.",
"keyWords": ["Authorisation", "Secrets", "Injection", "Access control", "Security review"],
"sections": [
sec("law", "Authentication vs Authorisation", [
"Authentication asks who are you. Authorisation asks what are you allowed to do. They are different problems and conflating them is among the most damaging mistakes in application security.",
"Broken access control — where a logged-in user can reach another user's data by changing an identifier in a URL — is consistently one of the most common serious vulnerabilities found in real applications.",
"Every endpoint returning user data must check not merely that someone is logged in, but that this particular user may see this particular record."]),
sec("mark", "Secrets and Input Validation", [
"API keys, database passwords, tokens and credentials belong in environment variables, never hard-coded in source. Anything committed to a repository should be assumed public forever, because history is difficult to erase and bots scan constantly.",
"Validate untrusted input at system boundaries. \"Untrusted\" means anything from a user, a URL, an upload, or an external service — including services you trust, which can be compromised.",
"Validation at the boundary is what prevents malformed data spreading through your system and surfacing somewhere unrecognisable."]),
sec("target", "The Vulnerabilities AI Tends to Introduce", [
"The general classes: SQL injection, cross-site scripting, broken access control, insecure authentication, exposed secrets, insecure file uploads, insecure API endpoints and dependency vulnerabilities.",
"AI-generated code has characteristic weaknesses worth reviewing for specifically: missing authorisation checks, insecure defaults, unsafe string construction, exposed sensitive data, overly permissive APIs and inadequate validation.",
"There is a reason for this pattern. The model optimises for code that satisfies the request, and \"works\" is visible while \"secure\" is not.",
"Review workflow: identify threats, analyse the attack surface, review code, review dependencies, review configuration, test, remediate, verify."])],
"check": [
q("Authorisation answers which question?", ["Who are you?", "What are you allowed to do?", "Are you logged in?", "Is your password correct?"], 1),
q("A logged-in user changing an ID in a URL to see another user's data is:", ["Cross-site scripting", "Broken access control", "SQL injection", "A dependency flaw"], 1),
q("Anything committed to a repository should be assumed:", ["Private", "Public forever", "Encrypted", "Temporary"], 1),
q("Why does AI-generated code tend toward insecurity?", ["Malicious training", "It optimises for satisfying the request; 'works' is visible, 'secure' is not", "Old models", "Poor prompts only"], 1)]},
# 15 --------------------------------------------------------------------------
{"id": "avibe15", "n": 15, "title": "Git & Collaborative AI Development", "mins": 55, "icon": "Users",
"summary": "Version control discipline when AI is producing changes: logical commits, feature branches, pull requests, code review criteria and team AI policies.",
"keyWords": ["Commits", "Branches", "Pull request", "Code review", "AI policy"],
"sections": [
sec("build", "Commits and Branches", [
"Branches, commits, merges, rebases, tags and pull requests remain the machinery. What changes with AI is the volume passing through it.",
"A commit should represent one logical change, not a heap of unrelated AI edits. Otherwise history becomes unreadable, and unreadable history is useless precisely when you need it most — during an incident.",
"Isolate work on branches: features, bug fixes, refactors, experiments. Experiments especially, since AI makes ambitious experiments cheap."]),
sec("mark", "Pull Requests and Review", [
"AI genuinely helps with PR descriptions, change summaries, test summaries and review preparation. These are tasks where it saves real time at low risk.",
"Review remains human work. Assess correctness, architecture, security, maintainability, performance and tests.",
"Maintainability deserves emphasis. Code that works but nobody understands is a liability with a delayed invoice — and AI produces this kind of code readily, because it never has to maintain anything."]),
sec("law", "Team Policies", [
"Teams using AI need explicit agreements: AI usage policies, coding standards, review requirements, shared project instructions and ownership rules.",
"Ownership is the one that bites. When AI wrote it and nobody reviewed it properly, responsibility diffuses until nobody feels accountable for the outcome.",
"Establish plainly: whoever submits AI-generated code owns it exactly as if they had written it themselves."])],
"check": [
q("A commit should represent:", ["A day's work", "One logical change", "All AI edits from a session", "One file"], 1),
q("When is unreadable Git history most costly?", ["During onboarding", "During an incident", "At release", "Never"], 1),
q("Which review criterion does AI-generated code most threaten?", ["Correctness", "Maintainability", "Performance", "Formatting"], 1, "The model never has to maintain anything."),
q("Who owns AI-generated code?", ["Nobody", "Whoever submits it, exactly as if they wrote it", "The AI vendor", "The reviewer"], 1)]},
# 16 --------------------------------------------------------------------------
{"id": "avibe16", "n": 16, "title": "Performance & Scalability", "mins": 60, "icon": "TrendingUp",
"summary": "Finding and fixing bottlenecks: where they originate, measuring before optimising, database and API performance, frontend cost, and scaling strategies.",
"keyWords": ["Bottleneck", "Profiling", "Caching", "Pagination", "Scaling"],
"sections": [
sec("chart", "Where Bottlenecks Live", [
"Performance problems originate in frontend rendering, API requests, database queries, network latency, external services, memory or CPU.",
"In practice, database queries are the most common culprit in application code, and payload size the most common on the frontend.",
"An application that works correctly can still perform badly, and correctness testing will never reveal it."]),
sec("law", "Measure Before Optimising", [
"Do not optimise based on assumptions. Measure first.",
"Developer intuition about performance is famously poor, and AI intuition is worse — the model cannot see your data volumes, your traffic pattern or your infrastructure.",
"Optimising the wrong thing costs time and usually adds complexity that must be maintained forever."]),
sec("build", "Database, API and Frontend", [
"Database: indexes, query optimisation, pagination, avoiding unnecessary queries, caching. Watch for the pattern where fetching a list then querying once per item turns one request into hundreds.",
"API: response sizes, unnecessary requests, concurrency, timeouts, caching, rate limiting.",
"Frontend: lazy loading, image optimisation, component rendering, bundle size, caching, network requests. Images are usually the largest single win and the easiest.",
"Then scaling: vertical, horizontal, caching, queues, background jobs, load balancing and database scaling. Caching first — it is usually the cheapest large improvement available."])],
"check": [
q("The first rule of optimisation is:", ["Cache everything", "Measure before optimising", "Add more servers", "Rewrite in a faster language"], 1),
q("Why is AI intuition about performance unreliable?", ["Models are weak", "It can't see your data volumes, traffic or infrastructure", "It's not trained on performance", "It is reliable"], 1),
q("Fetching a list then querying once per item turns:", ["One request into hundreds", "Hundreds into one", "Nothing", "Reads into writes"], 0),
q("Which frontend optimisation is usually the largest easy win?", ["Bundle splitting", "Image optimisation", "Lazy loading", "Caching"], 1)]},
# 17 --------------------------------------------------------------------------
{"id": "avibe17", "n": 17, "title": "Deployment & DevOps With AI", "mins": 60, "icon": "Rocket",
"summary": "Getting software to users and keeping it running: environments, build processes, CI/CD pipelines, cloud fundamentals, monitoring and rollbacks.",
"keyWords": ["Environments", "CI/CD", "Build", "Monitoring", "Rollback", "DNS"],
"sections": [
sec("chart", "Environments and Builds", [
"Development, testing, staging and production serve different purposes. Staging exists to be as close to production as possible so that surprises happen there instead.",
"A build turns source into something deployable: dependencies, compilation, bundling, environment configuration, production builds.",
"Production builds differ meaningfully from development ones — optimised, minified, with debugging removed. Code that works in development can fail in a production build, which is why staging exists."]),
sec("steps", "CI/CD", [
"An automated pipeline: install dependencies, run linting, run tests, build, perform security checks, deploy.",
"The value is that it runs every time regardless of schedule pressure. Manual processes are skipped precisely when skipping them is most dangerous.",
"Put security checks in the pipeline rather than in a person's memory."]),
sec("law", "Monitoring and Rollbacks", [
"Cloud fundamentals: servers, containers, domains, DNS, databases, storage, environment variables, networking.",
"Then monitoring — errors, logs, uptime, response times, resource usage. Without it your users become your alerting system, which is a poor experience and a slow one.",
"And rollbacks. Know how to undo a deployment before you need to. The time to work out your recovery procedure is not while the site is down."])],
"check": [
q("Why does staging exist?", ["For demos", "So surprises happen there instead of production", "For testing designs", "It's traditional"], 1),
q("The main value of a CI/CD pipeline is:", ["Speed", "It runs every time regardless of schedule pressure", "Lower cost", "Fewer tools"], 1),
q("Without monitoring, who alerts you to problems?", ["The cloud provider", "Your users", "Nobody", "The AI"], 1),
q("When should you work out your rollback procedure?", ["During the incident", "Before you need it", "After the first failure", "It's automatic"], 1)]},
# 18 --------------------------------------------------------------------------
{"id": "avibe18", "n": 18, "title": "Advanced UI/UX Vibe Coding", "mins": 60, "icon": "Camera",
"summary": "Production-quality interfaces: design systems, component architecture, genuinely responsive design, accessibility, purposeful animation, and turning designs into code.",
"keyWords": ["Design system", "Component architecture", "Responsive", "Accessibility", "Animation"],
"sections": [
sec("build", "Design Systems and Components", [
"A design system defines reusable colours, typography, spacing, buttons, forms, cards, navigation and feedback states. It is what stops an application looking like six different products.",
"Distinguish reusable components, page-level components, application layouts and design primitives. Confusing these produces components that are almost reusable, which is worse than either extreme.",
"AI is strong at generating a design system if you ask for one first, and poor at inferring one from scattered requests afterwards."]),
sec("law", "Responsive and Accessible", [
"Build for mobile, tablet and desktop — designing behaviour rather than shrinking desktop layouts. A layout that merely compresses is not responsive; it is small.",
"Accessibility covers keyboard navigation, semantic HTML, labels, focus states, colour contrast, screen-reader considerations and accessible forms.",
"AI-generated interfaces are frequently inaccessible by default: div elements acting as buttons, missing labels, poor contrast. Ask for accessibility explicitly and verify with keyboard navigation, which takes a minute and catches a surprising amount."]),
sec("mark", "Animation and Design Translation", [
"Use transitions, micro-interactions, loading animations and page transitions where they support usability — showing what changed, what is loading, what responded.",
"Animation that exists to impress usually irritates on the tenth use. Respect reduced-motion preferences.",
"AI can translate screenshots, design specifications, component descriptions and visual references into code. Compare the output against the requirement rather than against your general impression, and refine iteratively."])],
"check": [
q("A layout that merely compresses on mobile is:", ["Responsive", "Just small", "Accessible", "Optimised"], 1),
q("How should you get a design system from AI?", ["Infer it from scattered requests", "Ask for one first", "Generate it last", "Extract it from code"], 1),
q("A fast, effective accessibility check is:", ["Colour analysis", "Navigating with the keyboard", "Reading the code", "Testing on mobile"], 1),
q("Animation should be judged by:", ["How impressive it looks", "Whether it supports usability on the tenth use", "How modern it feels", "File size"], 1)]},
# 19 --------------------------------------------------------------------------
{"id": "avibe19", "n": 19, "title": "Building With Multiple AI Models & Tools", "mins": 50, "icon": "Activity",
"summary": "No single model suits every task: comparing strengths, matching model to job, multi-tool workflows, handing off between models, and evaluating output objectively.",
"keyWords": ["Model selection", "Multi-tool workflow", "Handoff", "Evaluation", "Cost"],
"sections": [
sec("chart", "Understanding Model Strengths", [
"Compare on reasoning ability, coding ability, speed, context handling, instruction following, cost and multimodal capability.",
"These trade off against each other. The most capable model is usually slower and more expensive, and for many tasks that capability is wasted.",
"Simple formatting suits a lightweight model. Code explanation suits a coding-focused one. Complex architecture warrants stronger reasoning. Visual analysis needs multimodal."]),
sec("build", "Multi-Tool Workflows and Handoffs", [
"Combine coding assistants, terminal agents, documentation tools, browser tools, testing tools, Git tools and design tools. Each is good at a narrow thing.",
"Moving work between models loses context unless you manage it. Write a concise handoff document: current objective, completed work, outstanding problems, relevant files, decisions, constraints and next steps.",
"This is the same discipline as the project documentation from unit 5, applied at session scale — and it is what makes switching models cheap rather than disruptive."]),
sec("mark", "Evaluating Output", [
"Compare outputs on correctness, maintainability, security, performance, clarity and test coverage.",
"Notice that impressiveness is not on the list. Generated code that reads elegantly can still be wrong, insecure or untestable.",
"Build the habit of judging against criteria rather than impression. It is the difference between choosing a model and being chosen by one."])],
"check": [
q("Should you always use the most capable model?", ["Yes", "No — capability is often wasted, and it costs speed and money", "Only for coding", "Only for cheap tasks"], 1),
q("What makes switching between models cheap?", ["Using the same vendor", "A concise handoff document capturing objective, work done and constraints", "Paying more", "Shorter sessions"], 1),
q("Which is NOT a criterion for evaluating AI output?", ["Correctness", "Security", "How impressive it reads", "Test coverage"], 2),
q("Visual analysis tasks need:", ["The fastest model", "A multimodal model", "The cheapest model", "Any model"], 1)]},
# 20 --------------------------------------------------------------------------
{"id": "avibe20", "n": 20, "title": "The Professional Vibe Coding Workflow & Capstone", "mins": 90, "icon": "Award",
"summary": "The eleven-stage professional workflow from idea to monitoring and iteration, followed by the capstone: a complete application taken through the entire lifecycle.",
"keyWords": ["Workflow", "Lifecycle", "Capstone", "Review", "Iteration"],
"sections": [
sec("steps", "The Eleven Stages", [
"Idea, requirements, specification, architecture, implementation planning, AI-assisted implementation, testing, review, deployment, monitoring, iteration.",
"Only stage six generates code. That proportion is the whole argument of the course made visible.",
"Implementation itself becomes: plan, delegate, inspect, execute, test, review — rather than prompt, generate five thousand lines, hope it works."]),
sec("mark", "Review and What Comes After", [
"Every important AI-generated change gets human review. Is the implementation correct? Does it match the specification? Is it secure, maintainable, unnecessarily complicated? Does it introduce technical debt? Are the tests sufficient?",
"Then deployment: environment variables, builds, database migrations, security, logging, monitoring, backups, deployment process, rollback strategy.",
"Then monitoring and iteration, because real software is never finished. Requirements appear, users report bugs, performance drifts, security threats evolve, priorities change. The same workflow carries you through all of it."]),
sec("target", "The Capstone", [
"Take one application through the entire lifecycle. Required: product definition, requirements, architecture, project context documentation, implementation, database with real relationships and migrations, authentication and security, at least one external integration, at least one AI-powered capability, a full test suite, a performance consideration you identified and addressed, a proper Git workflow, deployment, and documentation.",
"That list is deliberately demanding. It is close to what shipping a real product actually requires, and completing it is meaningful evidence of capability.",
"Document known limitations honestly. Every real system has them, and naming yours demonstrates judgement rather than weakness."]),
sec("talk", "The Philosophy", [
"The central claim, stated plainly: AI dramatically increases the speed at which software is produced. It does not automatically increase the quality of that software.",
"Quality comes from clear thinking, good specifications, appropriate architecture, effective instructions, careful implementation, rigorous testing, security and human judgement. AI accelerates several of those and replaces none.",
"So the advanced practitioner does not only ask whether AI can build this. They ask what should be built, why this way, what assumptions are being made, how the system should be structured, how to know the code is correct, how to test and secure it, how it behaves under real conditions, how another developer will maintain it, and how it will be monitored and improved after release.",
"That shift — from code generation to engineering orchestration — is the whole of advanced vibe coding. The objective is not to make developers unnecessary. It is to make them dramatically more capable while they retain responsibility for the decisions that determine whether the software is any good."])],
"check": [
q("How many of the eleven workflow stages generate code?", ["All of them", "One", "Five", "Eight"], 1, "Only stage six — which is the argument of the course made visible."),
q("The implementation loop should be:", ["Prompt, generate, hope", "Plan, delegate, inspect, execute, test, review", "Generate then test", "Delegate everything"], 1),
q("The central claim of the course is:", ["AI increases quality automatically", "AI increases speed of production, not automatically quality", "AI replaces engineers", "AI is unreliable"], 1),
q("Documenting known limitations demonstrates:", ["Weakness", "Judgement", "Inexperience", "Poor planning"], 1)]},
]

COURSE = {
    "code": "VIBE-Y2",
    "subject": "Advanced Vibe Coding",
    "group": "Digital & Technology",
    "cat": "General Courses",
    "year": "All years",
    "term": 2,
    "termLabel": "Advanced · self-paced",
    "title": "Advanced Vibe Coding: Engineering With AI",
    "tagline": "Move beyond generating code. Specify, architect, delegate, review, test, secure, deploy and monitor real software with AI as an engineering partner — while keeping human judgement where it belongs.",
    "months": "16–20 weeks (self-paced)",
    "passMark": None,
    "totalQuestions": 0,
    "examMins": 0,
    "materials": [],
    "units": UNITS,
}


def main():
    with open(SRC, encoding="utf-8", errors="surrogateescape") as fh:
        d = fh.read()
    if '"VIBE-Y2"' in d:
        sys.exit("FAIL: course already present")
    anchor = "var gg={"
    if d.count(anchor) != 1:
        sys.exit(f"FAIL: gg catalogue anchor found {d.count(anchor)}x")
    payload = json.dumps({"VIBE-Y2": COURSE}, ensure_ascii=False, separators=(",", ":"))
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
