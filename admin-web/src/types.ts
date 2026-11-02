export interface AdminUser {
  id: string;
  fullName: string;
  username: string;
  email: string;
  role: 'admin';
}

export interface AdminStudent {
  id: string;
  fullName: string;
  username: string;
  email: string;
  createdAt: string | null;
}

export interface Category {
  id: string;
  name: string;
  subcategories: string[];
  active: boolean;
}

export interface Pagination {
  page: number;
  pageSize: number;
  total: number;
  pageCount: number;
}

export interface AdminQuestion {
  id: string;
  categoryId: string;
  subcategory: string;
  questionText: string;
  type: string;
  options: { id: string; text: string }[];
  answerKey: string | boolean | Record<string, string>;
  explanation: string;
  difficulty: 'easy' | 'medium' | 'hard';
  timeLimitSeconds: number | null;
  points: number;
  modes: ('casual' | 'competitive')[];
  image: { url: string; source: string; license: string } | null;
  status: 'draft' | 'pending_review' | 'published' | 'archived';
}

export interface AdminExam {
  id: string;
  title: string;
  description: string;
  categoryId: string;
  scheduledAt: string;
  status: string;
  questionCount: number;
  totalMarks: number;
  attempts: number;
  prize: { description: string } | null;
}

export interface ExamResult {
  rank: number;
  fullName: string;
  username: string;
  score: number;
  correctCount: number;
  answeredCount: number;
  totalQuestions: number;
  submittedAt?: string;
}
