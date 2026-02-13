class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String subject;
  final String difficulty;
  final String? explanation;
  final bool isCustom;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.subject,
    required this.difficulty,
    this.explanation,
    this.isCustom = false,
  });

  QuizQuestion copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correctIndex,
    String? subject,
    String? difficulty,
    String? explanation,
    bool? isCustom,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      subject: subject ?? this.subject,
      difficulty: difficulty ?? this.difficulty,
      explanation: explanation ?? this.explanation,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'options': options,
    'correctIndex': correctIndex,
    'subject': subject,
    'difficulty': difficulty,
    'explanation': explanation,
    'isCustom': isCustom,
  };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    id: json['id'] ?? '',
    question: json['question'] ?? '',
    options: (json['options'] as List?)?.cast<String>() ?? [],
    correctIndex: json['correctIndex'] ?? 0,
    subject: json['subject'] ?? '',
    difficulty: json['difficulty'] ?? 'lehtë',
    explanation: json['explanation'],
    isCustom: json['isCustom'] ?? true,
  );
}

class QuizData {
  static const List<Map<String, dynamic>> subjects = [
    {'name': 'Matematikë', 'icon': '📐', 'color': 0xFF4CAF50},
    {'name': 'Kimi', 'icon': '⚗️', 'color': 0xFF2196F3},
    {'name': 'Biologji', 'icon': '🧬', 'color': 0xFF9C27B0},
    {'name': 'Fizikë', 'icon': '⚛️', 'color': 0xFFFF9800},
  ];

