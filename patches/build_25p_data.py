#!/usr/bin/env python3
"""
25Personalities — replaces the 28-question iPersonality quiz with the
120-question, 20-dimension, 25-type instrument.

WHY THIS RAISES ACCURACY
Three changes do the real work:

  1. Every dimension is measured by MANY questions rather than one, so a
     single misread or unusual answer cannot swing the result.
  2. A consistency check re-asks the same concept in different wording.
     Contradictory answers lower the reported confidence instead of being
     silently averaged into false certainty.
  3. The result is three ranked patterns (primary, secondary, supporting)
     plus 20 numeric dimensions — not one box. Two people sharing a
     primary type can still look very different, which is true of people.

The source design's guardrails are preserved deliberately: results are
tendencies not facts, weaknesses are framed as "potential vulnerabilities",
confidence is always reported, and nothing here diagnoses anything.

Question types:
  ORD  ordinal A-F scale -> graded loading on one or two dimensions
  CAT  categorical choice -> explicit dimension map per option
"""
import json
import sys

SRC = "assets/app.js"

# ---------------------------------------------------------------------------
# 20 dimensions (index order is used throughout).
# ---------------------------------------------------------------------------
DIMS = [
    ("Social Energy", "Solitary and reflective", "Social and expressive"),
    ("Structure", "Flexible and spontaneous", "Organised and systematic"),
    ("Openness", "Practical and concrete", "Curious and experimental"),
    ("Emotional Intensity", "Steady and reserved", "Passionate and reactive"),
    ("Emotional Security", "Self-contained", "Connection-oriented"),
    ("Autonomy", "Comfortable interdependent", "Independent and freedom-seeking"),
    ("Achievement Drive", "Lifestyle-oriented", "Ambitious and goal-driven"),
    ("Risk Tolerance", "Security-oriented", "Comfortable with uncertainty"),
    ("Analytical Orientation", "Intuitive and experiential", "Logical and evidence-led"),
    ("Creativity", "Procedural and optimising", "Imaginative and generative"),
    ("Social Influence", "Independent contributor", "Persuasive and leading"),
    ("Empathy", "Task-focused and direct", "People-sensitive"),
    ("Stability Preference", "Change-seeking", "Security-seeking"),
    ("Meaning Orientation", "Outcome-focused", "Purpose-driven"),
    ("Status Orientation", "Internally motivated", "Recognition-sensitive"),
    ("Relationship Orientation", "Highly independent", "Partnership-oriented"),
    ("Adaptability", "Prefers predictability", "Flexible and resilient"),
    ("Persistence", "Redirects easily", "Long-term committed"),
    ("Self-Awareness", "Action-oriented", "Reflective and pattern-aware"),
    ("Independence of Thought", "Consensus-oriented", "Nonconformist"),
]
D = {name: i for i, (name, _, _) in enumerate(DIMS)}

LIKERT = ["Strongly disagree", "Disagree", "Slightly disagree",
          "Slightly agree", "Agree", "Strongly agree"]


def ORD(text, opts, load, varies=None):
    """Ordinal question. `load` is {dim: weight}; option 0 scores -weight,
    option 4 scores +weight, graded between. Option F ('varies') is treated
    separately because 'it depends' is information about adaptability and
    self-awareness, not a midpoint."""
    steps = [-1.0, -0.6, -0.2, 0.4, 1.0]
    out = []
    for i, o in enumerate(opts[:5]):
        dd = {D[k]: round(v * steps[i], 2) for k, v in load.items()}
        out.append([o, dd])
    v = varies or {"Adaptability": 0.8, "Self-Awareness": 0.4, "Stability Preference": -0.4}
    out.append([opts[5], {D[k]: val for k, val in v.items()}])
    return {"q": text, "o": out}


def CAT(text, pairs):
    """Categorical question: each option carries its own dimension map."""
    return {"q": text, "o": [[t, {D[k]: v for k, v in m.items()}] for t, m in pairs]}


Q = []
A = Q.append

# --- SECTION 1: biology & temperament (1-10) --------------------------------
A(ORD("How would you describe your natural energy level?",
      ["Very low", "Usually low", "Moderate", "Usually high", "Very high", "Highly variable"],
      {"Social Energy": 0.6, "Adaptability": 0.2}))
A(CAT("When do you normally function best?", [
    ("Very early morning", {"Structure": 0.8, "Stability Preference": 0.5}),
    ("Morning", {"Structure": 0.5, "Stability Preference": 0.3}),
    ("Afternoon", {"Structure": 0.1}),
    ("Evening", {"Openness": 0.3, "Structure": -0.3}),
    ("Late night", {"Creativity": 0.6, "Structure": -0.6, "Independence of Thought": 0.3}),
    ("It varies considerably", {"Adaptability": 0.8, "Stability Preference": -0.5})]))
A(ORD("How strongly does lack of sleep affect your functioning?",
      ["Hardly at all", "Slightly", "Moderately", "Significantly", "Extremely", "It depends"],
      {"Emotional Intensity": 0.5, "Adaptability": -0.3}))
A(ORD("How sensitive are you to noise and environmental stimulation?",
      ["Very insensitive", "Slightly insensitive", "Average", "Moderately sensitive",
       "Very sensitive", "Extremely sensitive"],
      {"Emotional Intensity": 0.7, "Social Energy": -0.4},
      {"Emotional Intensity": 1.0, "Social Energy": -0.6}))
A(ORD("How quickly do you become overwhelmed by prolonged activity?",
      ["Very slowly", "Slowly", "Moderately", "Quickly", "Very quickly", "Depends on the activity"],
      {"Persistence": -0.6, "Emotional Intensity": 0.4}))
A(ORD("How comfortable are you with physical discomfort?",
      ["Extremely uncomfortable", "Very uncomfortable", "Somewhat uncomfortable",
       "Fairly comfortable", "Very comfortable", "My response varies"],
      {"Risk Tolerance": 0.6, "Persistence": 0.4}))
A(ORD("How predictable is your energy from day to day?",
      ["Extremely predictable", "Very predictable", "Somewhat predictable",
       "Somewhat unpredictable", "Very unpredictable", "Depends on circumstances"],
      {"Stability Preference": -0.7, "Structure": -0.4}))
A(ORD("How strongly does your physical environment influence your mood?",
      ["Not at all", "Very little", "Somewhat", "Significantly", "Very strongly", "Almost completely"],
      {"Emotional Intensity": 0.6, "Self-Awareness": 0.3},
      {"Emotional Intensity": 1.0, "Self-Awareness": 0.4}))
A(ORD("How quickly do you recover after an exhausting day?",
      ["Very slowly", "Slowly", "Moderately", "Quickly", "Very quickly", "Depends on the exhaustion"],
      {"Adaptability": 0.6, "Emotional Intensity": -0.4}))
A(CAT("Which description best fits your natural temperament?", [
    ("Calm and slow-paced", {"Emotional Intensity": -0.9, "Stability Preference": 0.6}),
    ("Calm but alert", {"Emotional Intensity": -0.5, "Analytical Orientation": 0.4}),
    ("Balanced", {"Adaptability": 0.4}),
    ("Energetic and expressive", {"Social Energy": 0.8, "Emotional Intensity": 0.5}),
    ("Intense and highly reactive", {"Emotional Intensity": 1.0, "Social Energy": 0.3}),
    ("Highly variable", {"Adaptability": 0.7, "Stability Preference": -0.5})]))

# --- SECTION 2: perception & cognition (11-20) ------------------------------
A(CAT("Faced with a complicated problem, what do you do first?", [
    ("Look for the facts", {"Analytical Orientation": 0.9}),
    ("Break it into smaller pieces", {"Analytical Orientation": 0.7, "Structure": 0.6}),
    ("Ask other people what they think", {"Social Energy": 0.6, "Relationship Orientation": 0.5, "Autonomy": -0.4}),
    ("Look for patterns", {"Creativity": 0.6, "Analytical Orientation": 0.4}),
    ("Trust my intuition", {"Analytical Orientation": -0.8, "Creativity": 0.4}),
    ("Act immediately and adjust later", {"Risk Tolerance": 0.8, "Structure": -0.6, "Adaptability": 0.5})]))
A(ORD("How important is evidence before you accept a claim?",
      ["Extremely important", "Very important", "Moderately important", "Somewhat important",
       "I often trust experience or intuition", "It depends on the subject"],
      {"Analytical Orientation": -0.9}))
A(CAT("When someone disagrees with you, your first reaction is:", [
    ("Examine their evidence", {"Analytical Orientation": 0.8, "Self-Awareness": 0.4}),
    ("Defend my position", {"Independence of Thought": 0.6, "Emotional Intensity": 0.4, "Empathy": -0.3}),
    ("Become curious", {"Openness": 0.9, "Self-Awareness": 0.5}),
    ("Feel personally challenged", {"Emotional Intensity": 0.8, "Emotional Security": 0.5}),
    ("Try to find common ground", {"Empathy": 0.8, "Relationship Orientation": 0.5}),
    ("Disengage", {"Autonomy": 0.6, "Social Energy": -0.5})]))
