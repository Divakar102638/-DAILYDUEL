import '../models/question_model.dart';

// 10 General Knowledge Questions (Assigned to 'challenge-daily-gk')
final List<QuestionModel> mockGkQuestions = [
  const QuestionModel(
    id: 'gk-q-001',
    challengeId: 'challenge-daily-gk',
    questionText:
        'Which planet in our solar system has the highest surface temperature?',
    options: ['Mercury', 'Venus', 'Mars', 'Jupiter'],
    correctOptionIndex: 1,
    explanation:
        'Although Mercury is closest to the Sun, Venus has a thick atmosphere of greenhouse gases that traps heat, creating average surface temperatures around 465°C.',
    points: 10,
    difficultyWeight: 1.0,
  ),
  const QuestionModel(
    id: 'gk-q-002',
    challengeId: 'challenge-daily-gk',
    questionText:
        'In which year did the Apollo 11 mission successfully land humans on the Moon?',
    options: ['1967', '1968', '1969', '1971'],
    correctOptionIndex: 2,
    explanation:
        'Neil Armstrong and Buzz Aldrin landed the Apollo 11 Lunar Module on the Moon on July 20, 1969.',
    points: 10,
    difficultyWeight: 1.0,
  ),
  const QuestionModel(
    id: 'gk-q-003',
    challengeId: 'challenge-daily-gk',
    questionText: 'What is the largest living structure on Earth?',
    options: [
      'The Amazon Rainforest',
      'The Great Barrier Reef',
      'Pando Aspen Grove',
      'The Redwood Forest',
    ],
    correctOptionIndex: 1,
    explanation:
        'The Great Barrier Reef stretches over 2,300 kilometers off the coast of Australia and is visible from space.',
    points: 10,
    difficultyWeight: 1.0,
  ),
  const QuestionModel(
    id: 'gk-q-004',
    challengeId: 'challenge-daily-gk',
    questionText:
        'Which chemical element has the highest melting point of all elements?',
    options: ['Titanium', 'Carbon', 'Tungsten', 'Platinum'],
    correctOptionIndex: 2,
    explanation:
        'Tungsten has the highest melting point of any metallic element at 3,422°C (6,192°F).',
    points: 10,
    difficultyWeight: 1.2,
  ),
  const QuestionModel(
    id: 'gk-q-005',
    challengeId: 'challenge-daily-gk',
    questionText:
        'Which strait separates continental Europe from the African continent?',
    options: [
      'Strait of Hormuz',
      'Strait of Malacca',
      'Strait of Gibraltar',
      'Bosporus Strait',
    ],
    correctOptionIndex: 2,
    explanation:
        'The Strait of Gibraltar connects the Atlantic Ocean to the Mediterranean Sea and separates Spain from Morocco.',
    points: 10,
    difficultyWeight: 1.0,
  ),
  const QuestionModel(
    id: 'gk-q-006',
    challengeId: 'challenge-daily-gk',
    questionText:
        'Who was the first woman to win a Nobel Prize and the only person to win in two different scientific fields?',
    options: [
      'Rosalind Franklin',
      'Marie Curie',
      'Ada Lovelace',
      'Lise Meitner',
    ],
    correctOptionIndex: 1,
    explanation:
        'Marie Curie won the Nobel Prize in Physics (1903) and the Nobel Prize in Chemistry (1911).',
    points: 10,
    difficultyWeight: 1.0,
  ),
  const QuestionModel(
    id: 'gk-q-007',
    challengeId: 'challenge-daily-gk',
    questionText: 'What is the capital city of Australia?',
    options: ['Sydney', 'Melbourne', 'Canberra', 'Brisbane'],
    correctOptionIndex: 2,
    explanation:
        'Canberra was selected as the compromise location between rival cities Sydney and Melbourne in 1908.',
    points: 10,
    difficultyWeight: 1.0,
  ),
  const QuestionModel(
    id: 'gk-q-008',
    challengeId: 'challenge-daily-gk',
    questionText:
        'What natural phenomenon causes the Aurora Borealis (Northern Lights)?',
    options: [
      'Atmospheric ozone depletion',
      'Solar wind particles interacting with Earth\'s magnetic field',
      'Reflections of sunlight from polar ice sheets',
      'High-altitude volcanic ash dispersal',
    ],
    correctOptionIndex: 1,
    explanation:
        'Charged solar particles collide with atmospheric gases like oxygen and nitrogen guided by Earth\'s magnetic field lines.',
    points: 10,
    difficultyWeight: 1.1,
  ),
  const QuestionModel(
    id: 'gk-q-009',
    challengeId: 'challenge-daily-gk',
    questionText:
        'In literature, who authored the epic dystopian masterpiece "Nineteen Eighty-Four"?',
    options: [
      'Aldous Huxley',
      'George Orwell',
      'Ray Bradbury',
      'Philip K. Dick',
    ],
    correctOptionIndex: 1,
    explanation:
        'George Orwell (Eric Arthur Blair) published "Nineteen Eighty-Four" in 1949 as an analysis of totalitarianism.',
    points: 10,
    difficultyWeight: 1.0,
  ),
  const QuestionModel(
    id: 'gk-q-010',
    challengeId: 'challenge-daily-gk',
    questionText:
        'Which ancient civilization built the monumental Machu Picchu complex in Peru?',
    options: ['Mayans', 'Aztecs', 'Incas', 'Toltecs'],
    correctOptionIndex: 2,
    explanation:
        'Machu Picchu was built by the Inca Empire under Emperor Pachacuti around 1450 CE high in the Andes Mountains.',
    points: 10,
    difficultyWeight: 1.0,
  ),
];

