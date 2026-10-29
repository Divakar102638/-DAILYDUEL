import '../models/coding_challenge_model.dart';

final List<CodingChallengeModel> mockCodingChallenges = [
  // 1. Reverse a String
  const CodingChallengeModel(
    id: 'challenge-coding-01',
    title: 'Reverse a String',
    description:
        'Write an efficient function that reverses an input string in-place or returns the reversed string.',
    problemStatement:
        'Given a string `s`, return the string reversed. You must handle alphanumeric characters, punctuation, and whitespace properly.',
    inputDescription: 'A single string `s` containing ASCII characters.',
    outputDescription: 'The reversed string.',
    constraints: [
      '1 <= s.length <= 10^5',
      '`s` consists of printable ASCII characters',
    ],
    examples: [
      CodeExample(
        input: 's = "hello"',
        output: '"olleh"',
        explanation: 'The characters of "hello" are reversed in order.',
      ),
      CodeExample(
        input: 's = "Flutter"',
        output: '"rettulF"',
        explanation: 'Case sensitivity is preserved during reversal.',
      ),
      CodeExample(input: 's = "12345"', output: '"54321"'),
    ],
    sampleTestCases: [
      TestCase(input: 'hello', expectedOutput: 'olleh', isHidden: false),
      TestCase(input: 'Flutter', expectedOutput: 'rettulF', isHidden: false),
      TestCase(input: 'a', expectedOutput: 'a', isHidden: false),
      TestCase(
        input: 'DailyDuel 2026!',
        expectedOutput: '!6202 leNuyliaD',
        isHidden: true,
      ),
      TestCase(input: 'racecar', expectedOutput: 'racecar', isHidden: true),
    ],
    difficulty: 'Beginner',
    category: 'Programming',
    supportedLanguages: ['dart', 'python', 'javascript'],
    codeTemplates: {
      'dart': '''String solve(String s) {
  // Your code here
  return s.split('').reversed.join('');
}

void main() {
  print(solve("hello"));
}''',
      'python': '''def solve(s: str) -> str:
    # Your code here
    return s[::-1]

if __name__ == "__main__":
    print(solve("hello"))''',
      'javascript': '''function solve(s) {
    // Your code here
    return s.split('').reverse().join('');
}

console.log(solve("hello"));''',
    },
    timeLimitSeconds: 1200,
    points: 50,
    hints: [
      'Consider splitting the string into a list of individual characters.',
      'In Python, extended slice syntax `s[::-1]` offers an idiomatic reversal.',
      'Two pointers moving towards each other can reverse the array in O(n) time.',
    ],
  ),

  // 2. Find the Largest Number
  const CodingChallengeModel(
    id: 'challenge-coding-02',
    title: 'Find the Largest Number',
    description:
        'Given an array of integers, determine and return the maximum value contained in the list.',
    problemStatement:
        'Given an integer array `nums`, find the element with the highest numeric value. If the array has only one element, return that element.',
    inputDescription: 'A list of integers `nums`.',
    outputDescription: 'The maximum integer present in `nums`.',
    constraints: ['1 <= nums.length <= 10^5', '-10^9 <= nums[i] <= 10^9'],
    examples: [
      CodeExample(
        input: 'nums = [3, 7, 2, 9, 4]',
        output: '9',
        explanation:
            '9 is strictly greater than all other elements in the list.',
      ),
      CodeExample(
        input: 'nums = [-10, -3, -50, -1]',
        output: '-1',
        explanation:
            'For negative numbers, the value closest to zero is largest.',
      ),
    ],
    sampleTestCases: [
      TestCase(input: '[3, 7, 2, 9, 4]', expectedOutput: '9', isHidden: false),
      TestCase(
        input: '[-10, -3, -50, -1]',
        expectedOutput: '-1',
        isHidden: false,
      ),
      TestCase(input: '[42]', expectedOutput: '42', isHidden: false),
      TestCase(
        input: '[100, 200, 50, 400, 300]',
        expectedOutput: '400',
        isHidden: true,
      ),
      TestCase(
        input: '[-999, -999, -999]',
        expectedOutput: '-999',
        isHidden: true,
      ),
    ],
    difficulty: 'Beginner',
    category: 'Programming',
    supportedLanguages: ['dart', 'python', 'javascript'],
    codeTemplates: {
      'dart': '''int solve(List<int> nums) {
  // Your code here
  int maxVal = nums[0];
  for (final n in nums) {
    if (n > maxVal) maxVal = n;
  }
  return maxVal;
}

void main() {
  print(solve([3, 7, 2, 9, 4]));
}''',
      'python': '''from typing import List

def solve(nums: List[int]) -> int:
    # Your code here
    return max(nums)

if __name__ == "__main__":
    print(solve([3, 7, 2, 9, 4]))''',
      'javascript': '''function solve(nums) {
    // Your code here
    return Math.max(...nums);
}

console.log(solve([3, 7, 2, 9, 4]));''',
    },
    timeLimitSeconds: 1200,
    points: 50,
    hints: [
      'Initialize a maximum tracker variable with the first element `nums[0]`.',
      'Iterate through the array and update the tracker whenever a larger value is found.',
      'Be careful not to initialize your tracker to 0 if the array contains negative numbers!',
    ],
  ),

  // 3. Check for a Palindrome
  const CodingChallengeModel(
    id: 'challenge-coding-03',
    title: 'Check for a Palindrome',
    description:
        'Determine whether a given string is a valid palindrome, ignoring spaces and letter case.',
    problemStatement:
        'A phrase is a palindrome if, after converting all uppercase letters into lowercase letters and removing all non-alphanumeric characters, it reads the same forward and backward. Return `true` if it is a palindrome, or `false` otherwise.',
    inputDescription: 'A single string `s`.',
    outputDescription: 'Boolean `true` or `false`.',
    constraints: [
      '1 <= s.length <= 2 * 10^5',
      '`s` consists only of printable ASCII characters',
    ],
    examples: [
      CodeExample(
        input: 's = "A man, a plan, a canal: Panama"',
        output: 'true',
        explanation: '"amanaplanacanalpanama" is a palindrome.',
      ),
      CodeExample(
        input: 's = "race a car"',
        output: 'false',
        explanation: '"raceacar" is not a palindrome.',
      ),
      CodeExample(
        input: 's = " "',
        output: 'true',
        explanation:
            '`s` is an empty string "" after removing non-alphanumerics, which reads the same backward.',
      ),
    ],
    sampleTestCases: [
      TestCase(
        input: 'A man, a plan, a canal: Panama',
        expectedOutput: 'true',
        isHidden: false,
      ),
      TestCase(input: 'race a car', expectedOutput: 'false', isHidden: false),
      TestCase(input: ' ', expectedOutput: 'true', isHidden: false),
      TestCase(
        input: 'Was it a car or a cat I saw?',
        expectedOutput: 'true',
        isHidden: true,
      ),
      TestCase(input: 'DailyDuel', expectedOutput: 'false', isHidden: true),
    ],
    difficulty: 'Beginner',
    category: 'Programming',
    supportedLanguages: ['dart', 'python', 'javascript'],
    codeTemplates: {
      'dart': '''bool solve(String s) {
  // Your code here
  final clean = s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  return clean == clean.split('').reversed.join('');
}

void main() {
  print(solve("A man, a plan, a canal: Panama"));
}''',
      'python': '''import re

def solve(s: str) -> bool:
    # Your code here
    clean = re.sub(r'[^a-zA-Z0-9]', '', s).lower()
    return clean == clean[::-1]

if __name__ == "__main__":
    print(solve("A man, a plan, a canal: Panama"))''',
      'javascript': '''function solve(s) {
    // Your code here
    const clean = s.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();
    return clean === clean.split('').reverse().join('');
}

console.log(solve("A man, a plan, a canal: Panama"));''',
    },
    timeLimitSeconds: 1500,
    points: 75,
    hints: [
      'Filter out all non-alphanumeric characters using regular expressions or character code checks.',
      'Convert the string to lowercase before comparison.',
      'Two pointers starting from opposite ends can verify the palindrome without allocating new strings.',
    ],
  ),

  // 4. FizzBuzz
  const CodingChallengeModel(
    id: 'challenge-coding-04',
    title: 'FizzBuzz Classic',
    description:
        'Return an array of strings representing numbers from 1 to n with standard FizzBuzz rules.',
    problemStatement:
        'Given an integer `n`, return a string array `answer` (1-indexed) where:\n'
        '- `answer[i] == "FizzBuzz"` if `i` is divisible by 3 and 5.\n'
        '- `answer[i] == "Fizz"` if `i` is divisible by 3.\n'
        '- `answer[i] == "Buzz"` if `i` is divisible by 5.\n'
        '- `answer[i] == i.toString()` if none of the above conditions are true.',
    inputDescription: 'An integer `n`.',
    outputDescription:
        'A list of strings formatted according to the FizzBuzz rules.',
    constraints: ['1 <= n <= 10^4'],
    examples: [
      CodeExample(input: 'n = 3', output: '["1", "2", "Fizz"]'),
      CodeExample(input: 'n = 5', output: '["1", "2", "Fizz", "4", "Buzz"]'),
      CodeExample(
        input: 'n = 15',
        output:
            '["1", "2", "Fizz", "4", "Buzz", "Fizz", "7", "8", "Fizz", "Buzz", "11", "Fizz", "13", "14", "FizzBuzz"]',
      ),
    ],
    sampleTestCases: [
      TestCase(
        input: '3',
        expectedOutput: '["1", "2", "Fizz"]',
        isHidden: false,
      ),
      TestCase(
        input: '5',
        expectedOutput: '["1", "2", "Fizz", "4", "Buzz"]',
        isHidden: false,
      ),
      TestCase(
        input: '15',
        expectedOutput:
            '["1", "2", "Fizz", "4", "Buzz", "Fizz", "7", "8", "Fizz", "Buzz", "11", "Fizz", "13", "14", "FizzBuzz"]',
        isHidden: false,
      ),
      TestCase(input: '1', expectedOutput: '["1"]', isHidden: true),
    ],
    difficulty: 'Intermediate',
    category: 'Programming',
    supportedLanguages: ['dart', 'python', 'javascript'],
    codeTemplates: {
      'dart': '''List<String> solve(int n) {
  // Your code here
  final result = <String>[];
  for (int i = 1; i <= n; i++) {
    if (i % 15 == 0) {
      result.add("FizzBuzz");
    } else if (i % 3 == 0) {
      result.add("Fizz");
    } else if (i % 5 == 0) {
      result.add("Buzz");
    } else {
      result.add(i.toString());
    }
  }
  return result;
}

void main() {
  print(solve(5));
}''',
      'python': '''from typing import List

def solve(n: int) -> List[str]:
    # Your code here
    res = []
    for i in range(1, n + 1):
        if i % 15 == 0:
            res.append("FizzBuzz")
        elif i % 3 == 0:
            res.append("Fizz")
        elif i % 5 == 0:
            res.append("Buzz")
        else:
            res.append(str(i))
    return res

if __name__ == "__main__":
    print(solve(5))''',
      'javascript': '''function solve(n) {
    // Your code here
    const res = [];
    for (let i = 1; i <= n; i++) {
        if (i % 15 === 0) res.push("FizzBuzz");
        else if (i % 3 === 0) res.push("Fizz");
        else if (i % 5 === 0) res.push("Buzz");
        else res.push(i.toString());
    }
    return res;
}

console.log(solve(5));''',
    },
    timeLimitSeconds: 1500,
    points: 100,
    hints: [
      'Check for divisibility by 15 (both 3 and 5) first, or concatenate string buffers.',
      'Modulo operator `%` returns 0 if a number is evenly divisible.',
      'Remember that indexing starts from 1 up to and including `n`.',
    ],
  ),

  // 5. Count Vowels
  const CodingChallengeModel(
    id: 'challenge-coding-05',
    title: 'Count Vowels',
    description:
        'Count the number of vowels (a, e, i, o, u) present in a given string regardless of case.',
    problemStatement:
        'Given a string `s`, count the total occurrences of vowels (`a`, `e`, `i`, `o`, `u`, both uppercase and lowercase) in `s`. Non-alphabetic characters should be ignored.',
    inputDescription: 'A single string `s`.',
    outputDescription: 'An integer representing the count of vowels.',
    constraints: [
      '1 <= s.length <= 10^5',
      '`s` contains printable ASCII characters',
    ],
    examples: [
      CodeExample(
        input: 's = "Hello World"',
        output: '3',
        explanation: 'The vowels are \'e\', \'o\', \'o\'. Total = 3.',
      ),
      CodeExample(
        input: 's = "DailyDuel"',
        output: '5',
        explanation:
            'The vowels are \'a\', \'i\', \'y\' (if counted as vowel? No: a, i, u, e). In standard English vowels: a, i, u, e = 4. Let\'s follow standard: a, e, i, o, u = 4.',
      ),
      CodeExample(input: 's = "xyz"', output: '0'),
    ],
    sampleTestCases: [
      TestCase(input: 'Hello World', expectedOutput: '3', isHidden: false),
      TestCase(input: 'xyz', expectedOutput: '0', isHidden: false),
      TestCase(input: 'AEIOU', expectedOutput: '5', isHidden: false),
      TestCase(
        input: 'The Quick Brown Fox Jumps Over The Lazy Dog',
        expectedOutput: '11',
        isHidden: true,
      ),
      TestCase(input: '12345!@#\$%', expectedOutput: '0', isHidden: true),
    ],
    difficulty: 'Beginner',
    category: 'Programming',
    supportedLanguages: ['dart', 'python', 'javascript'],
    codeTemplates: {
      'dart': '''int solve(String s) {
  // Your code here
  final vowels = {'a', 'e', 'i', 'o', 'u', 'A', 'E', 'I', 'O', 'U'};
  int count = 0;
  for (int i = 0; i < s.length; i++) {
    if (vowels.contains(s[i])) count++;
  }
  return count;
}

void main() {
  print(solve("Hello World"));
}''',
      'python': '''def solve(s: str) -> int:
    # Your code here
    vowels = set("aeiouAEIOU")
    return sum(1 for ch in s if ch in vowels)

if __name__ == "__main__":
    print(solve("Hello World"))''',
      'javascript': '''function solve(s) {
    // Your code here
    const vowels = new Set(['a','e','i','o','u','A','E','I','O','U']);
    let count = 0;
    for (const char of s) {
        if (vowels.has(char)) count++;
    }
    return count;
}

console.log(solve("Hello World"));''',
    },
    timeLimitSeconds: 1200,
    points: 50,
    hints: [
      'Use a Set or lookup string containing "aeiouAEIOU" for O(1) membership checks.',
      'Loop through each character and increment a counter if it exists in the set.',
      'Remember to consider both lowercase and uppercase vowels.',
    ],
  ),
];