A(ORD("How easily do you change your mind?",
      ["Almost never", "Rarely", "Sometimes", "Fairly easily", "Very easily",
       "Only when strong evidence appears"],
      {"Adaptability": 0.6, "Independence of Thought": -0.3},
      {"Analytical Orientation": 0.8, "Independence of Thought": 0.5}))
A(CAT("Which is most like your thinking?", [
    ("Logical", {"Analytical Orientation": 0.9}),
    ("Analytical", {"Analytical Orientation": 0.8, "Structure": 0.3}),
    ("Creative", {"Creativity": 1.0, "Openness": 0.6}),
    ("Intuitive", {"Analytical Orientation": -0.7, "Creativity": 0.5}),
    ("Practical", {"Openness": -0.5, "Structure": 0.4}),
    ("Strategic", {"Analytical Orientation": 0.6, "Achievement Drive": 0.5, "Persistence": 0.4})]))
A(ORD("How often do you overthink decisions?",
      ["Almost never", "Rarely", "Sometimes", "Often", "Very often", "Almost constantly"],
      {"Self-Awareness": 0.5, "Risk Tolerance": -0.6},
      {"Self-Awareness": 0.9, "Risk Tolerance": -1.0}))
A(CAT("Making an important decision, you prioritise:", [
    ("Data", {"Analytical Orientation": 0.9}),
    ("Logic", {"Analytical Orientation": 0.8}),
    ("Experience", {"Analytical Orientation": -0.3, "Persistence": 0.3}),
    ("Feelings", {"Emotional Intensity": 0.7, "Analytical Orientation": -0.7}),
    ("Other people's opinions", {"Independence of Thought": -0.8, "Relationship Orientation": 0.5}),
    ("Long-term consequences", {"Persistence": 0.7, "Meaning Orientation": 0.4})]))
A(ORD("How easily can you identify your own cognitive biases?",
      ["Very easily", "Fairly easily", "Sometimes", "With difficulty", "Rarely", "I am unsure"],
      {"Self-Awareness": -0.8}, {"Self-Awareness": -0.3}))
A(CAT("When learning something new, you prefer:", [
    ("Detailed explanations", {"Analytical Orientation": 0.6, "Structure": 0.5}),
    ("Examples", {"Structure": 0.3}),
    ("Hands-on practice", {"Openness": 0.4, "Structure": -0.3}),
    ("Visual information", {"Creativity": 0.5}),
    ("Discussion", {"Social Energy": 0.7, "Relationship Orientation": 0.4}),
    ("Experimentation", {"Openness": 0.8, "Risk Tolerance": 0.5, "Creativity": 0.5})]))
A(CAT("Faced with uncertainty, you usually:", [
    ("Gather more information", {"Analytical Orientation": 0.7, "Risk Tolerance": -0.3}),
    ("Create a plan", {"Structure": 0.9, "Stability Preference": 0.4}),
    ("Trust intuition", {"Analytical Orientation": -0.7, "Risk Tolerance": 0.4}),
    ("Ask someone experienced", {"Autonomy": -0.6, "Relationship Orientation": 0.4}),
    ("Take action", {"Risk Tolerance": 0.9, "Adaptability": 0.5}),
    ("Wait until it becomes clearer", {"Risk Tolerance": -0.8, "Stability Preference": 0.6})]))

# --- SECTION 3: emotion (21-30) --------------------------------------------
A(ORD("How easily can you identify what you are feeling?",
      ["Very easily", "Easily", "Usually", "Sometimes", "With difficulty", "Very rarely"],
      {"Self-Awareness": -0.9, "Empathy": -0.4}, {"Self-Awareness": -1.0, "Empathy": -0.5}))
A(ORD("How strongly do you experience emotions?",
      ["Very mildly", "Mildly", "Moderately", "Strongly", "Very strongly", "It varies dramatically"],
      {"Emotional Intensity": 1.0}))
A(CAT("When angry, you are most likely to:", [
    ("Become quiet", {"Emotional Intensity": -0.4, "Social Energy": -0.4}),
    ("Discuss the issue calmly", {"Self-Awareness": 0.7, "Empathy": 0.5}),
    ("Express it immediately", {"Emotional Intensity": 0.8, "Social Energy": 0.4}),
    ("Withdraw", {"Autonomy": 0.6, "Relationship Orientation": -0.4}),
    ("Become confrontational", {"Emotional Intensity": 0.9, "Empathy": -0.5}),
    ("Pretend I am not angry", {"Self-Awareness": -0.5, "Emotional Security": 0.4})]))
A(CAT("When hurt by someone, you tend to:", [
    ("Forgive quickly", {"Empathy": 0.7, "Adaptability": 0.5}),
    ("Discuss it", {"Relationship Orientation": 0.6, "Self-Awareness": 0.4}),
    ("Distance myself", {"Autonomy": 0.7, "Relationship Orientation": -0.5}),
    ("Hold onto it", {"Emotional Intensity": 0.7, "Adaptability": -0.5}),
    ("Seek reassurance", {"Emotional Security": 0.9, "Relationship Orientation": 0.5}),
    ("Become emotionally independent", {"Autonomy": 0.9, "Emotional Security": -0.6})]))
A(CAT("What worries you most?", [
    ("Failure", {"Achievement Drive": 0.7, "Status Orientation": 0.4}),
    ("Rejection", {"Emotional Security": 0.9, "Relationship Orientation": 0.5}),
    ("Losing control", {"Structure": 0.7, "Autonomy": 0.5}),
    ("Financial insecurity", {"Stability Preference": 0.9, "Risk Tolerance": -0.6}),
    ("Disappointing people", {"Empathy": 0.7, "Emotional Security": 0.6}),
    ("Wasting my potential", {"Meaning Orientation": 0.8, "Achievement Drive": 0.5})]))
A(CAT("What tends to motivate you emotionally?", [
    ("Love", {"Relationship Orientation": 0.9, "Empathy": 0.5}),
    ("Recognition", {"Status Orientation": 0.9, "Social Influence": 0.4}),
    ("Security", {"Stability Preference": 0.9, "Risk Tolerance": -0.5}),
    ("Achievement", {"Achievement Drive": 0.9}),
    ("Freedom", {"Autonomy": 1.0}),
    ("Meaning", {"Meaning Orientation": 1.0})]))
A(ORD("How comfortable are you showing vulnerability?",
      ["Extremely comfortable", "Comfortable", "Somewhat comfortable", "Uncomfortable",
       "Very uncomfortable", "Only with a few people"],
      {"Autonomy": 0.6, "Relationship Orientation": -0.5},
      {"Relationship Orientation": 0.3, "Autonomy": 0.3}))
A(CAT("After a major disappointment, you usually:", [
    ("Analyse what happened", {"Analytical Orientation": 0.8, "Self-Awareness": 0.5}),
    ("Talk to someone", {"Relationship Orientation": 0.8, "Social Energy": 0.4}),
    ("Distract myself", {"Self-Awareness": -0.5, "Adaptability": 0.3}),
    ("Work harder", {"Achievement Drive": 0.8, "Persistence": 0.6}),
    ("Withdraw", {"Autonomy": 0.6, "Social Energy": -0.6}),
    ("Become determined to prove myself", {"Achievement Drive": 0.8, "Status Orientation": 0.5})]))
A(ORD("How much does other people's approval affect your decisions?",
      ["Almost not at all", "Very little", "Somewhat", "Significantly", "Very strongly",
       "Depends whose approval"],
      {"Independence of Thought": -0.9, "Emotional Security": 0.5},
      {"Independence of Thought": -0.2, "Self-Awareness": 0.4}))
A(CAT("Which emotional need is strongest for you?", [
    ("To feel loved", {"Relationship Orientation": 0.9, "Emotional Security": 0.6}),
    ("To feel respected", {"Status Orientation": 0.7, "Social Influence": 0.4}),
    ("To feel safe", {"Stability Preference": 0.9, "Emotional Security": 0.6}),
    ("To feel understood", {"Empathy": 0.7, "Emotional Intensity": 0.5}),
    ("To feel free", {"Autonomy": 1.0}),
    ("To feel significant", {"Achievement Drive": 0.7, "Meaning Orientation": 0.5})]))

# --- SECTION 4: personality & behaviour (31-40) ----------------------------
A(CAT("At a social gathering, you normally:", [
    ("Talk to almost everyone", {"Social Energy": 1.0, "Social Influence": 0.5}),
    ("Talk mostly to people I know", {"Social Energy": 0.3}),
    ("Find one or two interesting people", {"Social Energy": -0.2, "Relationship Orientation": 0.4}),
    ("Observe before participating", {"Social Energy": -0.5, "Self-Awareness": 0.4}),
    ("Stay mostly quiet", {"Social Energy": -0.9}),
    ("Leave early", {"Social Energy": -1.0, "Autonomy": 0.5})]))
