import '../models/challenge_model.dart';

List<ChallengeModel> getMockChallenges() {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  return [
    // --- 3 DAILY FEATURED CHALLENGES (Always available today) ---
    ChallengeModel(
      id: 'challenge-daily-gk',
      title: 'Daily World & Science Trivia',
      description:
          'Test your worldly wisdom with curated questions spanning history, geography, space, and culture.',
      category: ChallengeCategory.generalKnowledge,
      difficulty: ChallengeDifficulty.beginner,
      status: ChallengeStatus.available,
      questionCount: 10,
      timeLimitSeconds: 600, // 10 minutes
      maxPoints: 100,
      type: ChallengeType.quiz,
      startedAt: todayStart,
    ),
    ChallengeModel(
      id: 'challenge-daily-tech',
      title: 'Daily Full-Stack & Systems Blitz',
      description:
          'Sharpen your software engineering acumen with questions on algorithms, web protocols, and cloud architecture.',
      category: ChallengeCategory.programming,
      difficulty: ChallengeDifficulty.intermediate,
      status: ChallengeStatus.available,
      questionCount: 10,
      timeLimitSeconds: 900, // 15 minutes
      maxPoints: 120,
      type: ChallengeType.quiz,
      startedAt: todayStart,
    ),
    ChallengeModel(
      id: 'challenge-daily-code',
      title: 'Code Duel: String & Array Mastery',
      description:
          'Solve practical algorithmic challenges with real test cases in Dart, Python, or JavaScript.',
      category: ChallengeCategory.programming,
      difficulty: ChallengeDifficulty.beginner,
      status: ChallengeStatus.available,
      questionCount: 1,
      timeLimitSeconds: 1800, // 30 minutes
      maxPoints: 100,
      supportedLanguages: const ['dart', 'python', 'javascript'],
      type: ChallengeType.coding,
      startedAt: todayStart,
    ),

    // --- CLOUD COMPUTING ---
    const ChallengeModel(
      id: 'challenge-cloud-01',
      title: 'Cloud Architecture Essentials',
      description:
          'Explore core cloud fundamentals including AWS, Azure, Google Cloud, microservices, and serverless design.',
      category: ChallengeCategory.cloudComputing,
      difficulty: ChallengeDifficulty.intermediate,
      status: ChallengeStatus.available,
      questionCount: 10,
      timeLimitSeconds: 600,
      maxPoints: 100,
      type: ChallengeType.quiz,
    ),

    // --- DEVOPS ---
    const ChallengeModel(
      id: 'challenge-devops-01',
      title: 'CI/CD & Docker Orchestration',
      description:
          'Test your knowledge on containers, Kubernetes, automated deployment pipelines, and infrastructure as code.',
      category: ChallengeCategory.devOps,
      difficulty: ChallengeDifficulty.intermediate,
      status: ChallengeStatus.available,
      questionCount: 10,
      timeLimitSeconds: 600,
      maxPoints: 100,
      type: ChallengeType.quiz,
    ),

    // --- NETWORKING ---
    const ChallengeModel(
      id: 'challenge-net-01',
      title: 'Networking & Protocols Sprint',
      description:
          'Dive deep into TCP/IP, DNS, HTTP/3, WebSocket protocols, and socket architecture.',
      category: ChallengeCategory.networking,
      difficulty: ChallengeDifficulty.beginner,
      status: ChallengeStatus.completed,
      questionCount: 10,
      timeLimitSeconds: 600,
      maxPoints: 100,
      type: ChallengeType.quiz,
      userScore: 90,
      userAccuracy: 90.0,
    ),

    // --- DATABASES ---
    const ChallengeModel(
      id: 'challenge-db-01',
      title: 'SQL, NoSQL & Data Modeling',
      description:
          'Indexing strategies, ACID transactions, CAP theorem, and distributed database sharding.',
      category: ChallengeCategory.databases,
      difficulty: ChallengeDifficulty.intermediate,
      status: ChallengeStatus.available,
      questionCount: 10,
      timeLimitSeconds: 600,
      maxPoints: 100,
      type: ChallengeType.quiz,
    ),

    // --- CYBERSECURITY ---
    const ChallengeModel(
      id: 'challenge-sec-01',
      title: 'Defensive Security & Cryptography',
      description:
          'OWASP Top 10 vulnerabilities, asymmetric encryption, JWT security, and threat modeling.',
      category: ChallengeCategory.cybersecurity,
      difficulty: ChallengeDifficulty.advanced,
      status: ChallengeStatus.inProgress,
      questionCount: 10,
      timeLimitSeconds: 900,
      maxPoints: 150,
      type: ChallengeType.quiz,
    ),

    // --- APTITUDE ---
    const ChallengeModel(
      id: 'challenge-apt-01',
      title: 'Logical Deduction & Reasoning',
      description:
          'Speed up your analytical thinking with pattern recognition, spatial puzzles, and deductive logic.',
      category: ChallengeCategory.aptitude,
      difficulty: ChallengeDifficulty.beginner,
      status: ChallengeStatus.available,
      questionCount: 10,
      timeLimitSeconds: 600,
      maxPoints: 100,
      type: ChallengeType.quiz,
    ),

    // --- MATHEMATICS ---
    const ChallengeModel(
      id: 'challenge-math-01',
      title: 'Discrete Math & Combinatorics',
      description:
          'Graph theory fundamentals, modular arithmetic, probability, and recurrence relations.',
      category: ChallengeCategory.mathematics,
      difficulty: ChallengeDifficulty.advanced,
      status: ChallengeStatus.locked,
      questionCount: 10,
      timeLimitSeconds: 900,
      maxPoints: 150,
      type: ChallengeType.quiz,
    ),

    // --- UPCOMING CODING DUEL ---
    const ChallengeModel(
      id: 'challenge-code-adv-01',
      title: 'Advanced Dynamic Programming Duel',
      description:
          'Tackle complex dynamic programming and graph problems against the clock.',
      category: ChallengeCategory.programming,
      difficulty: ChallengeDifficulty.advanced,
      status: ChallengeStatus.upcoming,
      questionCount: 2,
      timeLimitSeconds: 2400,
      maxPoints: 200,
      supportedLanguages: ['dart', 'python', 'javascript'],
      type: ChallengeType.coding,
    ),

    // --- COMPLETED GENERAL KNOWLEDGE ---
    const ChallengeModel(
      id: 'challenge-gk-history',
      title: 'Historical Turning Points',
      description:
          'Decisive battles, groundbreaking inventions, and iconic treaties that reshaped world history.',
      category: ChallengeCategory.generalKnowledge,
      difficulty: ChallengeDifficulty.intermediate,
      status: ChallengeStatus.completed,
      questionCount: 10,
      timeLimitSeconds: 600,
      maxPoints: 100,
      type: ChallengeType.quiz,
      userScore: 80,
      userAccuracy: 80.0,
    ),

    // --- ADVANCED CLOUD ARCHITECTURE ---
    const ChallengeModel(
      id: 'challenge-cloud-adv',
      title: 'Multi-Region High Availability',
      description:
          'Disaster recovery, global VPC peering, multi-master replication, and zero-downtime migrations.',
      category: ChallengeCategory.cloudComputing,
      difficulty: ChallengeDifficulty.advanced,
      status: ChallengeStatus.locked,
      questionCount: 10,
      timeLimitSeconds: 900,
      maxPoints: 150,
      type: ChallengeType.quiz,
    ),

    // --- IN PROGRESS DATABASE PERFORMANCE ---
    const ChallengeModel(
      id: 'challenge-db-adv',
      title: 'Query Optimization & EXPLAIN Plans',
      description:
          'Analyze query execution plans, B-Tree vs LSM trees, and memory buffer management.',
      category: ChallengeCategory.databases,
      difficulty: ChallengeDifficulty.advanced,
      status: ChallengeStatus.available,
      questionCount: 10,
      timeLimitSeconds: 900,
      maxPoints: 150,
      type: ChallengeType.quiz,
    ),
  ];
}

final List<ChallengeModel> mockChallenges = getMockChallenges();

List<ChallengeModel> getDailyFeaturedChallenges() {
  return mockChallenges
      .where(
        (c) =>
            c.id == 'challenge-daily-gk' ||
            c.id == 'challenge-daily-tech' ||
            c.id == 'challenge-daily-code',
      )
      .toList();
}

ChallengeModel? getMockChallengeById(String id) {
  try {
    return mockChallenges.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