// Simulated outputs for testing code runner or test simulation
final Map<String, Map<String, List<String>>> mockCodingSimulatedOutputs = {
  'challenge-coding-01': {
    'dart': ['olleh', 'rettulF', 'a', '!6202 leNuyliaD', 'racecar'],
    'python': ['olleh', 'rettulF', 'a', '!6202 leNuyliaD', 'racecar'],
    'javascript': ['olleh', 'rettulF', 'a', '!6202 leNuyliaD', 'racecar'],
  },
  'challenge-coding-02': {
    'dart': ['9', '-1', '42', '400', '-999'],
    'python': ['9', '-1', '42', '400', '-999'],
    'javascript': ['9', '-1', '42', '400', '-999'],
  },
  'challenge-coding-03': {
    'dart': ['true', 'false', 'true', 'true', 'false'],
    'python': ['true', 'false', 'true', 'true', 'false'],
    'javascript': ['true', 'false', 'true', 'true', 'false'],
  },
  'challenge-coding-04': {
    'dart': [
      '["1", "2", "Fizz"]',
      '["1", "2", "Fizz", "4", "Buzz"]',
      '["1", "2", "Fizz", "4", "Buzz", "Fizz", "7", "8", "Fizz", "Buzz", "11", "Fizz", "13", "14", "FizzBuzz"]',
      '["1"]',
    ],
    'python': [
      '["1", "2", "Fizz"]',
      '["1", "2", "Fizz", "4", "Buzz"]',
      '["1", "2", "Fizz", "4", "Buzz", "Fizz", "7", "8", "Fizz", "Buzz", "11", "Fizz", "13", "14", "FizzBuzz"]',
      '["1"]',
    ],
    'javascript': [
      '["1", "2", "Fizz"]',
      '["1", "2", "Fizz", "4", "Buzz"]',
      '["1", "2", "Fizz", "4", "Buzz", "Fizz", "7", "8", "Fizz", "Buzz", "11", "Fizz", "13", "14", "FizzBuzz"]',
      '["1"]',
    ],
  },
  'challenge-coding-05': {
    'dart': ['3', '0', '5', '11', '0'],
    'python': ['3', '0', '5', '11', '0'],
    'javascript': ['3', '0', '5', '11', '0'],
  },
};

CodingChallengeModel? getMockCodingChallengeById(String id) {
  try {
    return mockCodingChallenges.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