A(ORD("How organised are you?",
      ["Extremely organised", "Very organised", "Moderately organised", "Somewhat disorganised",
       "Very spontaneous", "Highly situational"],
      {"Structure": -1.0}))
A(ORD("How comfortable are you with routine?",
      ["I strongly prefer routine", "I prefer routine", "I like some routine",
       "I prefer flexibility", "I strongly dislike routine", "I need alternating routine and novelty"],
      {"Stability Preference": -0.9, "Openness": 0.5},
      {"Adaptability": 0.7, "Openness": 0.4}))
A(ORD("How often do you finish what you start?",
      ["Almost always", "Usually", "More often than not", "Sometimes", "Rarely",
       "Depends whether I stay interested"],
      {"Persistence": -1.0}, {"Persistence": -0.3, "Openness": 0.5}))
A(ORD("Which best describes you?",
      ["Introverted", "Mostly introverted", "Ambiverted", "Mostly extroverted", "Extroverted",
       "Highly context-dependent"],
      {"Social Energy": 1.0}))
A(ORD("How adventurous are you?",
      ["Extremely cautious", "Cautious", "Moderately adventurous", "Adventurous",
       "Highly adventurous", "Adventurous when the reward is worthwhile"],
      {"Risk Tolerance": 1.0, "Openness": 0.5},
      {"Risk Tolerance": 0.4, "Analytical Orientation": 0.5}))
A(ORD("How competitive are you?",
      ["Not competitive", "Slightly competitive", "Moderately competitive", "Quite competitive",
       "Extremely competitive", "Only in areas important to me"],
      {"Achievement Drive": 0.9, "Status Orientation": 0.5},
      {"Achievement Drive": 0.4, "Meaning Orientation": 0.4}))
A(ORD("How tolerant are you of disorder?",
      ["Extremely intolerant", "Intolerant", "Moderate", "Tolerant", "Very tolerant",
       "I perform better in some disorder"],
      {"Structure": -0.9, "Adaptability": 0.4},
      {"Structure": -0.8, "Creativity": 0.5}))
A(ORD("How spontaneous are you?",
      ["Not spontaneous", "Slightly spontaneous", "Moderately spontaneous", "Quite spontaneous",
       "Extremely spontaneous", "Spontaneous when I feel safe"],
      {"Structure": -0.8, "Risk Tolerance": 0.5},
      {"Emotional Security": 0.5, "Structure": -0.3}))
A(CAT("Which best describes your behaviour?", [
    ("I plan and execute", {"Structure": 0.8, "Persistence": 0.6}),
    ("I plan extensively", {"Structure": 1.0, "Risk Tolerance": -0.4}),
    ("I improvise effectively", {"Adaptability": 0.9, "Structure": -0.5}),
    ("I explore possibilities", {"Openness": 0.9, "Creativity": 0.5}),
    ("I act according to emotion", {"Emotional Intensity": 0.8, "Structure": -0.5}),
    ("I respond to what circumstances demand", {"Adaptability": 0.9, "Autonomy": -0.2})]))

# --- SECTION 5: motivation (41-50) -----------------------------------------
A(CAT("Which would you value most in a career?", [
    ("High income", {"Status Orientation": 0.6, "Achievement Drive": 0.5, "Meaning Orientation": -0.3}),
    ("Security", {"Stability Preference": 1.0, "Risk Tolerance": -0.6}),
    ("Freedom", {"Autonomy": 1.0}),
    ("Meaning", {"Meaning Orientation": 1.0}),
    ("Recognition", {"Status Orientation": 1.0}),
    ("Intellectual stimulation", {"Openness": 0.8, "Analytical Orientation": 0.5})]))
A(CAT("Which reward motivates you most?", [
    ("Money", {"Status Orientation": 0.5, "Stability Preference": 0.4}),
    ("Praise", {"Status Orientation": 0.8, "Emotional Security": 0.4}),
    ("Achievement", {"Achievement Drive": 1.0}),
    ("Influence", {"Social Influence": 1.0}),
    ("Freedom", {"Autonomy": 1.0}),
    ("Mastery", {"Persistence": 0.8, "Meaning Orientation": 0.4})]))
A(CAT("What are you most afraid of becoming?", [
    ("Poor", {"Stability Preference": 0.8, "Risk Tolerance": -0.5}),
    ("Irrelevant", {"Status Orientation": 0.8, "Social Influence": 0.4}),
    ("Dependent", {"Autonomy": 1.0}),
    ("Unsuccessful", {"Achievement Drive": 0.9}),
    ("Trapped", {"Autonomy": 0.8, "Openness": 0.5}),
    ("Someone who wasted their potential", {"Meaning Orientation": 0.9, "Self-Awareness": 0.4})]))
A(CAT("Given a difficult goal, you usually:", [
    ("Create a detailed plan", {"Structure": 0.9}),
    ("Start immediately", {"Risk Tolerance": 0.7, "Structure": -0.4}),
    ("Research first", {"Analytical Orientation": 0.8}),
    ("Find someone to collaborate with", {"Relationship Orientation": 0.7, "Social Energy": 0.5}),
    ("Wait until motivation appears", {"Persistence": -0.8, "Structure": -0.5}),
    ("Break it into experiments", {"Openness": 0.7, "Analytical Orientation": 0.5, "Adaptability": 0.4})]))
A(CAT("What gives the strongest feeling of accomplishment?", [
    ("Winning", {"Achievement Drive": 0.9, "Status Orientation": 0.5}),
    ("Helping someone", {"Empathy": 0.9, "Meaning Orientation": 0.5}),
    ("Creating something", {"Creativity": 1.0}),
    ("Solving something difficult", {"Analytical Orientation": 0.8, "Persistence": 0.5}),
    ("Becoming financially independent", {"Autonomy": 0.7, "Stability Preference": 0.5}),
    ("Becoming better than I was", {"Self-Awareness": 0.7, "Persistence": 0.6})]))
A(ORD("How important is status to you?",
      ["Not important", "Slightly important", "Moderately important", "Important",
       "Very important", "Important only in certain environments"],
      {"Status Orientation": 1.0}, {"Status Orientation": 0.3, "Adaptability": 0.4}))
A(CAT("What would you choose if money were guaranteed?", [
    ("Build a business", {"Achievement Drive": 0.8, "Risk Tolerance": 0.6}),
    ("Create art or media", {"Creativity": 1.0, "Openness": 0.5}),
    ("Help people", {"Empathy": 0.9, "Meaning Orientation": 0.6}),
    ("Research and learn", {"Analytical Orientation": 0.8, "Openness": 0.6}),
    ("Travel and explore", {"Openness": 0.9, "Stability Preference": -0.6}),
    ("Build something meaningful", {"Meaning Orientation": 1.0})]))
A(CAT("Which motivates you more?", [
    ("Rewards", {"Status Orientation": 0.5, "Achievement Drive": 0.4}),
    ("Avoiding failure", {"Risk Tolerance": -0.8, "Stability Preference": 0.5}),
    ("Personal growth", {"Self-Awareness": 0.8, "Openness": 0.5}),
    ("Competition", {"Achievement Drive": 0.9, "Status Orientation": 0.4}),
    ("Responsibility", {"Persistence": 0.7, "Empathy": 0.4}),
    ("Curiosity", {"Openness": 1.0, "Creativity": 0.4})]))
A(ORD("How persistent are you when success is slow?",
      ["Extremely persistent", "Very persistent", "Moderately persistent",
       "I need visible progress", "I lose motivation quickly", "I change strategies rather than quit"],
      {"Persistence": -1.0}, {"Persistence": 0.6, "Adaptability": 0.8}))
A(CAT("What matters most at the end of your life?", [
    ("Wealth", {"Status Orientation": 0.6, "Meaning Orientation": -0.4}),
    ("Family", {"Relationship Orientation": 1.0}),
    ("Achievement", {"Achievement Drive": 0.9}),
    ("Impact", {"Meaning Orientation": 0.9, "Social Influence": 0.5}),
    ("Freedom", {"Autonomy": 1.0}),
    ("Wisdom and understanding", {"Self-Awareness": 0.8, "Openness": 0.5})]))

# --- SECTION 6: values & morality (51-60) ----------------------------------
A(CAT("Which is most important?", [
    ("Freedom", {"Autonomy": 1.0, "Independence of Thought": 0.5}),
    ("Equality", {"Empathy": 0.7, "Meaning Orientation": 0.5}),
    ("Loyalty", {"Relationship Orientation": 0.8, "Stability Preference": 0.4}),
    ("Justice", {"Independence of Thought": 0.6, "Meaning Orientation": 0.5}),
    ("Compassion", {"Empathy": 1.0}),
    ("Responsibility", {"Persistence": 0.7, "Structure": 0.5})]))
