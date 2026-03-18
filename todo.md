# SciBot - Priority Improvements

## 1. Security — Move API Keys Server-Side
The Gemini API key is exposed client-side in `.env`. Anyone can decompile the app and steal it. Build a simple backend proxy (Firebase Cloud Functions is the easiest since you already use Firebase) that handles all Gemini calls. This is **non-negotiable** before any public release.

## 2. Make Personalization Real
The app promises "learning your own special way" but doesn't deliver. Add:
- **Per-topic mastery tracking** — record what the student gets right/wrong by topic
- **Adaptive difficulty** — quizzes get harder as the student improves on a topic
- **Spaced repetition** — resurface missed questions days later for retention
- **A simple dashboard** showing "you're strong in Biology, weak in Chemistry logarithms"

This is what turns the app from a homework solver into an actual learning tool.

## 3. Fix the Streak Bug & Gamification
The streak system has a bug (increments multiple times per day) and is the **only** engagement mechanic. Fix it, then add:
- XP points for completing activities
- Levels/badges for milestones
- Study reminders via push notifications

Without engagement hooks, students open the app once and forget it.

## 4. Break Up GeminiService
842 lines, 20+ methods, handles everything. Split it into focused services:
- `ChatAIService` — conversation
- `QuizGeneratorService` — quiz creation
- `HomeworkAIService` — extraction & solving
- `AudioScriptService` — lesson generation

This makes the code testable and maintainable.

## 5. Add Proper Error Handling & Offline Support
Right now if Gemini fails, the user gets a cryptic error or nothing. Add:
- Retry logic with exponential backoff for API calls
- Offline caching of recent quizzes, lessons, and homework
- Clear "you're offline" UI indicator
- Structured error types instead of raw strings

## 6. Curriculum Alignment
Map content to Albanian school grades (6-12). Students should be able to select their grade and get relevant topics. Without this, the app feels random rather than purposeful.

---

**Start with #1 and #2.** Security is a blocker for release, and personalization is the core value proposition — everything else builds on those two.
