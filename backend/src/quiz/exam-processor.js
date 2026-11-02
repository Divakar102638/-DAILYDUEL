const { scoreQuestion } = require('./validation');

async function processDueExamResults({
  getCollection,
  now = () => new Date(),
}) {
  const exams = getCollection('exams');
  const attempts = getCollection('exam_attempts');
  const results = getCollection('exam_results');
  const achievements = getCollection('exam_achievements');
  await exams.createIndex(
    { status: 1, scheduledAt: 1 },
    { name: 'exams_status_scheduled_at' },
  );
  await results.createIndex(
    { examId: 1, userId: 1 },
    { unique: true, name: 'exam_results_exam_user_unique' },
  );
  const currentTime = now();
  const dueExams = await exams
    .find({
      status: { $nin: ['results_published', 'archived'] },
      scheduledAt: { $lte: new Date(currentTime.getTime() - 450_000) },
    })
    .toArray();
  let processed = 0;

  for (const exam of dueExams) {
    const examAttempts = await attempts
      .find({ examId: exam._id })
      .toArray();
    for (const attempt of examAttempts) {
      let score = 0;
      let correctCount = 0;
      let answeredCount = 0;
      for (const question of exam.questions) {
        const key = question.questionId.toString();
        const answer = attempt.answers?.[key];
        if (answer !== undefined && answer !== null) answeredCount += 1;
        const evaluated = scoreQuestion(question, answer);
        if (evaluated.correct) {
          correctCount += 1;
          score += question.points;
        }
      }

      await results.updateOne(
        { examId: exam._id, userId: attempt.userId },
        {
          $setOnInsert: {
            examId: exam._id,
            userId: attempt.userId,
            fullName: attempt.fullName,
            username: attempt.username,
            score,
            correctCount,
            answeredCount,
            totalQuestions: exam.questions.length,
            submittedAt: currentTime,
          },
        },
        { upsert: true },
      );
      await attempts.updateOne(
        { _id: attempt._id, status: { $ne: 'scored' } },
        { $set: { status: 'scored', scoredAt: currentTime } },
      );
    }

    const finalResults = await results
      .find({ examId: exam._id })
      .sort({ score: -1, submittedAt: 1, userId: 1 })
      .toArray();
    for (let index = 0; index < finalResults.length; index += 1) {
      const finalResult = finalResults[index];
      const achievementType =
        index === 0 ? 'exam_winner' : index < 3 ? 'exam_podium' : 'exam_participant';
      await results.updateOne(
        { _id: finalResult._id },
        { $set: { rank: index + 1 } },
      );
      await achievements.updateOne(
        {
          examId: exam._id,
          userId: finalResult.userId,
          type: achievementType,
        },
        {
          $setOnInsert: {
            examId: exam._id,
            userId: finalResult.userId,
            type: achievementType,
            awardedAt: currentTime,
          },
        },
        { upsert: true },
      );
    }
    await exams.updateOne(
      { _id: exam._id, resultsPublishedAt: null },
      {
        $set: {
          status: 'results_published',
          resultsPublishedAt: currentTime,
        },
      },
    );
    processed += 1;
  }
  return processed;
}

module.exports = { processDueExamResults };