A(CAT("If telling the truth seriously hurts someone, you would:", [
    ("Tell the truth regardless", {"Independence of Thought": 0.8, "Empathy": -0.5}),
    ("Tell a softened version", {"Empathy": 0.6}),
    ("Consider the consequences first", {"Analytical Orientation": 0.6, "Self-Awareness": 0.4}),
    ("Avoid answering", {"Social Energy": -0.4, "Empathy": 0.3}),
    ("Protect the person", {"Empathy": 0.9, "Relationship Orientation": 0.5}),
    ("Ask what they need to know", {"Empathy": 0.7, "Self-Awareness": 0.6})]))
A(CAT("Which would you sacrifice first?", [
    ("Money", {"Meaning Orientation": 0.6, "Status Orientation": -0.5}),
    ("Status", {"Status Orientation": -0.9}),
    ("Comfort", {"Persistence": 0.7, "Risk Tolerance": 0.4}),
    ("Freedom", {"Autonomy": -0.8, "Relationship Orientation": 0.4}),
    ("Time", {"Achievement Drive": 0.6}),
    ("Personal recognition", {"Status Orientation": -0.8, "Meaning Orientation": 0.5})]))
A(CAT("Which behaviour bothers you most?", [
    ("Dishonesty", {"Independence of Thought": 0.5, "Meaning Orientation": 0.4}),
    ("Disloyalty", {"Relationship Orientation": 0.8}),
    ("Laziness", {"Achievement Drive": 0.7, "Persistence": 0.5}),
    ("Cruelty", {"Empathy": 1.0}),
    ("Arrogance", {"Empathy": 0.5, "Status Orientation": -0.5}),
    ("Incompetence", {"Analytical Orientation": 0.6, "Achievement Drive": 0.5})]))
A(ORD("Do you believe rules should be followed?",
      ["Almost always", "Usually", "Unless there is good reason not to", "Rules are guidelines",
       "Rules often restrict progress", "Depends who created the rule"],
      {"Independence of Thought": 1.0, "Structure": -0.5},
      {"Independence of Thought": 0.7, "Analytical Orientation": 0.4}))
A(CAT("When your values conflict with group expectations, you:", [
    ("Follow my values", {"Independence of Thought": 1.0, "Autonomy": 0.6}),
    ("Follow the group", {"Independence of Thought": -0.9, "Relationship Orientation": 0.4}),
    ("Negotiate", {"Social Influence": 0.6, "Empathy": 0.5}),
    ("Keep my disagreement private", {"Social Energy": -0.5, "Independence of Thought": 0.3}),
    ("Leave the group", {"Autonomy": 0.9, "Relationship Orientation": -0.5}),
    ("Try to change the group", {"Social Influence": 0.9, "Independence of Thought": 0.6})]))
A(ORD("How important is loyalty?",
      ["Extremely important", "Very important", "Moderately important", "Somewhat important",
       "Not very important", "Loyalty must be earned"],
      {"Relationship Orientation": -0.9, "Stability Preference": -0.4},
      {"Analytical Orientation": 0.5, "Autonomy": 0.5}))
A(CAT("What should society prioritise?", [
    ("Freedom", {"Autonomy": 0.8, "Independence of Thought": 0.5}),
    ("Stability", {"Stability Preference": 0.9}),
    ("Opportunity", {"Achievement Drive": 0.6, "Openness": 0.4}),
    ("Equality", {"Empathy": 0.8}),
    ("Innovation", {"Openness": 0.9, "Creativity": 0.6}),
    ("Community", {"Relationship Orientation": 0.8, "Meaning Orientation": 0.5})]))
A(CAT("Which is more important?", [
    ("Intentions", {"Empathy": 0.7, "Analytical Orientation": -0.4}),
    ("Results", {"Achievement Drive": 0.8, "Analytical Orientation": 0.4}),
    ("Both equally", {"Adaptability": 0.4}),
    ("The principle involved", {"Independence of Thought": 0.8, "Meaning Orientation": 0.5}),
    ("The circumstances", {"Adaptability": 0.8}),
    ("Long-term consequences", {"Persistence": 0.7, "Analytical Orientation": 0.5})]))
A(ORD("How strongly do you hold your principles?",
      ["Extremely strongly", "Strongly", "Moderately", "Flexibly", "Very flexibly",
       "My principles evolve with experience"],
      {"Independence of Thought": -0.9, "Adaptability": 0.6},
      {"Self-Awareness": 0.8, "Openness": 0.5}))

# --- SECTION 7: identity (61-70) -------------------------------------------
A(ORD("How clearly do you know who you are?",
      ["Extremely clearly", "Very clearly", "Fairly clearly", "Somewhat unclear", "Very unclear",
       "Identity is constantly changing"],
      {"Self-Awareness": -0.8, "Stability Preference": -0.4},
      {"Openness": 0.7, "Adaptability": 0.6}))
A(ORD("How much does your profession form part of your identity?",
      ["Almost none", "Very little", "Somewhat", "Significantly", "Very strongly",
       "It depends on my current work"],
      {"Achievement Drive": 0.7, "Status Orientation": 0.4}))
A(ORD("How much do you identify with your family?",
      ["Extremely strongly", "Strongly", "Moderately", "Somewhat", "Very little", "It is complicated"],
      {"Relationship Orientation": -0.9, "Autonomy": 0.5},
      {"Self-Awareness": 0.5, "Emotional Intensity": 0.3}))
A(ORD("How much do you identify with your community or culture?",
      ["Extremely strongly", "Strongly", "Moderately", "Somewhat", "Very little",
       "I identify with multiple cultures"],
      {"Relationship Orientation": -0.8, "Independence of Thought": 0.5},
      {"Openness": 0.8, "Adaptability": 0.5}))
A(CAT("Which best describes your self-image?", [
    ("I know my strengths", {"Self-Awareness": 0.8, "Emotional Security": -0.3}),
    ("I focus on improving weaknesses", {"Self-Awareness": 0.6, "Achievement Drive": 0.5}),
    ("I am still figuring myself out", {"Openness": 0.6, "Self-Awareness": 0.3}),
    ("I frequently doubt myself", {"Emotional Security": 0.8, "Emotional Intensity": 0.5}),
    ("I have a very strong sense of self", {"Independence of Thought": 0.8, "Autonomy": 0.6}),
    ("My identity changes with circumstances", {"Adaptability": 0.9, "Stability Preference": -0.5})]))
A(ORD("How important is independence to your identity?",
      ["Extremely important", "Very important", "Moderately important", "Somewhat important",
       "Not very important", "I value interdependence"],
      {"Autonomy": -1.0}, {"Relationship Orientation": 0.7, "Autonomy": -0.4}))
A(CAT("What do you most want people to remember about you?", [
    ("That I was successful", {"Achievement Drive": 0.9, "Status Orientation": 0.5}),
    ("That I was kind", {"Empathy": 1.0}),
    ("That I was intelligent", {"Analytical Orientation": 0.7, "Status Orientation": 0.4}),
    ("That I changed something", {"Meaning Orientation": 0.8, "Social Influence": 0.6}),
    ("That I was free", {"Autonomy": 1.0}),
    ("That I loved people well", {"Relationship Orientation": 0.9, "Empathy": 0.6})]))
A(ORD("How much do you compare yourself with others?",
      ["Almost never", "Rarely", "Sometimes", "Often", "Very often", "Only with people similar to me"],
      {"Status Orientation": 0.8, "Emotional Security": 0.5},
      {"Status Orientation": 0.3, "Self-Awareness": 0.4}))
A(CAT("Which sounds most like you?", [
    ("I know exactly what I want", {"Structure": 0.7, "Persistence": 0.6}),
    ("I know what I don't want", {"Self-Awareness": 0.5}),
    ("I am exploring", {"Openness": 0.9}),
    ("I have many possible identities", {"Openness": 0.7, "Adaptability": 0.6}),
    ("I feel pulled between versions of myself", {"Emotional Intensity": 0.6, "Stability Preference": -0.5}),
    ("I am reinventing myself", {"Adaptability": 0.9, "Openness": 0.7})]))
A(CAT("What most strongly influences your self-worth?", [
    ("Achievement", {"Achievement Drive": 1.0}),
    ("Relationships", {"Relationship Orientation": 0.9}),
    ("Character", {"Meaning Orientation": 0.7, "Self-Awareness": 0.5}),
    ("Competence", {"Analytical Orientation": 0.6, "Persistence": 0.5}),
    ("Independence", {"Autonomy": 1.0}),
    ("Contribution", {"Meaning Orientation": 0.9, "Empathy": 0.5})]))