// 10 Technical / Programming Questions (Assigned to 'challenge-daily-tech')
final List<QuestionModel> mockTechQuestions = [
  const QuestionModel(
    id: 'tech-q-001',
    challengeId: 'challenge-daily-tech',
    questionText:
        'What is the average time complexity of searching for an element in a Hash Table with good distribution?',
    options: ['O(1)', 'O(log n)', 'O(n)', 'O(n log n)'],
    correctOptionIndex: 0,
    explanation:
        'Hash tables achieve constant O(1) average lookup time by computing hash buckets directly from key values.',
    points: 12,
    difficultyWeight: 1.0,
  ),
  const QuestionModel(
    id: 'tech-q-002',
    challengeId: 'challenge-daily-tech',
    questionText:
        'In Dart and Flutter, what is the primary purpose of the "const" constructor?',
    options: [
      'It creates immutable compile-time constants and enables widget reuse in the render tree',
      'It executes widget building asynchronously on a background isolate',
      'It bypasses the garbage collector and allocates memory in native C++ heap',
      'It enables hot reloading for stateful variables during development',
    ],
    correctOptionIndex: 0,
    explanation:
        'In Dart, const constructors create canonicalized instances at compile time, reducing memory allocations and skipping unnecessary rebuilds in Flutter.',
    points: 12,
    difficultyWeight: 1.1,
  ),
  const QuestionModel(
    id: 'tech-q-003',
    challengeId: 'challenge-daily-tech',
    questionText:
        'In relational databases, which ACID property guarantees that all operations within a transaction succeed or none do?',
    options: ['Atomicity', 'Consistency', 'Isolation', 'Durability'],
    correctOptionIndex: 0,
    explanation:
        'Atomicity guarantees that a transaction is treated as a single indivisible unit: either all changes are committed, or none are.',
    points: 12,
    difficultyWeight: 1.0,
  ),
  const QuestionModel(
    id: 'tech-q-004',
    challengeId: 'challenge-daily-tech',
    questionText:
        'Which HTTP response status code represents "429 Too Many Requests"?',
    options: [
      '401 Unauthorized',
      '403 Forbidden',
      '429 Too Many Requests',
      '503 Service Unavailable',
    ],
    correctOptionIndex: 2,
    explanation:
        'HTTP 429 indicates that the client has sent too many requests in a given amount of time (rate limiting).',
    points: 12,
    difficultyWeight: 1.0,
  ),
  const QuestionModel(
    id: 'tech-q-005',
    challengeId: 'challenge-daily-tech',
    questionText:
        'In Python, what is the key difference between a "list" and a "tuple"?',
    options: [
      'Lists are mutable while tuples are immutable',
      'Tuples can store heterogeneous types while lists cannot',
      'Lists use hash tables while tuples use linked lists',
      'Tuples execute in C-level parallel threads while lists do not',
    ],
    correctOptionIndex: 0,
    explanation:
        'Lists in Python can be modified after creation (mutable), whereas tuples cannot have elements modified, added, or removed (immutable).',
    points: 12,
    difficultyWeight: 1.0,
  ),
  const QuestionModel(
    id: 'tech-q-006',
    challengeId: 'challenge-daily-tech',
    questionText:
        'What transport layer protocol does HTTP/3 utilize instead of standard TCP?',
    options: ['QUIC (UDP-based)', 'SCTP', 'TLS Socket Layer', 'IPsec Tunnel'],
    correctOptionIndex: 0,
    explanation:
        'HTTP/3 replaces TCP with QUIC, an encrypted multiplexed transport protocol built on top of UDP that eliminates head-of-line blocking.',
    points: 12,
    difficultyWeight: 1.3,
  ),
  const QuestionModel(
    id: 'tech-q-007',
    challengeId: 'challenge-daily-tech',
    questionText:
        'In Git, what does the command "git cherry-pick <commit-hash>" do?',
    options: [
      'Deletes the specified commit from history permanently',
      'Applies the exact changes from an existing commit onto the current branch',
      'Reverts all unstaged files back to the specified commit',
      'Creates a new remote branch tracking that commit',
    ],
    correctOptionIndex: 1,
    explanation:
        'Git cherry-pick introduces the changes recorded by one or more existing commits and commits them on top of the current HEAD.',
    points: 12,
    difficultyWeight: 1.1,
  ),
  const QuestionModel(
    id: 'tech-q-008',
    challengeId: 'challenge-daily-tech',
    questionText:
        'Which cloud design pattern is specifically used to handle temporary surges in traffic by placing jobs into a durable queue?',
    options: [
      'Queue-Based Load Leveling',
      'Circuit Breaker',
      'Ambassador Pattern',
      'Strangler Fig Pattern',
    ],
    correctOptionIndex: 0,
    explanation:
        'Queue-Based Load Leveling acts as a buffer between a task and a service to smooth out intermittent heavy loads.',
    points: 12,
    difficultyWeight: 1.2,
  ),
  const QuestionModel(
    id: 'tech-q-009',
    challengeId: 'challenge-daily-tech',
    questionText:
        'In JavaScript/TypeScript, what is the output of `typeof NaN`?',
    options: ['"undefined"', '"number"', '"NaN"', '"object"'],
    correctOptionIndex: 1,
    explanation:
        'In JavaScript, NaN ("Not-a-Number") is a numeric data value according to IEEE 754 floating-point specifications, so `typeof NaN` evaluates to `"number"`.',
    points: 12,
    difficultyWeight: 1.1,
  ),
  const QuestionModel(
    id: 'tech-q-010',
    challengeId: 'challenge-daily-tech',
    questionText:
        'What is the worst-case time complexity of QuickSort when choosing a naive pivot (e.g. first element) on an already sorted array?',
    options: ['O(n)', 'O(n log n)', 'O(n²)', 'O(2ⁿ)'],
    correctOptionIndex: 2,
    explanation:
        'When the pivot produces unbalanced partitions of size 0 and n-1, QuickSort degrades to O(n²) comparisons.',
    points: 12,
    difficultyWeight: 1.2,
  ),
];

