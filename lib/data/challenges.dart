class Challenge {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String difficulty; // 'lehtë', 'mesatar', 'vështirë'
  final String iconEmoji;
  final List<String> hints;
  final String? imageUrl;
  final bool isCustom;
  final String? puzzleType; // 'formula', 'balance', 'match', null for regular
  final List<String>? puzzleElements; // Elements for puzzle challenges
  final String? correctAnswer;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.difficulty,
    required this.iconEmoji,
    this.hints = const [],
    this.imageUrl,
    this.isCustom = false,
    this.puzzleType,
    this.puzzleElements,
    this.correctAnswer,
  });
}

class ChallengesData {
  // ═══════════════════════════════════════════════════════════════
  // MATEMATIKË - 5 Sfida
  // ═══════════════════════════════════════════════════════════════
  static const List<Challenge> matematike = [
    Challenge(
      id: 'mat_1',
      title: 'Ekuacionet Kuadratike',
      description: 'Zgjidh ekuacionin: x² - 5x + 6 = 0. Gjej të dyja rrënjët dhe verifiko zgjidhjen.',
      subject: 'Matematikë',
      difficulty: 'lehtë',
      iconEmoji: '📐',
      hints: [
        'Përdor formulën: x = (-b ± √(b²-4ac)) / 2a',
        'Identifiko a=1, b=-5, c=6',
        'Kontrollo: a cilat numra kur shumëzohen japin 6 dhe kur mblidhen japin 5?',
      ],
      correctAnswer: '2',
    ),
    Challenge(
      id: 'mat_2',
      title: 'Teorema e Pitagorës',
      description: 'Një shkallë 10m është mbështetur në mur. Baza e shkallës është 6m larg murit. Sa lart arrin shkalla në mur?',
      subject: 'Matematikë',
      difficulty: 'lehtë',
      iconEmoji: '📏',
      hints: [
        'Përdor formulën: a² + b² = c²',
        'Hipotenuza (shkalla) = 10m, një katet = 6m',
        'Zgjidh për katetin tjetër: b = √(c² - a²)',
      ],
      correctAnswer: '8',
    ),
    Challenge(
      id: 'mat_3',
      title: 'Probabiliteti me Zare',
      description: 'Nëse hedh dy zare, cila është probabiliteti që shuma të jetë 7? Shprehe si thyesë dhe përqindje.',
      subject: 'Matematikë',
      difficulty: 'mesatar',
      iconEmoji: '🎲',
      hints: [
        'Numri total i rezultateve = 6 × 6 = 36',
        'Gjej të gjitha kombinimet që japin 7: (1,6), (2,5), (3,4)...',
        'Mos harro: (1,6) dhe (6,1) janë të ndryshme!',
      ],
      correctAnswer: '6',
    ),
    Challenge(
      id: 'mat_4',
      title: 'Funksionet Logaritmike',
      description: 'Zgjidh për x: log₂(x) + log₂(x-2) = 3. Verifiko që zgjidhja është e vlefshme.',
      subject: 'Matematikë',
      difficulty: 'vështirë',
      iconEmoji: '📊',
      hints: [
        'Përdor vetinë: log(a) + log(b) = log(a·b)',
        'Kjo bëhet: log₂(x(x-2)) = 3',
        'Pra: x(x-2) = 2³ = 8',
      ],
      correctAnswer: '4',
    ),
    Challenge(
      id: 'mat_5',
      title: 'Vargjet Aritmetike',
      description: 'Në një varg aritmetik, termi i 5-të është 17 dhe termi i 12-të është 38. Gjej diferencën d.',
      subject: 'Matematikë',
      difficulty: 'mesatar',
      iconEmoji: '🔢',
      hints: [
        'Formula: aₙ = a₁ + (n-1)d',
        'Shkruaj dy ekuacione: a₅ = a₁ + 4d = 17 dhe a₁₂ = a₁ + 11d = 38',
        'Zgjidh sistemin e ekuacioneve',
      ],
      correctAnswer: '3',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // KIMI - 5 Sfida + 5 Formula Puzzles
  // ═══════════════════════════════════════════════════════════════
  static const List<Challenge> kimi = [
    Challenge(
      id: 'kim_1',
      title: 'Balancimi i Ekuacioneve',
      description: 'Balanço ekuacionin kimik: Fe + O₂ → Fe₂O₃. Sa atome hekur dhe oksigjen nevojiten?',
      subject: 'Kimi',
      difficulty: 'lehtë',
      iconEmoji: '⚗️',
      hints: [
        'Fillo me elementin më kompleks (Fe₂O₃)',
        'Fe₂O₃ ka 2 Fe dhe 3 O',
        'O₂ ka 2 O, pra duhen 3/2 O₂ ose 3 O₂ për 2 Fe₂O₃',
      ],
      correctAnswer: '4Fe + 3O₂ → 2Fe₂O₃',
    ),
    Challenge(
      id: 'kim_2',
      title: 'Struktura e Atomit',
      description: 'Atomi i Klorit (Cl) ka numër atomik 17 dhe numër masiv 35. Sa protone, neutrone dhe elektrone ka?',
      subject: 'Kimi',
      difficulty: 'lehtë',
      iconEmoji: '⚛️',
      hints: [
        'Numri atomik = numri i protoneve',
        'Numri i elektroneve = numri i protoneve (për atom neutral)',
        'Neutronet = Numri masiv - Numri atomik',
      ],
      correctAnswer: '17 protone, 18 neutrone, 17 elektrone',
    ),
    Challenge(
      id: 'kim_3',
      title: 'Reaksionet Acid-Bazë',
      description: 'Çfarë produktesh formohen kur HCl reagon me NaOH? Shkruaj ekuacionin e plotë dhe identifiko tipin e reaksionit.',
      subject: 'Kimi',
      difficulty: 'mesatar',
      iconEmoji: '🧪',
      hints: [
        'Ky është reaksion neutralizimi',
        'Acid + Bazë → Kripë + Ujë',
        'Na nga NaOH bashkohet me Cl nga HCl',
      ],
      correctAnswer: 'HCl + NaOH → NaCl + H₂O',
    ),
    Challenge(
      id: 'kim_4',
      title: 'Llogaritjet Molare',
      description: 'Sa gram NaCl (M=58.5 g/mol) nevojiten për të përgatitur 500 mL tretësirë 0.5 M?',
      subject: 'Kimi',
      difficulty: 'mesatar',
      iconEmoji: '⚖️',
      hints: [
        'Formula: n = M × V (ku V është në litra)',
        'n = 0.5 mol/L × 0.5 L = 0.25 mol',
        'masa = n × M = 0.25 × 58.5 g',
      ],
      correctAnswer: '14.625 gram',
    ),
    Challenge(
      id: 'kim_5',
      title: 'Lidhjet Kimike',
      description: 'Shpjego pse H₂O ka pikë vlimi më të lartë se H₂S, edhe pse S është më i rëndë se O.',
      subject: 'Kimi',
      difficulty: 'vështirë',
      iconEmoji: '🔗',
      hints: [
        'Mendo për lidhjet hidrogjenore',
        'O është më elektronegativ se S',
        'Lidhjet hidrogjenore janë më të forta në H₂O',
      ],
      correctAnswer: 'Lidhjet hidrogjenore në H₂O janë më të forta',
    ),
    // Formula Puzzles
    Challenge(
      id: 'kim_puzzle_1',
      title: '🧩 Puzzle: Krijo Ujin',
      description: 'Bashko elementet për të krijuar formulën e ujit. Zvarrit elementet në vendin e duhur.',
      subject: 'Kimi',
      difficulty: 'lehtë',
      iconEmoji: '💧',
      puzzleType: 'formula',
      puzzleElements: ['H', 'H', 'O'],
      correctAnswer: 'H₂O',
      hints: [
        'Uji ka 2 atome hidrogjeni',
        'Uji ka 1 atom oksigjeni',
        'Formula: H₂O',
      ],
    ),
    Challenge(
      id: 'kim_puzzle_2',
      title: '🧩 Puzzle: Krijo Kripën',
      description: 'Bashko elementet për të krijuar formulën e kripës së tryezës (Natrium Klorid).',
      subject: 'Kimi',
      difficulty: 'lehtë',
      iconEmoji: '🧂',
      puzzleType: 'formula',
      puzzleElements: ['Na', 'Cl'],
      correctAnswer: 'NaCl',
      hints: [
        'Kripa ka 1 atom natriumi',
        'Kripa ka 1 atom klori',
        'Formula: NaCl',
      ],
    ),
    Challenge(
      id: 'kim_puzzle_3',
      title: '🧩 Puzzle: Acid Sulfurik',
      description: 'Bashko elementet për të krijuar formulën e acidit sulfurik.',
      subject: 'Kimi',
      difficulty: 'mesatar',
      iconEmoji: '⚠️',
      puzzleType: 'formula',
      puzzleElements: ['H', 'H', 'S', 'O', 'O', 'O', 'O'],
      correctAnswer: 'H₂SO₄',
      hints: [
        'Acidi sulfurik ka 2 atome hidrogjeni',
        'Ka 1 atom squfuri',
        'Ka 4 atome oksigjeni',
      ],
    ),
    Challenge(
      id: 'kim_puzzle_4',
      title: '🧩 Puzzle: Glukoza',
      description: 'Krijo formulën e glukozës - sheqerit që na jep energji.',
      subject: 'Kimi',
      difficulty: 'vështirë',
      iconEmoji: '🍬',
      puzzleType: 'formula',
      puzzleElements: ['C', 'C', 'C', 'C', 'C', 'C', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'O', 'O', 'O', 'O', 'O', 'O'],
      correctAnswer: 'C₆H₁₂O₆',
      hints: [
        'Glukoza ka 6 atome karboni',
        'Ka 12 atome hidrogjeni',
        'Ka 6 atome oksigjeni',
      ],
    ),
    Challenge(
      id: 'kim_puzzle_5',
      title: '🧩 Puzzle: Balanco Reaksionin',
      description: 'Balanco reaksionin: H₂ + O₂ → H₂O. Vendos koeficientët e duhur.',
      subject: 'Kimi',
      difficulty: 'mesatar',
      iconEmoji: '⚖️',
      puzzleType: 'balance',
      puzzleElements: ['2', 'H₂', '+', '1', 'O₂', '→', '2', 'H₂O'],
      correctAnswer: '2H₂ + O₂ → 2H₂O',
      hints: [
        'Numëro atomet e H në të dyja anët',
        'Numëro atomet e O në të dyja anët',
        'Vendos koeficientë për ti barazuar',
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // BIOLOGJI - 5 Sfida
  // ═══════════════════════════════════════════════════════════════
  static const List<Challenge> biologji = [
    Challenge(
      id: 'bio_1',
      title: 'Mitoza vs Mejoza',
      description: 'Një qelizë me 46 kromozome i nënshtrohet mitozës dhe një tjetër mejozës. Sa kromozome kanë qelizat bija në secilin rast?',
      subject: 'Biologji',
      difficulty: 'lehtë',
      iconEmoji: '🧬',
      hints: [
        'Mitoza prodhon qeliza identike me prindin',
        'Mejoza prodhon qeliza me gjysmën e kromozomeve',
        'Mejoza është për qelizat seksuale (gametët)',
      ],
    ),
    Challenge(
      id: 'bio_2',
      title: 'Fotosinteza',
      description: 'Shkruaj ekuacionin e fotosintezës. Çfarë ndodh me energjinë diellore gjatë këtij procesi?',
      subject: 'Biologji',
      difficulty: 'lehtë',
      iconEmoji: '🌱',
      hints: [
        'Reaktantët: CO₂ + H₂O + dritë',
        'Produktet: Glukozë + O₂',
        'Energjia ruhet në lidhjet e glukozës',
      ],
    ),
    Challenge(
      id: 'bio_3',
      title: 'Trashëgimia Gjenetike',
      description: 'Nëse të dy prindërit janë heterozigotë (Aa) për një tipar dominant, cili është probabiliteti që fëmija të shfaqë tiparin recesiv?',
      subject: 'Biologji',
      difficulty: 'mesatar',
      iconEmoji: '👨‍👩‍👧',
      hints: [
        'Bëj katrorin e Punnett-it',
        'Kryqëzo Aa × Aa',
        'Numëro sa janë AA, Aa, dhe aa',
      ],
    ),
    Challenge(
      id: 'bio_4',
      title: 'Sistemi Tretës',
      description: 'Përshkruaj rrugën e një cope buke nga goja deri në thithjen e nutrientëve. Cilat enzima veprojnë?',
      subject: 'Biologji',
      difficulty: 'mesatar',
      iconEmoji: '🍞',
      hints: [
        'Fillo me amilazën në pështymë',
        'Stomaku, zorra e hollë, pankreasi',
        'Ku thithen nutrientët?',
      ],
    ),
    Challenge(
      id: 'bio_5',
      title: 'Ekosistemi dhe Zinxhiri Ushqimor',
      description: 'Në një ekosistem, nëse popullsia e gjarpërinjve bie drastikisht, si do të ndikojë kjo në popullatën e brejtësve dhe bimëve?',
      subject: 'Biologji',
      difficulty: 'vështirë',
      iconEmoji: '🦎',
      hints: [
        'Gjarpërinjtë janë grabitqarë të brejtësve',
        'Mendo për efektin kaskadë',
        'Çfarë ndodh kur ka më pak grabitqarë?',
      ],
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // FIZIKË - 5 Sfida
  // ═══════════════════════════════════════════════════════════════
  static const List<Challenge> fizike = [
    Challenge(
      id: 'fiz_1',
      title: 'Ligjet e Njutonit',
      description: 'Një makinë 1000 kg përshpejton nga 0 në 20 m/s për 10 sekonda. Llogarit forcën neto që vepron mbi të.',
      subject: 'Fizikë',
      difficulty: 'lehtë',
      iconEmoji: '🚗',
      hints: [
        'Gjej përshpejtimin: a = Δv / Δt',
        'Përdor ligjin e dytë: F = m × a',
        'a = (20-0) / 10 = 2 m/s²',
      ],
    ),
    Challenge(
      id: 'fiz_2',
      title: 'Energjia Potenciale',
      description: 'Një top 0.5 kg lëshohet nga lartësia 10m. Me çfarë shpejtësie do të godasë tokën? (g = 10 m/s²)',
      subject: 'Fizikë',
      difficulty: 'lehtë',
      iconEmoji: '⚽',
      hints: [
        'Përdor ruajtjen e energjisë',
        'EP fillestare = EK përfundimtare',
        'mgh = ½mv², zgjidh për v',
      ],
    ),
    Challenge(
      id: 'fiz_3',
      title: 'Qarqet Elektrike',
      description: 'Tre rezistorë 6Ω janë lidhur në paralel me një bateri 12V. Llogarit rezistencën ekuivalente dhe rrymën totale.',
      subject: 'Fizikë',
      difficulty: 'mesatar',
      iconEmoji: '⚡',
      hints: [
        'Për paralel: 1/R_eq = 1/R₁ + 1/R₂ + 1/R₃',
        'Pastaj përdor ligjin e Omit: I = V / R',
        '1/R_eq = 1/6 + 1/6 + 1/6 = 3/6 = 1/2',
      ],
    ),
    Challenge(
      id: 'fiz_4',
      title: 'Valët dhe Zëri',
      description: 'Një valë zanore ka frekuencë 440 Hz dhe gjatësi vale 0.77m. Llogarit shpejtësinë e zërit dhe identifiko notën muzikore.',
      subject: 'Fizikë',
      difficulty: 'mesatar',
      iconEmoji: '🔊',
      hints: [
        'Formula: v = f × λ',
        'v = 440 × 0.77 m/s',
        '440 Hz është nota A4 (La)',
      ],
    ),
    Challenge(
      id: 'fiz_5',
      title: 'Optika - Pasqyrat',
      description: 'Një objekt vendoset 30 cm para një pasqyre përmbledhëse me largësi fokale 20 cm. Ku formohet imazhi dhe si është ai?',
      subject: 'Fizikë',
      difficulty: 'vështirë',
      iconEmoji: '🔍',
      hints: [
        'Përdor formulën: 1/f = 1/do + 1/di',
        '1/20 = 1/30 + 1/di',
        'Zgjidh për di dhe gjej zmadhimin: m = -di/do',
      ],
    ),
  ];

  // Të gjitha sfidat së bashku
  static List<Challenge> get allChallenges => [
    ...matematike,
    ...kimi,
    ...biologji,
    ...fizike,
  ];

  // Merr sfidat sipas lëndës
  static List<Challenge> getBySubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'matematikë':
        return matematike;
      case 'kimi':
        return kimi;
      case 'biologji':
        return biologji;
      case 'fizikë':
        return fizike;
      default:
        return allChallenges;
    }
  }

  // Subjects list
  static const List<Map<String, String>> subjects = [
    {'name': 'Matematikë', 'emoji': '📐'},
    {'name': 'Kimi', 'emoji': '⚗️'},
    {'name': 'Biologji', 'emoji': '🧬'},
    {'name': 'Fizikë', 'emoji': '⚡'},
  ];
}