# --- SECTION 8: relationships (71-80) --------------------------------------
A(CAT("What do you need most from a romantic partner?", [
    ("Emotional security", {"Emotional Security": 1.0, "Stability Preference": 0.4}),
    ("Intellectual connection", {"Analytical Orientation": 0.7, "Openness": 0.5}),
    ("Passion", {"Emotional Intensity": 0.9}),
    ("Friendship", {"Relationship Orientation": 0.8}),
    ("Freedom", {"Autonomy": 1.0}),
    ("Shared ambition", {"Achievement Drive": 0.8})]))
A(ORD("How quickly do you become emotionally attached?",
      ["Very quickly", "Quickly", "Moderately", "Slowly", "Very slowly", "Only after deep trust"],
      {"Emotional Security": -0.8, "Autonomy": 0.6},
      {"Autonomy": 0.5, "Self-Awareness": 0.4}))
A(CAT("During conflict, you usually:", [
    ("Discuss it immediately", {"Social Energy": 0.6, "Emotional Intensity": 0.4}),
    ("Need time first", {"Self-Awareness": 0.6, "Social Energy": -0.4}),
    ("Try to compromise", {"Empathy": 0.8, "Adaptability": 0.5}),
    ("Become defensive", {"Emotional Security": 0.7, "Empathy": -0.4}),
    ("Withdraw", {"Autonomy": 0.7, "Relationship Orientation": -0.5}),
    ("Focus on solving the problem", {"Analytical Orientation": 0.8, "Emotional Intensity": -0.4})]))
A(ORD("How much personal space do you need in a relationship?",
      ["Very little", "Little", "Moderate", "A lot", "Very much", "It depends on the relationship"],
      {"Autonomy": 1.0, "Relationship Orientation": -0.5}))
A(CAT("What makes you feel loved?", [
    ("Words", {"Emotional Security": 0.5, "Relationship Orientation": 0.4}),
    ("Time", {"Relationship Orientation": 0.8}),
    ("Physical affection", {"Emotional Intensity": 0.6, "Relationship Orientation": 0.5}),
    ("Acts of service", {"Persistence": 0.4, "Empathy": 0.5}),
    ("Gifts", {"Status Orientation": 0.4}),
    ("Being understood and supported", {"Empathy": 0.7, "Self-Awareness": 0.5})]))
A(CAT("What most threatens a relationship for you?", [
    ("Dishonesty", {"Independence of Thought": 0.5}),
    ("Emotional distance", {"Emotional Security": 0.8, "Relationship Orientation": 0.5}),
    ("Control", {"Autonomy": 1.0}),
    ("Boredom", {"Openness": 0.8, "Stability Preference": -0.5}),
    ("Lack of ambition", {"Achievement Drive": 0.8}),
    ("Lack of respect", {"Status Orientation": 0.5, "Independence of Thought": 0.4})]))
A(ORD("How easily do you trust someone?",
      ["Immediately", "Fairly quickly", "Gradually", "Slowly", "Very slowly",
       "Trust depends on demonstrated consistency"],
      {"Emotional Security": -0.5, "Autonomy": 0.6},
      {"Analytical Orientation": 0.6, "Persistence": 0.3}))
A(ORD("If your partner earned substantially more than you, you would feel:",
      ["Completely comfortable", "Mostly comfortable", "Neutral", "Slightly uncomfortable",
       "Very uncomfortable", "It would motivate me"],
      {"Status Orientation": 0.7, "Emotional Security": 0.4},
      {"Achievement Drive": 0.8, "Status Orientation": 0.4}))
A(CAT("What kind of partner would complement you best?", [
    ("Similar to me", {"Stability Preference": 0.5, "Relationship Orientation": 0.4}),
    ("More emotionally stable", {"Emotional Intensity": 0.6, "Emotional Security": 0.4}),
    ("More adventurous", {"Risk Tolerance": -0.4, "Openness": 0.3}),
    ("More ambitious", {"Achievement Drive": -0.3, "Status Orientation": 0.3}),
    ("More independent", {"Autonomy": 0.6}),
    ("More nurturing", {"Emotional Security": 0.7, "Empathy": -0.2})]))
A(CAT("In close relationships, you tend to be:", [
    ("Highly nurturing", {"Empathy": 1.0, "Relationship Orientation": 0.6}),
    ("Protective", {"Relationship Orientation": 0.7, "Persistence": 0.4}),
    ("Independent", {"Autonomy": 1.0}),
    ("Emotionally expressive", {"Emotional Intensity": 0.9}),
    ("Analytical", {"Analytical Orientation": 0.8, "Emotional Intensity": -0.4}),
    ("Adaptable", {"Adaptability": 0.9})]))

# --- SECTION 9: social structure, power & status (81-90) -------------------
A(ORD("How comfortable are you around powerful people?",
      ["Extremely comfortable", "Comfortable", "Neutral", "Slightly uncomfortable",
       "Very uncomfortable", "I actively challenge authority"],
      {"Social Influence": -0.8, "Emotional Security": 0.4},
      {"Independence of Thought": 1.0, "Social Influence": 0.5}))
A(ORD("How important is social status?",
      ["Extremely important", "Very important", "Moderately important", "Slightly important",
       "Not important", "I care about competence more than status"],
      {"Status Orientation": -1.0}, {"Status Orientation": -0.6, "Analytical Orientation": 0.5}))
A(CAT("In groups, you naturally become:", [
    ("Leader", {"Social Influence": 1.0, "Achievement Drive": 0.5}),
    ("Organiser", {"Structure": 0.8, "Social Influence": 0.4}),
    ("Advisor", {"Analytical Orientation": 0.7, "Social Influence": 0.3}),
    ("Mediator", {"Empathy": 0.9, "Relationship Orientation": 0.5}),
    ("Specialist", {"Analytical Orientation": 0.6, "Autonomy": 0.5, "Social Influence": -0.4}),
    ("Observer", {"Social Energy": -0.8, "Self-Awareness": 0.5})]))
A(ORD("How do you react to hierarchy?",
      ["I prefer clear hierarchy", "I accept it when justified", "I am neutral",
       "I prefer equality", "I dislike hierarchy", "I prefer competence-based hierarchy"],
      {"Structure": -0.7, "Independence of Thought": 0.6},
      {"Analytical Orientation": 0.6, "Independence of Thought": 0.4}))
A(ORD("Networking feels:",
      ["Natural", "Comfortable", "Manageable", "Difficult", "Extremely uncomfortable",
       "Useful but exhausting"],
      {"Social Energy": -0.9, "Social Influence": -0.6},
      {"Social Energy": -0.4, "Self-Awareness": 0.5}))
A(CAT("When someone has more power than you, you usually:", [
    ("Respect their authority", {"Structure": 0.5, "Independence of Thought": -0.5}),
    ("Study how they operate", {"Analytical Orientation": 0.7, "Achievement Drive": 0.5}),
    ("Build a relationship", {"Social Influence": 0.8, "Relationship Orientation": 0.4}),
    ("Challenge them", {"Independence of Thought": 1.0, "Risk Tolerance": 0.5}),
    ("Avoid them", {"Social Energy": -0.7, "Emotional Security": 0.4}),
    ("Try to become independent of them", {"Autonomy": 1.0})]))
A(CAT("Which matters more?", [
    ("Influence", {"Social Influence": 1.0}),
    ("Expertise", {"Analytical Orientation": 0.8, "Persistence": 0.5}),
    ("Wealth", {"Status Orientation": 0.7, "Stability Preference": 0.4}),
    ("Reputation", {"Status Orientation": 0.9}),
    ("Freedom", {"Autonomy": 1.0}),
    ("Relationships", {"Relationship Orientation": 1.0})]))
A(ORD("How willing are you to negotiate?",
      ["Extremely willing", "Very willing", "Moderately willing", "Reluctant", "Very reluctant",
       "Only when the outcome matters"],
      {"Social Influence": -0.7, "Adaptability": -0.5},
      {"Analytical Orientation": 0.5, "Achievement Drive": 0.4}))
A(CAT("Which environment suits you best?", [
    ("Clear hierarchy", {"Structure": 0.8, "Stability Preference": 0.5}),
    ("Competitive environment", {"Achievement Drive": 0.9, "Status Orientation": 0.4}),
    ("Collaborative environment", {"Relationship Orientation": 0.7, "Empathy": 0.5}),
    ("Flat organisation", {"Independence of Thought": 0.6, "Autonomy": 0.5}),
    ("Entrepreneurial environment", {"Risk Tolerance": 0.9, "Autonomy": 0.6}),
    ("Independent environment", {"Autonomy": 1.0, "Social Energy": -0.4})]))
A(ORD("How comfortable are you promoting yourself?",
      ["Extremely comfortable", "Comfortable", "Neutral", "Uncomfortable", "Very uncomfortable",
       "Comfortable when I believe in my work"],
      {"Social Influence": -0.9, "Status Orientation": -0.5},
      {"Meaning Orientation": 0.6, "Social Influence": 0.3}))

