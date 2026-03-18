/// Pyetjet e quiz-it të profilit kognitiv
class ProfileQuizQuestion {
  final String question;
  final List<ProfileQuizOption> options;
  final String category; // learningStyle, subjects, level, goal, time

  const ProfileQuizQuestion({
    required this.question,
    required this.options,
    required this.category,
  });
}

class ProfileQuizOption {
  final String text;
  final String value;
  final String emoji;

  const ProfileQuizOption({
    required this.text,
    required this.value,
    required this.emoji,
  });
}

const List<ProfileQuizQuestion> profileQuizQuestions = [
  // ═══════════════════════════════════════════════════════════
  // Pyetja 1: Stili i të mësuarit - Vizual vs Logjik
  // ═══════════════════════════════════════════════════════════
  ProfileQuizQuestion(
    question: 'Si të pëlqen më shumë të mësosh?',
    category: 'learningStyle',
    options: [
      ProfileQuizOption(
        text: 'Me figura, diagrama dhe video',
        value: 'vizual',
        emoji: '🎨',
      ),
      ProfileQuizOption(
        text: 'Me logjikë, hapa dhe formula',
        value: 'logjik',
        emoji: '🧠',
      ),
      ProfileQuizOption(
        text: 'Duke bërë eksperimente dhe praktikë',
        value: 'praktik',
        emoji: '🔬',
      ),
      ProfileQuizOption(
        text: 'Duke lexuar dhe marrë shënime',
        value: 'lexues',
        emoji: '📖',
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════
  // Pyetja 2: Stili i të mësuarit - Konfirmim
  // ═══════════════════════════════════════════════════════════
  ProfileQuizQuestion(
    question: 'Kur mëson diçka të re, çfarë të ndihmon më shumë?',
    category: 'learningStyle',
    options: [
      ProfileQuizOption(
        text: 'Të shoh një shembull vizual',
        value: 'vizual',
        emoji: '👁️',
      ),
      ProfileQuizOption(
        text: 'Të kuptoj pse funksionon ashtu',
        value: 'logjik',
        emoji: '💡',
      ),
      ProfileQuizOption(
        text: 'Të provoj vetë me duar',
        value: 'praktik',
        emoji: '✋',
      ),
      ProfileQuizOption(
        text: 'Të lexoj shpjegimin me detaje',
        value: 'lexues',
        emoji: '📝',
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════
  // Pyetja 3: Lëndët e preferuara
  // ═══════════════════════════════════════════════════════════
  ProfileQuizQuestion(
    question: 'Cilat lëndë të pëlqejnë më shumë? (Zgjidh sa të duash)',
    category: 'subjects',
    options: [
      ProfileQuizOption(
        text: 'Matematikë',
        value: 'Matematikë',
        emoji: '📐',
      ),
      ProfileQuizOption(
        text: 'Fizikë',
        value: 'Fizikë',
        emoji: '⚡',
      ),
      ProfileQuizOption(
        text: 'Kimi',
        value: 'Kimi',
        emoji: '🧪',
      ),
      ProfileQuizOption(
        text: 'Biologji',
        value: 'Biologji',
        emoji: '🧬',
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════
  // Pyetja 4: Niveli aktual
  // ═══════════════════════════════════════════════════════════
  ProfileQuizQuestion(
    question: 'Si e vlerëson nivelin tënd aktual në shkencë?',
    category: 'level',
    options: [
      ProfileQuizOption(
        text: 'Fillestar - Sapo po filloj',
        value: 'fillestar',
        emoji: '🌱',
      ),
      ProfileQuizOption(
        text: 'Mesatar - Di bazat, dua të mësoj më shumë',
        value: 'mesatar',
        emoji: '📚',
      ),
      ProfileQuizOption(
        text: 'I avancuar - Dua sfida të vështira',
        value: 'avancuar',
        emoji: '🚀',
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════
  // Pyetja 5: Qëllimi
  // ═══════════════════════════════════════════════════════════
  ProfileQuizQuestion(
    question: 'Cili është qëllimi yt kryesor?',
    category: 'goal',
    options: [
      ProfileQuizOption(
        text: 'Përgatitje për provim',
        value: 'provim',
        emoji: '📝',
      ),
      ProfileQuizOption(
        text: 'Nota më të mira në shkollë',
        value: 'nota',
        emoji: '⭐',
      ),
      ProfileQuizOption(
        text: 'Kuriozitet - Dua të mësoj gjëra të reja',
        value: 'kuriozitet',
        emoji: '🔍',
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════
  // Pyetja 6: Koha e disponueshme
  // ═══════════════════════════════════════════════════════════
  ProfileQuizQuestion(
    question: 'Sa kohë ke në dispozicion për mësim çdo ditë?',
    category: 'time',
    options: [
      ProfileQuizOption(
        text: '15 minuta',
        value: '15',
        emoji: '⏱️',
      ),
      ProfileQuizOption(
        text: '30 minuta',
        value: '30',
        emoji: '🕐',
      ),
      ProfileQuizOption(
        text: '1 orë',
        value: '60',
        emoji: '🕑',
      ),
      ProfileQuizOption(
        text: 'Më shumë se 1 orë',
        value: '90',
        emoji: '🕒',
      ),
    ],
  ),
];