// Additional questions for 'challenge-net-01' (Networking)
final List<QuestionModel> mockNetworkingQuestions = [
  const QuestionModel(
    id: 'net-q-001',
    challengeId: 'challenge-net-01',
    questionText: 'What is the default port for secure HTTPS web traffic?',
    options: ['80', '443', '8080', '8443'],
    correctOptionIndex: 1,
    explanation:
        'Port 443 is the standard port assigned for HTTPS traffic using TLS/SSL.',
    points: 10,
    difficultyWeight: 1.0,
  ),
  const QuestionModel(
    id: 'net-q-002',
    challengeId: 'challenge-net-01',
    questionText:
        'Which layer of the OSI model does a standard network switch operate at?',
    options: [
      'Layer 1 (Physical)',
      'Layer 2 (Data Link)',
      'Layer 3 (Network)',
      'Layer 4 (Transport)',
    ],
    correctOptionIndex: 1,
    explanation:
        'Standard layer-2 switches use MAC addresses at the Data Link layer to forward frames.',
    points: 10,
    difficultyWeight: 1.0,
  ),
];

final List<QuestionModel> allMockQuestions = [
  ...mockGkQuestions,
  ...mockTechQuestions,
  ...mockNetworkingQuestions,
];

List<QuestionModel> getQuestionsForChallenge(String challengeId) {
  final matching = allMockQuestions
      .where((q) => q.challengeId == challengeId)
      .toList();
  if (matching.isNotEmpty) return matching;

  // Fallback to GK questions if not explicitly populated
  return mockGkQuestions
      .map((q) => q.copyWith(challengeId: challengeId))
      .toList();
}