# --- SECTION 10: culture, belonging & worldview (91-100) -------------------
A(ORD("How strongly do traditions influence your decisions?",
      ["Extremely strongly", "Strongly", "Moderately", "Slightly", "Very little",
       "I selectively preserve traditions"],
      {"Stability Preference": -0.8, "Openness": 0.6},
      {"Self-Awareness": 0.5, "Independence of Thought": 0.5}))
A(ORD("How important is belonging to a community?",
      ["Extremely important", "Very important", "Moderately important", "Somewhat important",
       "Not important", "I prefer several smaller communities"],
      {"Relationship Orientation": -0.9, "Autonomy": 0.5},
      {"Relationship Orientation": 0.3, "Openness": 0.4}))
A(ORD("How comfortable are you with people whose worldview differs from yours?",
      ["Extremely comfortable", "Comfortable", "Moderately comfortable", "Somewhat uncomfortable",
       "Very uncomfortable", "Comfortable if mutual respect exists"],
      {"Openness": -0.9, "Empathy": -0.4}, {"Openness": 0.5, "Self-Awareness": 0.4}))
A(ORD("How much does religion or spirituality influence your decisions?",
      ["Extremely strongly", "Strongly", "Moderately", "Slightly", "Not at all",
       "My spirituality is personal rather than institutional"],
      {"Meaning Orientation": -0.7, "Independence of Thought": 0.5},
      {"Meaning Orientation": 0.6, "Independence of Thought": 0.6}))
A(ORD("How important is preserving cultural identity?",
      ["Extremely important", "Very important", "Moderately important", "Slightly important",
       "Not very important", "I value culture but also change it"],
      {"Stability Preference": -0.8, "Openness": 0.5},
      {"Openness": 0.7, "Independence of Thought": 0.5}))
A(CAT("When your culture conflicts with your personal beliefs, you:", [
    ("Follow culture", {"Independence of Thought": -0.9, "Stability Preference": 0.5}),
    ("Follow personal beliefs", {"Independence of Thought": 1.0, "Autonomy": 0.5}),
    ("Search for compromise", {"Empathy": 0.6, "Adaptability": 0.6}),
    ("Question the tradition", {"Openness": 0.8, "Independence of Thought": 0.6}),
    ("Reject the cultural expectation", {"Independence of Thought": 1.0, "Relationship Orientation": -0.4}),
    ("Separate private belief from public behaviour", {"Adaptability": 0.7, "Self-Awareness": 0.5})]))
A(ORD("How important is language to your identity?",
      ["Extremely important", "Very important", "Moderately important", "Slightly important",
       "Not important", "I identify with multiple languages"],
      {"Relationship Orientation": -0.5, "Stability Preference": -0.4},
      {"Openness": 0.8, "Adaptability": 0.5}))
A(ORD("How strongly are you influenced by social expectations?",
      ["Extremely strongly", "Strongly", "Moderately", "Slightly", "Very little",
       "Only expectations from people I respect"],
      {"Independence of Thought": 1.0}, {"Independence of Thought": 0.5, "Self-Awareness": 0.5}))
A(CAT("What makes a community strong?", [
    ("Shared values", {"Meaning Orientation": 0.7, "Relationship Orientation": 0.4}),
    ("Shared identity", {"Relationship Orientation": 0.7, "Stability Preference": 0.4}),
    ("Rules", {"Structure": 0.8, "Stability Preference": 0.5}),
    ("Trust", {"Relationship Orientation": 0.7, "Empathy": 0.5}),
    ("Economic opportunity", {"Achievement Drive": 0.6, "Stability Preference": 0.4}),
    ("Mutual responsibility", {"Empathy": 0.7, "Persistence": 0.4})]))
A(ORD("How likely are you to challenge a widely accepted belief?",
      ["Very unlikely", "Unlikely", "Sometimes", "Often", "Very often",
       "Only after substantial research"],
      {"Independence of Thought": 1.0, "Openness": 0.5},
      {"Analytical Orientation": 0.9, "Independence of Thought": 0.5}))

# --- SECTION 11: environment, work & circumstances (101-110) ---------------
A(CAT("What work environment brings out your best?", [
    ("Highly structured", {"Structure": 1.0, "Stability Preference": 0.5}),
    ("Moderately structured", {"Structure": 0.5}),
    ("Flexible", {"Adaptability": 0.7, "Autonomy": 0.4}),
    ("Completely autonomous", {"Autonomy": 1.0, "Structure": -0.4}),
    ("Fast-moving", {"Risk Tolerance": 0.7, "Adaptability": 0.6}),
    ("Collaborative", {"Relationship Orientation": 0.7, "Social Energy": 0.5})]))
A(ORD("How do you handle uncertainty?",
      ["I dislike it strongly", "I prefer plans", "I can tolerate it", "I adapt easily",
       "I enjoy it", "I enjoy it when I control the downside"],
      {"Risk Tolerance": 1.0, "Adaptability": 0.6},
      {"Risk Tolerance": 0.6, "Analytical Orientation": 0.6}))
A(CAT("Which workplace would you prefer?", [
    ("Large established organisation", {"Stability Preference": 0.9, "Risk Tolerance": -0.5}),
    ("Growing company", {"Achievement Drive": 0.5, "Risk Tolerance": 0.3}),
    ("Startup", {"Risk Tolerance": 0.9, "Openness": 0.5}),
    ("Small specialist team", {"Analytical Orientation": 0.5, "Autonomy": 0.4}),
    ("Self-employment", {"Autonomy": 1.0, "Risk Tolerance": 0.6}),
    ("Portfolio or freelance career", {"Autonomy": 0.9, "Openness": 0.6, "Stability Preference": -0.5})]))
A(ORD("How important is geographic stability?",
      ["Extremely important", "Very important", "Moderately important", "Slightly important",
       "I prefer mobility", "I want the option to move"],
      {"Stability Preference": -0.9, "Openness": 0.5},
      {"Autonomy": 0.7, "Openness": 0.4}))
A(ORD("How important is remote work?",
      ["Essential", "Very important", "Nice to have", "Neutral", "I prefer in-person", "Hybrid is ideal"],
      {"Autonomy": -0.8, "Social Energy": 0.6}, {"Adaptability": 0.6}))
A(CAT("When circumstances suddenly change, you:", [
    ("Become stressed", {"Adaptability": -0.9, "Stability Preference": 0.6}),
    ("Make a new plan", {"Structure": 0.7, "Adaptability": 0.5}),
    ("Ask for information", {"Analytical Orientation": 0.6}),
    ("Adapt immediately", {"Adaptability": 1.0}),
    ("Become excited", {"Openness": 0.8, "Risk Tolerance": 0.6}),
    ("Look for the opportunity", {"Risk Tolerance": 0.7, "Achievement Drive": 0.5})]))
A(CAT("Which economic condition most affects your decisions?", [
    ("Financial security", {"Stability Preference": 0.9}),
    ("Income growth", {"Achievement Drive": 0.7}),
    ("Debt", {"Stability Preference": 0.7, "Risk Tolerance": -0.5}),
    ("Family responsibilities", {"Relationship Orientation": 0.8, "Stability Preference": 0.5}),
    ("Opportunity", {"Risk Tolerance": 0.7, "Openness": 0.5}),
    ("Long-term potential over short-term income", {"Persistence": 0.8, "Meaning Orientation": 0.5})]))
A(ORD("How much control do you need over your schedule?",
      ["Almost complete control", "A lot", "Moderate control", "Some structure helps",
       "I prefer someone else to structure it", "It depends on the work"],
      {"Autonomy": -1.0, "Structure": 0.5}))
A(CAT("Which resource is most valuable to you?", [
    ("Money", {"Stability Preference": 0.6, "Status Orientation": 0.4}),
    ("Time", {"Autonomy": 0.8}),
    ("Knowledge", {"Analytical Orientation": 0.8, "Openness": 0.5}),
    ("Connections", {"Social Influence": 0.9, "Relationship Orientation": 0.4}),
    ("Freedom", {"Autonomy": 1.0}),
    ("Energy", {"Self-Awareness": 0.5, "Adaptability": 0.4})]))
A(CAT("What most affects your productivity?", [
    ("Noise", {"Emotional Intensity": 0.6, "Social Energy": -0.4}),
    ("People", {"Social Energy": -0.5, "Autonomy": 0.4}),
    ("Stress", {"Emotional Intensity": 0.7, "Adaptability": -0.4}),
    ("Lack of structure", {"Structure": 0.9}),
    ("Lack of challenge", {"Achievement Drive": 0.8, "Openness": 0.5}),
    ("Lack of autonomy", {"Autonomy": 1.0})]))

