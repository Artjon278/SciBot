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



  6. Weekly Report (Raporti Javor)

  - Cdo te diele gjeneron raport automatik per javen
  - Permban: sa ore mesove, sa tema perfundove, sa quiz bere
  - Tregon pikat e forta te javes: "U permiresove ne termodinamike me 20%"
  - Tregon pikat per fokus: "Algjebra ka nevoje per me shume praktike"
  - Krahason me javen e kaluar (progres ose regres)
  - Jep 3 objektiva konkrete per javen e ardhshme
  - Mund te ndertohet si PDF ose te ndahet me prinderit

  ---
  7. Challenge Mode (Menyra e Sfides)

  - Garë me veten: rezultati i djeshëm vs sot per te njejten teme
  - Leaderboard anonim: renditet sipas pikeve javore (pa emra, vetem avatare)
  - Daily Challenge: nje sfide e re cdo dite, e njejte per te gjithe studentet
  - Streak sfidash: sa dite rresht ke perfunduar Daily Challenge
  - Badge/Achievement sistem: "Mbreti i Fizikes", "7 dite rresht", "100 pergjigje te
  sakta"
  - XP (experience points) per cdo aktivitet: quiz, detyre, bisede, sfide

  ---
  8. Personaliteti Adaptiv i AI-it

  - AI zbulon personalitetin e studentit me kohe (jo vetem nga onboarding quiz)
  - Per student te shpejte: pergjigje direkte, pa hyrje te gjata, me shume sfida
  - Per student qe dyshon ne vete: me shume inkurajim, celebron cdo sukses te vogel
  - Per student kurioz: jep "fun facts", lidh temat me jeten reale
  - Per student qe ngutet: jep permbledhje te shkurtra, bullet points
  - Toni ndryshon sipas lendes: me formal ne matematike, me i lire ne biologji
  - Studenti mund te zgjedhe manualisht: "Dua AI me strikt" ose "Dua AI miqesor"

  ---
  9. Study Streaks+ (Streak i Avancuar)

  - Jo vetem "hape app-in" por "meso dicka te re" per te ruajtur streak-un
  - Streak per lende: sa dite rresht ke mesuar fizike, matematike, etj
  - Milestone rewards: ne 7 dite, 30 dite, 100 dite - badge speciale
  - Freeze: 1 dite ne jave mund ta "ngrish" streak-un pa e humbur
  - Weekly goal: vendos vete sa minuta/dite do mesosh, streak llogaritet vetem nese e
  arrin
  - Vizualizim kalendarik: si GitHub contributions graph per mesimin tend

  ---
  10. Smart Notifications (Njoftimet Inteligjente)

  - Kujton studentin ne oren qe ai zakonisht meson (meson nga sjellja)
  - "Ke 3 dite pa mesuar fizike, po e humb streak-un!"
  - "Tema X po te harrohet, bej nje quiz te shpejte"
  - "Raporti javor eshte gati, shikoje!"
  - "Sfida e dites eshte gati, 47 studente e kane perfunduar tashme"
  - Frekuenca e njoftimeve adaptohet: nese studenti i injoron, ulen automatikisht