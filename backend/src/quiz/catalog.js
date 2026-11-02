const DEFAULT_CATEGORIES = [
  {
    id: 'fun-entertainment',
    name: 'Fun and Entertainment',
    subcategories: [
      'Funny quizzes',
      'Meme quizzes',
      'Comedy trivia',
      'Telugu comedy and movie trivia',
      'Guess the emoji',
      'Guess the movie from emojis',
      'Funny riddles and trick questions',
      'Would You Rather?',
      'This or That?',
      'Guess the character',
      'Guess the dialogue',
    ],
  },
  {
    id: 'entertainment',
    name: 'Entertainment',
    subcategories: [
      'Telugu cinema and Tollywood',
      'Bollywood and Hollywood',
      'Music and songs',
      'Actors and actresses',
      'Web series and television',
      'Celebrity trivia',
    ],
  },
  {
    id: 'brain-games',
    name: 'Brain Games',
    subcategories: [
      'Logical reasoning',
      'Brain teasers',
      'Number puzzles',
      'Pattern recognition',
      'Memory challenges',
      'Mathematical riddles',
    ],
  },
  {
    id: 'general-knowledge',
    name: 'General Knowledge',
    subcategories: [
      'General knowledge',
      'Current affairs',
      'History',
      'Geography',
      'Science',
      'Politics and government',
      'Sports and cricket',
      'English vocabulary',
      'Aptitude',
    ],
  },
  {
    id: 'technology-career',
    name: 'Technology and Career',
    subcategories: [
      'Programming',
      'Python',
      'Java',
      'JavaScript',
      'SQL',
      'DevOps and Cloud',
      'AWS and Azure',
      'Docker and Kubernetes',
      'Linux and Git',
      'Cybersecurity',
      'Artificial intelligence and machine learning',
      'Interview preparation',
    ],
  },
  {
    id: 'lifestyle',
    name: 'Lifestyle',
    subcategories: [
      'Food and travel trivia',
      'Fashion and lifestyle',
      'Hobbies and interests',
      'Entertainment-only personality quizzes',
    ],
  },
];

function publicCategory(category) {
  return {
    id: String(category._id ?? category.id),
    name: category.name,
    subcategories: Array.isArray(category.subcategories)
      ? category.subcategories
      : [],
    active: category.active !== false,
  };
}

module.exports = { DEFAULT_CATEGORIES, publicCategory };