# --- SECTION 12: time, development & life history (111-120) ----------------
A(ORD("How much do childhood experiences influence your current behaviour?",
      ["Extremely strongly", "Strongly", "Moderately", "Slightly", "Very little",
       "I am still discovering the influence"],
      {"Self-Awareness": -0.5, "Emotional Intensity": -0.4},
      {"Self-Awareness": 0.9, "Openness": 0.4}))
A(CAT("How would you describe your relationship with your past?", [
    ("I rarely think about it", {"Self-Awareness": -0.6, "Adaptability": 0.4}),
    ("I accept it", {"Self-Awareness": 0.6, "Emotional Intensity": -0.3}),
    ("I learn from it", {"Self-Awareness": 0.9, "Persistence": 0.4}),
    ("I regret parts of it", {"Emotional Intensity": 0.6, "Self-Awareness": 0.4}),
    ("I am strongly shaped by it", {"Emotional Intensity": 0.6, "Stability Preference": 0.4}),
    ("I actively try to redefine it", {"Adaptability": 0.8, "Openness": 0.6})]))
A(CAT("When you experience failure, you usually see it as:", [
    ("Evidence I am not capable", {"Emotional Security": 0.9, "Persistence": -0.6}),
    ("A temporary setback", {"Persistence": 0.8, "Adaptability": 0.5}),
    ("A lesson", {"Self-Awareness": 0.8, "Openness": 0.5}),
    ("Motivation", {"Achievement Drive": 0.9, "Persistence": 0.5}),
    ("A reason to change direction", {"Adaptability": 0.8, "Persistence": -0.3}),
    ("Information", {"Analytical Orientation": 0.9, "Emotional Intensity": -0.4})]))
A(ORD("How much have major life events changed you?",
      ["Very little", "Slightly", "Moderately", "Significantly", "Profoundly",
       "They have changed me repeatedly"],
      {"Adaptability": 0.6, "Stability Preference": -0.5},
      {"Adaptability": 0.9, "Openness": 0.5}))
A(ORD("How comfortable are you with personal change?",
      ["Very uncomfortable", "Somewhat uncomfortable", "Neutral", "Comfortable",
       "Very comfortable", "I actively seek transformation"],
      {"Adaptability": 1.0, "Openness": 0.6},
      {"Openness": 1.0, "Adaptability": 0.8, "Stability Preference": -0.6}))
A(CAT("Which stage of life feels most important right now?", [
    ("Establishing myself", {"Achievement Drive": 0.7, "Status Orientation": 0.4}),
    ("Building security", {"Stability Preference": 0.9}),
    ("Exploring possibilities", {"Openness": 0.9, "Risk Tolerance": 0.5}),
    ("Building relationships or family", {"Relationship Orientation": 0.9}),
    ("Achieving major goals", {"Achievement Drive": 0.9, "Persistence": 0.5}),
    ("Finding meaning", {"Meaning Orientation": 1.0, "Self-Awareness": 0.5})]))
A(ORD("How often do you reinvent yourself?",
      ["Almost never", "Rarely", "Occasionally", "Frequently", "Very frequently",
       "Whenever circumstances demand it"],
      {"Adaptability": 0.9, "Stability Preference": -0.6},
      {"Adaptability": 0.9, "Openness": 0.4}))
A(CAT("What do you most regret?", [
    ("Things I did", {"Self-Awareness": 0.5, "Emotional Intensity": 0.4}),
    ("Things I did not do", {"Risk Tolerance": -0.5, "Openness": 0.5}),
    ("Relationships I lost", {"Relationship Orientation": 0.9}),
    ("Opportunities I missed", {"Achievement Drive": 0.7, "Risk Tolerance": -0.3}),
    ("Time I wasted", {"Achievement Drive": 0.6, "Persistence": 0.4}),
    ("I focus more on the future than regret", {"Adaptability": 0.7, "Self-Awareness": 0.3})]))
A(CAT("What are you currently trying hardest to become?", [
    ("Successful", {"Achievement Drive": 1.0}),
    ("Secure", {"Stability Preference": 1.0}),
    ("Independent", {"Autonomy": 1.0}),
    ("Loved", {"Relationship Orientation": 0.9, "Emotional Security": 0.5}),
    ("Skilled", {"Persistence": 0.8, "Analytical Orientation": 0.4}),
    ("Fulfilled", {"Meaning Orientation": 1.0})]))
A(CAT("Which best describes your current life?", [
    ("I know exactly where I am going", {"Structure": 0.8, "Persistence": 0.6}),
    ("I have direction but need execution", {"Achievement Drive": 0.5, "Structure": -0.3}),
    ("I am exploring", {"Openness": 0.9}),
    ("I feel stuck", {"Adaptability": -0.6, "Emotional Intensity": 0.4}),
    ("I am rebuilding", {"Adaptability": 0.8, "Persistence": 0.5}),
    ("I am entering a major new chapter", {"Openness": 0.8, "Risk Tolerance": 0.5})]))

assert len(Q) == 120, f"expected 120 questions, built {len(Q)}"

# Consistency pairs: same concept, opposite wording. Wide disagreement between
# the two lowers reported confidence rather than being silently averaged.
CONSISTENCY = [[31, 34], [19, 39], [65, 73], [101, 107], [35, 88], [15, 112]]

# ---------------------------------------------------------------------------
# 25 types. Signature = the dimensions that must be high (+) or low (-).
# ---------------------------------------------------------------------------
T = lambda name, sig, s, w, careers, rel: {
    "n": name,
    "sig": {D[k]: v for k, v in sig.items()},
    "s": s, "w": w, "c": careers, "r": rel}