  // ═══════════════════════════════════════════════════════════════
  // MATEMATIKË - 10 Pyetje
  // ═══════════════════════════════════════════════════════════════
  static const List<QuizQuestion> matematike = [
    QuizQuestion(
      id: 'quiz_mat_1',
      question: 'Sa është vlera e x në ekuacionin: 2x + 5 = 15?',
      options: ['3', '5', '7', '10'],
      correctIndex: 1,
      subject: 'Matematikë',
      difficulty: 'lehtë',
      explanation: '2x + 5 = 15 → 2x = 10 → x = 5',
    ),
    QuizQuestion(
      id: 'quiz_mat_2',
      question: 'Cila është rrënja katrore e 144?',
      options: ['11', '12', '13', '14'],
      correctIndex: 1,
      subject: 'Matematikë',
      difficulty: 'lehtë',
      explanation: '√144 = 12 sepse 12 × 12 = 144',
    ),
    QuizQuestion(
      id: 'quiz_mat_3',
      question: 'Nëse sin(θ) = 0.5, sa është θ në gradë?',
      options: ['30°', '45°', '60°', '90°'],
      correctIndex: 0,
      subject: 'Matematikë',
      difficulty: 'mesatar',
      explanation: 'sin(30°) = 0.5 është një vlerë e njohur trigonometrike',
    ),
    QuizQuestion(
      id: 'quiz_mat_4',
      question: 'Sa është 3! (3 faktoriel)?',
      options: ['3', '6', '9', '27'],
      correctIndex: 1,
      subject: 'Matematikë',
      difficulty: 'lehtë',
      explanation: '3! = 3 × 2 × 1 = 6',
    ),
    QuizQuestion(
      id: 'quiz_mat_5',
      question: 'Cili është termi i 10-të i vargut aritmetik: 2, 5, 8, 11, ...?',
      options: ['26', '29', '32', '35'],
      correctIndex: 1,
      subject: 'Matematikë',
      difficulty: 'mesatar',
      explanation: 'a₁ = 2, d = 3, a₁₀ = 2 + (10-1)×3 = 2 + 27 = 29',
    ),
    QuizQuestion(
      id: 'quiz_mat_6',
      question: 'Sa është log₁₀(1000)?',
      options: ['2', '3', '4', '10'],
      correctIndex: 1,
      subject: 'Matematikë',
      difficulty: 'mesatar',
      explanation: 'log₁₀(1000) = 3 sepse 10³ = 1000',
    ),
    QuizQuestion(
      id: 'quiz_mat_7',
      question: 'Cila është formula e sipërfaqes së rrethit?',
      options: ['2πr', 'πr²', 'πd', '2πr²'],
      correctIndex: 1,
      subject: 'Matematikë',
      difficulty: 'lehtë',
      explanation: 'Sipërfaqja e rrethit = π × r²',
    ),
    QuizQuestion(
      id: 'quiz_mat_8',
      question: 'Sa është shuma e këndeve të brendshme të një gjashtëkëndëshi?',
      options: ['360°', '540°', '720°', '900°'],
      correctIndex: 2,
      subject: 'Matematikë',
      difficulty: 'mesatar',
      explanation: 'Shuma = (n-2) × 180° = (6-2) × 180° = 720°',
    ),
    QuizQuestion(
      id: 'quiz_mat_9',
      question: 'Nëse f(x) = x² + 3x, sa është f(2)?',
      options: ['8', '10', '12', '14'],
      correctIndex: 1,
      subject: 'Matematikë',
      difficulty: 'lehtë',
      explanation: 'f(2) = 2² + 3×2 = 4 + 6 = 10',
    ),
    QuizQuestion(
      id: 'quiz_mat_10',
      question: 'Cili është derivati i funksionit f(x) = 3x²?',
      options: ['3x', '6x', '6x²', '9x'],
      correctIndex: 1,
      subject: 'Matematikë',
      difficulty: 'vështirë',
      explanation: 'f\'(x) = 2 × 3x = 6x (rregulli i fuqisë)',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // KIMI - 10 Pyetje
  // ═══════════════════════════════════════════════════════════════
  static const List<QuizQuestion> kimi = [
    QuizQuestion(
      id: 'quiz_kim_1',
      question: 'Cili është simboli kimik i arit?',
      options: ['Ag', 'Au', 'Ar', 'Al'],
      correctIndex: 1,
      subject: 'Kimi',
      difficulty: 'lehtë',
      explanation: 'Au vjen nga latinishtja "Aurum" që do të thotë ar',
    ),
    QuizQuestion(
      id: 'quiz_kim_2',
      question: 'Sa elektrone ka atomi i karbonit?',
      options: ['4', '6', '8', '12'],
      correctIndex: 1,
      subject: 'Kimi',
      difficulty: 'lehtë',
      explanation: 'Karboni ka numër atomik 6, pra ka 6 elektrone',
    ),
    QuizQuestion(
      id: 'quiz_kim_3',
      question: 'Cila është formula kimike e ujit?',
      options: ['H₂O', 'HO₂', 'H₂O₂', 'OH'],
      correctIndex: 0,
      subject: 'Kimi',
      difficulty: 'lehtë',
      explanation: 'Uji përbëhet nga 2 atome hidrogjen dhe 1 atom oksigjen',
    ),
    QuizQuestion(
      id: 'quiz_kim_4',
      question: 'Cili gaz është më i bollshëm në atmosferën e Tokës?',
      options: ['Oksigjen', 'Dioksid karboni', 'Azot', 'Argon'],
      correctIndex: 2,
      subject: 'Kimi',
      difficulty: 'mesatar',
      explanation: 'Azoti përbën rreth 78% të atmosferës',
    ),
    QuizQuestion(
      id: 'quiz_kim_5',
      question: 'Cili është pH i një tretësire neutrale?',
      options: ['0', '7', '10', '14'],
      correctIndex: 1,
      subject: 'Kimi',
      difficulty: 'lehtë',
      explanation: 'pH 7 është neutral, <7 është acid, >7 është bazik',
    ),
    QuizQuestion(
      id: 'quiz_kim_6',
      question: 'Cila lidhje kimike formohet kur elektronet ndahen midis atomeve?',
      options: ['Jonike', 'Kovalente', 'Metalike', 'Hidrogjeni'],
      correctIndex: 1,
      subject: 'Kimi',
      difficulty: 'mesatar',
      explanation: 'Lidhja kovalente formohet kur atomet ndajnë elektrone',
    ),
    QuizQuestion(
      id: 'quiz_kim_7',
      question: 'Cili është numri atomik i oksigjenit?',
      options: ['6', '7', '8', '16'],
      correctIndex: 2,
      subject: 'Kimi',
      difficulty: 'lehtë',
      explanation: 'Oksigjeni ka 8 protone në bërthamë, pra numër atomik 8',
    ),
    QuizQuestion(
      id: 'quiz_kim_8',
      question: 'Cila është formula e kripës së tryezës?',
      options: ['KCl', 'NaCl', 'CaCl₂', 'MgCl₂'],
      correctIndex: 1,
      subject: 'Kimi',
      difficulty: 'lehtë',
      explanation: 'Kripa e tryezës është klorur natriumi (NaCl)',
    ),
    QuizQuestion(
      id: 'quiz_kim_9',
      question: 'Çfarë lloj reaksioni është: 2H₂ + O₂ → 2H₂O?',
      options: ['Dekompozim', 'Sintezë', 'Zëvendësim', 'Neutralizim'],
      correctIndex: 1,
      subject: 'Kimi',
      difficulty: 'mesatar',
      explanation: 'Dy ose më shumë substanca bashkohen për të formuar një produkt',
    ),
    QuizQuestion(
      id: 'quiz_kim_10',
      question: 'Sa vlen numri i Avogadros?',
      options: ['6.02 × 10²³', '3.14 × 10²³', '9.81 × 10²³', '1.38 × 10²³'],
      correctIndex: 0,
      subject: 'Kimi',
      difficulty: 'mesatar',
      explanation: 'Numri i Avogadros = 6.022 × 10²³ grimca për mol',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // BIOLOGJI - 10 Pyetje
  // ═══════════════════════════════════════════════════════════════
  static const List<QuizQuestion> biologji = [
    QuizQuestion(
      id: 'quiz_bio_1',
      question: 'Cili organeli qelizor është "fabrika e energjisë"?',
      options: ['Bërthama', 'Ribozomet', 'Mitokondria', 'Kloroplasti'],
      correctIndex: 2,
      subject: 'Biologji',
      difficulty: 'lehtë',
      explanation: 'Mitokondria prodhon ATP përmes frymëmarrjes qelizore',
    ),
    QuizQuestion(
      id: 'quiz_bio_2',
      question: 'Sa kromozome ka një qelizë normale njerëzore?',
      options: ['23', '46', '44', '48'],
      correctIndex: 1,
      subject: 'Biologji',
      difficulty: 'lehtë',
      explanation: 'Njerëzit kanë 46 kromozome (23 çifte)',
    ),
    QuizQuestion(
      id: 'quiz_bio_3',
      question: 'Cila bazë azotike NUK gjendet në ADN?',
      options: ['Adenina', 'Timina', 'Uracili', 'Guanina'],
      correctIndex: 2,
      subject: 'Biologji',
      difficulty: 'mesatar',
      explanation: 'Uracili gjendet në ARN, jo në ADN. ADN ka Timinë',
    ),
    QuizQuestion(
      id: 'quiz_bio_4',
      question: 'Çfarë quhet procesi ku bimët prodhojnë ushqim nga drita?',
      options: ['Frymëmarrja', 'Fotosenteza', 'Fermentimi', 'Transpirimi'],
      correctIndex: 1,
      subject: 'Biologji',
      difficulty: 'lehtë',
      explanation: 'Fotosenteza konverton dritën në energji kimike (glukozë)',
    ),
    QuizQuestion(
      id: 'quiz_bio_5',
      question: 'Cili sistem i trupit kontrollon aktivitetet vullnetare?',
      options: ['Sistemi nervor autonom', 'Sistemi nervor somatik', 'Sistemi endokrin', 'Sistemi limfatik'],
      correctIndex: 1,
      subject: 'Biologji',
      difficulty: 'mesatar',
      explanation: 'Sistemi nervor somatik kontrollon lëvizjet vullnetare',
    ),
    QuizQuestion(
      id: 'quiz_bio_6',
      question: 'Cili është organi më i madh i trupit të njeriut?',
      options: ['Mëlçia', 'Mushkëritë', 'Lëkura', 'Zorret'],
      correctIndex: 2,
      subject: 'Biologji',
      difficulty: 'lehtë',
      explanation: 'Lëkura është organi më i madh, rreth 2m² sipërfaqe',
    ),
    QuizQuestion(
      id: 'quiz_bio_7',
      question: 'Çfarë lloj qelize prodhon antitrupa?',
      options: ['Qelizat e kuqe', 'Qelizat B', 'Qelizat T', 'Trombocitet'],
      correctIndex: 1,
      subject: 'Biologji',
      difficulty: 'mesatar',
      explanation: 'Qelizat B (limfocitet B) prodhojnë antitrupa',
    ),
    QuizQuestion(
      id: 'quiz_bio_8',
      question: 'Cili hormon rregullon nivelin e sheqerit në gjak?',
      options: ['Adrenalina', 'Insulina', 'Tiroksina', 'Kortizoli'],
      correctIndex: 1,
      subject: 'Biologji',
      difficulty: 'lehtë',
      explanation: 'Insulina ul nivelin e sheqerit duke lejuar qelizat të marrin glukozë',
    ),
    QuizQuestion(
      id: 'quiz_bio_9',
      question: 'Sa dhëmbë ka një i rritur normal?',
      options: ['28', '30', '32', '34'],
      correctIndex: 2,
      subject: 'Biologji',
      difficulty: 'lehtë',
      explanation: 'Të rriturit kanë 32 dhëmbë përfshirë 4 dhëmbët e urtësisë',
    ),
    QuizQuestion(
      id: 'quiz_bio_10',
      question: 'Çfarë quhet procesi i ndarjes qelizore që prodhon qeliza gjenetikisht identike?',
      options: ['Mejoza', 'Mitoza', 'Meioza', 'Binarja'],
      correctIndex: 1,
      subject: 'Biologji',
      difficulty: 'mesatar',
      explanation: 'Mitoza prodhon 2 qeliza bija identike me qelizën mëmë',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // FIZIKË - 10 Pyetje
  // ═══════════════════════════════════════════════════════════════
  static const List<QuizQuestion> fizike = [
    QuizQuestion(
      id: 'quiz_fiz_1',
      question: 'Sa është shpejtësia e dritës në vakum (përafërsisht)?',
      options: ['300,000 m/s', '300,000 km/s', '30,000 km/s', '3,000,000 km/s'],
      correctIndex: 1,
      subject: 'Fizikë',
      difficulty: 'lehtë',
      explanation: 'c ≈ 3 × 10⁸ m/s = 300,000 km/s',
    ),
    QuizQuestion(
      id: 'quiz_fiz_2',
      question: 'Cila është njësia e forcës në SI?',
      options: ['Joule', 'Watt', 'Newton', 'Pascal'],
      correctIndex: 2,
      subject: 'Fizikë',
      difficulty: 'lehtë',
      explanation: 'Forca matet në Newton (N). 1 N = 1 kg·m/s²',
    ),
    QuizQuestion(
      id: 'quiz_fiz_3',
      question: 'Sipas ligjit të dytë të Njutonit, F = ?',
      options: ['m/a', 'm × a', 'm + a', 'm - a'],
      correctIndex: 1,
      subject: 'Fizikë',
      difficulty: 'lehtë',
      explanation: 'Forca = masë × nxitim (F = m × a)',
    ),
    QuizQuestion(
      id: 'quiz_fiz_4',
      question: 'Cila është vlera e nxitimit të rënies së lirë në Tokë?',
      options: ['9.8 m/s', '9.8 m/s²', '10 m/s', '10 km/s²'],
      correctIndex: 1,
      subject: 'Fizikë',
      difficulty: 'lehtë',
      explanation: 'g ≈ 9.8 m/s² (shpesh përafrohet si 10 m/s²)',
    ),
    QuizQuestion(
      id: 'quiz_fiz_5',
      question: 'Cila është formula e energjisë kinetike?',
      options: ['mgh', '½mv²', 'mv', 'ma'],
      correctIndex: 1,
      subject: 'Fizikë',
      difficulty: 'mesatar',
      explanation: 'Energjia kinetike = ½ × masë × shpejtësi²',
    ),
    QuizQuestion(
      id: 'quiz_fiz_6',
      question: 'Çfarë lloj vale është zëri?',
      options: ['Elektromagnetike', 'Tërthore', 'Gjatësore', 'Dritë'],
      correctIndex: 2,
      subject: 'Fizikë',
      difficulty: 'mesatar',
      explanation: 'Zëri është valë gjatësore që udhëton përmes materialeve',
    ),
    QuizQuestion(
      id: 'quiz_fiz_7',
      question: 'Cila është njësia e rezistencës elektrike?',
      options: ['Volt', 'Amper', 'Ohm', 'Watt'],
      correctIndex: 2,
      subject: 'Fizikë',
      difficulty: 'lehtë',
      explanation: 'Rezistenca matet në Ohm (Ω). V = IR',
    ),
    QuizQuestion(
      id: 'quiz_fiz_8',
      question: 'Çfarë ndodh me gjatësinë e valës kur frekuenca rritet?',
      options: ['Rritet', 'Zvogëlohet', 'Mbetet njësoj', 'Bëhet zero'],
      correctIndex: 1,
      subject: 'Fizikë',
      difficulty: 'mesatar',
      explanation: 'v = f × λ. Nëse v është konstante dhe f rritet, λ zvogëlohet',
    ),
    QuizQuestion(
      id: 'quiz_fiz_9',
      question: 'Cili shkencëtar zbuloi ligjin e gravitacionit universal?',
      options: ['Einstein', 'Galileo', 'Newton', 'Kepler'],
      correctIndex: 2,
      subject: 'Fizikë',
      difficulty: 'lehtë',
      explanation: 'Isaac Newton formuloi ligjin e gravitacionit universal',
    ),
    QuizQuestion(
      id: 'quiz_fiz_10',
      question: 'Sa vlen 1 kWh në Joule?',
      options: ['1,000 J', '3,600 J', '3,600,000 J', '1,000,000 J'],
      correctIndex: 2,
      subject: 'Fizikë',
      difficulty: 'vështirë',
      explanation: '1 kWh = 1000 W × 3600 s = 3,600,000 J = 3.6 MJ',
    ),
  ];

  static List<QuizQuestion> getAllQuestions() {
    return [...matematike, ...kimi, ...biologji, ...fizike];
  }

  static List<QuizQuestion> getQuestionsBySubject(String subject) {
    switch (subject) {
      case 'Matematikë':
        return matematike;
      case 'Kimi':
        return kimi;
      case 'Biologji':
        return biologji;
      case 'Fizikë':
        return fizike;
      default:
        return getAllQuestions();
    }
  }

  static List<QuizQuestion> getRandomQuiz(String? subject, int count) {
    List<QuizQuestion> pool;
    if (subject != null && subject.isNotEmpty) {
      pool = getQuestionsBySubject(subject);
    } else {
      pool = getAllQuestions();
    }
    
    pool = List.from(pool)..shuffle();
    return pool.take(count).toList();
  }
}