TYPES = [
T("The Strategic Builder", {"Achievement Drive":1,"Persistence":1,"Analytical Orientation":.8,"Structure":.8,"Autonomy":.6},
  ["Planning","Execution","Strategy","Discipline","Long-term thinking"],
  ["May overwork","May over-control","Difficulty slowing down","May measure self-worth through achievement"],
  ["Entrepreneurship","Operations","Engineering","Management","Finance","Strategy","Project leadership"],
  "A stable but ambitious partner who respects independence, communicates clearly and shares long-term goals."),
T("The Empathic Connector", {"Empathy":1,"Relationship Orientation":1,"Self-Awareness":.7,"Social Energy":.4},
  ["Listening","Emotional intelligence","Collaboration","Mediation","Relationship building"],
  ["May people-please","May struggle with boundaries","May take criticism personally","Risk of emotional exhaustion"],
  ["Counselling","Education","Human resources","Healthcare","Customer success","Community leadership"],
  "An emotionally safe, communicative and affectionate relationship where feelings are discussed rather than assumed."),
T("The Independent Explorer", {"Autonomy":1,"Openness":1,"Adaptability":.9,"Stability Preference":-.8},
  ["Innovation","Exploration","Flexibility","Independence","Problem solving"],
  ["May be inconsistent","May struggle with routine","May resist commitment","Prone to boredom"],
  ["Entrepreneurship","Consulting","Freelancing","Creative industries","Product innovation","Research"],
  "High trust with significant personal freedom, low controlling behaviour and a steady supply of novelty."),
T("The Creative Visionary", {"Creativity":1,"Openness":1,"Meaning Orientation":.8,"Structure":-.5},
  ["Creativity","Originality","Vision","Storytelling","Innovation"],
  ["Execution may be inconsistent","Sensitivity to criticism","May over-idealise","Struggles with bureaucracy"],
  ["Design","Film","Writing","Advertising","Architecture","Media","Product design"],
  "A partner who values imagination, gives room for absorption in work, and offers honest but gentle feedback."),
T("The Analytical Investigator", {"Analytical Orientation":1,"Openness":.8,"Autonomy":.8,"Social Energy":-.6},
  ["Research","Logic","Problem solving","Critical thinking","Pattern recognition"],
  ["Analysis paralysis","May seem emotionally detached","Overthinking","Social withdrawal"],
  ["Data science","Research","Engineering","Cybersecurity","Economics","Science","Technology"],
  "Intellectual connection with someone who does not require constant social activity or emotional performance."),
T("The Charismatic Influencer", {"Social Energy":1,"Social Influence":1,"Achievement Drive":.7,"Status Orientation":.6},
  ["Persuasion","Networking","Leadership","Presentation","Selling ideas"],
  ["Strong need for recognition","Impulsiveness","Overcommitment","Difficulty with quiet execution"],
  ["Sales","Media","Public leadership","Business development","Marketing","Entrepreneurship"],
  "A partner comfortable with a busy social life who provides honest grounding rather than constant admiration."),
T("The Reliable Guardian", {"Stability Preference":1,"Structure":1,"Persistence":.8,"Relationship Orientation":.6,"Risk Tolerance":-.7},
  ["Reliability","Loyalty","Organisation","Responsibility","Consistency"],
  ["Resistance to change","Excessive caution","Over-responsibility","Difficulty taking risks"],
  ["Administration","Compliance","Operations","Finance","Project management","Institutional leadership"],
  "A stable, loyal and predictable partnership, often family-oriented, where commitments are honoured."),
T("The Adventurous Catalyst", {"Risk Tolerance":1,"Adaptability":1,"Openness":.8,"Social Energy":.6,"Stability Preference":-.8},
  ["Courage","Initiative","Adaptability","Enterprise","Crisis response"],
  ["Impulsiveness","Restlessness","May take excessive risks","Struggles with repetition"],
  ["Entrepreneurship","Sales","Emergency response","Media","Travel","Negotiation"],
  "Someone who enjoys movement and change, and does not interpret restlessness as rejection."),
T("The Quiet Specialist", {"Social Energy":-1,"Analytical Orientation":.9,"Autonomy":.8,"Persistence":.7,"Social Influence":-.6},
  ["Expertise","Focus","Precision","Independent work"],
  ["May avoid networking","May under-promote own work","Risk of isolation"],
  ["Engineering","Programming","Research","Accounting","Technical specialisation","Writing"],
  "A calm relationship with plenty of quiet time and a partner who does not equate silence with distance."),
T("The Community Leader", {"Empathy":.9,"Social Influence":.9,"Meaning Orientation":.9,"Relationship Orientation":.7},
  ["Leadership","Community building","Mentorship","Communication"],
  ["May take responsibility for everyone","Burnout risk","Difficulty saying no"],
  ["Nonprofit leadership","Education","Public service","Management","Community development"],
  "A partner who shares your values and will actively protect your time from everyone else's demands."),
T("The Systems Architect", {"Analytical Orientation":1,"Structure":1,"Autonomy":.7,"Persistence":.7},
  ["Systems thinking","Optimisation","Planning","Managing complexity"],
  ["Perfectionism","Rigidity","May overengineer"],
  ["Engineering","Technology","Operations","Architecture","Systems design","Strategy"],
  "Someone comfortable with your need for order who can gently interrupt perfectionism."),
T("The Nurturing Caregiver", {"Empathy":1,"Relationship Orientation":1,"Emotional Security":.6,"Persistence":.6},
  ["Care","Patience","Support","Emotional understanding"],
  ["Self-neglect","Over-giving","Boundary difficulties"],
  ["Education","Healthcare","Counselling","Child development","Social services"],
  "A partner who actively looks after you too, rather than accepting care without returning it."),
T("The Competitive Achiever", {"Achievement Drive":1,"Status Orientation":.9,"Persistence":.8,"Risk Tolerance":.5},
  ["Drive","Ambition","Performance","Goal achievement"],
  ["Workaholism","Comparison with others","Burnout risk","Difficulty accepting failure"],
  ["Finance","Entrepreneurship","Sales","Executive leadership","Competitive professions"],
  "Someone secure enough not to compete with you, who can say when the drive has tipped into cost."),
T("The Diplomatic Mediator", {"Empathy":.9,"Social Influence":.7,"Adaptability":.7,"Emotional Intensity":-.4},
  ["Negotiation","Mediation","Diplomacy","Communication"],
  ["Conflict avoidance","Indecision","May compromise excessively"],
  ["Law","Diplomacy","Human resources","Negotiation","Management","Counselling"],
  "A direct partner who invites you to state your own preference rather than accommodating theirs."),
T("The Pragmatic Operator", {"Adaptability":.9,"Achievement Drive":.7,"Analytical Orientation":.5,"Openness":-.4},
  ["Execution","Troubleshooting","Practical judgement","Crisis management"],
  ["Impatience with theory","Short-term focus","May struggle to explain intuitive decisions"],
  ["Operations","Logistics","Management","Entrepreneurship","Sales"],
  "Someone practical who values getting things done and does not need lengthy emotional processing."),
T("The Philosophical Seeker", {"Meaning Orientation":1,"Openness":1,"Self-Awareness":.9,"Independence of Thought":.8},
  ["Wisdom","Reflection","Conceptual thinking","Big-picture understanding"],
  ["Overthinking","Detachment","Difficulty with conventional paths"],
  ["Philosophy","Research","Writing","Education","Strategy","Thought leadership"],
  "A partner who enjoys long conversations and does not mistake questioning for dissatisfaction."),
T("The Security Architect", {"Stability Preference":1,"Structure":.9,"Risk Tolerance":-1,"Persistence":.6},
  ["Risk management","Preparation","Reliability","Long-term planning"],
  ["Excessive caution","Anxiety around uncertainty","May miss opportunities"],
  ["Finance","Risk management","Compliance","Administration","Insurance","Planning"],
  "A steady relationship with clear plans, shared financial understanding and few sudden changes."),
T("The Social Entrepreneur", {"Meaning Orientation":1,"Achievement Drive":.8,"Empathy":.8,"Social Influence":.8},
  ["Vision","Leadership","Social impact","Networking"],
  ["Takes on too much","Idealism","Burnout risk"],
  ["Social enterprise","Nonprofits","Impact investing","Community ventures","Purpose-driven business"],
  "Someone who believes in the mission but will insist you rest, and mean it."),
T("The Adaptive Generalist", {"Adaptability":1,"Openness":.9,"Persistence":-.4,"Autonomy":.5},
  ["Learning quickly","Connecting different fields","Versatility","Problem solving"],
  ["May lack specialisation","Starts too many projects","Difficulty choosing a direction"],
  ["Consulting","Product management","Entrepreneurship","Strategy","Innovation"],
  "A partner who provides some continuity while enjoying your range rather than finding it unsettling."),
T("The Disciplined Craftsman", {"Persistence":1,"Structure":.9,"Analytical Orientation":.6,"Achievement Drive":.5,"Risk Tolerance":-.4},
  ["Skill development","Precision","Patience","Quality"],
  ["Perfectionism","Slow to adapt","May overfocus on detail"],
  ["Engineering","Skilled trades","Design","Programming","Medicine","Craft professions"],
  "Someone who respects deep work and does not read absorption as neglect."),
T("The Relational Idealist", {"Relationship Orientation":1,"Empathy":1,"Emotional Intensity":.9,"Meaning Orientation":.7},
  ["Loyalty","Emotional depth","Creativity","Devotion"],
  ["May idealise people","High sensitivity","Vulnerable to disappointment","Boundary difficulties"],
  ["Counselling","Arts","Education","Human-centred work"],
  "Deep emotional connection built on trust, communication and genuinely shared values."),
T("The Resilient Survivor", {"Adaptability":1,"Persistence":1,"Autonomy":1,"Emotional Security":-.6},
  ["Resilience","Resourcefulness","Courage","Practical adaptation"],
  ["Hyper-independence","Difficulty accepting help","Emotional guardedness"],
  ["Entrepreneurship","Leadership","Crisis management","Operations","High-autonomy roles"],
  "A patient partner who earns trust slowly and does not push for vulnerability before it is ready."),
T("The Balanced Builder", {"Adaptability":.6,"Structure":.5,"Empathy":.5,"Achievement Drive":.5,"Analytical Orientation":.5},
  ["Balance","Flexibility","Communication","Versatility"],
  ["May struggle to identify one direction","Can adapt so much that own preferences blur"],
  ["Management","Consulting","Product management","Entrepreneurship","General leadership"],
  "A partnership with clear mutual expectations, where you are regularly asked what you actually want."),
T("The Independent Guardian", {"Autonomy":1,"Persistence":.8,"Relationship Orientation":.6,"Emotional Intensity":-.5,"Structure":.6},
  ["Reliability","Protection","Self-sufficiency","Commitment"],
  ["Difficulty asking for help","Emotional guardedness","Takes on excessive responsibility"],
  ["Security","Engineering","Management","Operations","Entrepreneurship"],
  "Trust, respect and independence — a partner who is loyal without being demanding."),
T("The Transformational Reinventor", {"Openness":1,"Adaptability":1,"Autonomy":.9,"Self-Awareness":.8,"Stability Preference":-.9},
  ["Reinvention","Learning","Adaptation","Resilience","Personal growth"],
  ["Restlessness","Identity instability","May abandon projects early","Difficulty maintaining continuity"],
  ["Entrepreneurship","Innovation","Consulting","Creative industries","Strategy","Technology"],
  "Someone secure in themselves who can stay steady while you change, without feeling left behind."),
]
assert len(TYPES) == 25, len(TYPES)

payload = {
    "dims": [[n, lo, hi] for n, lo, hi in DIMS],
    "qs": Q,
    "types": TYPES,
    "pairs": CONSISTENCY,
}

out = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
with open("mk25data.json", "w", encoding="utf-8") as fh:
    fh.write(out)
print(f"  questions   : {len(Q)}")
print(f"  dimensions  : {len(DIMS)}")
print(f"  types       : {len(TYPES)}")
print(f"  consistency : {len(CONSISTENCY)} pairs")
print(f"  payload     : {len(out):,} chars")
