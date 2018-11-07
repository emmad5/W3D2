require "singleton"
require "sqlite3"

class QuestionsDatabase < SQLite3::Database 
  include Singleton 
  
  def initialize 
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end 
end

class Users 
  attr_accessor :fname, :lname
  attr_reader :id
  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT 
        *
      FROM 
        users 
      WHERE
        fname = ? AND lname = ?
    SQL
    return nil unless user 
    user.map { |u| Users.new(u) }
  end 
  
  def self.find_by_id(id)
    raise "#{self} not in database" unless @id
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT 
        *
      FROM 
        users 
      WHERE
        id = ? 
    SQL
    return nil unless user 
    Users.new(user.first) 
  end 
  
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM users")
    data.map { |datum| Users.new(datum) }
  end
  
  def initialize(options)
    @fname = options['fname'] 
    @lname = options['lname'] 
    @id = options['id']
  end
  
  def authored_questions
    q = Questions.find_by_author_id(self.id)
    return nil if q.empty?
    Questions.new(q)  
  end
  
  def authored_replies
    Replies.find_by_user_id(self.id)
  end
  
  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
      UPDATE
        users
      SET
        fname = ?, lname = ?
      WHERE
        id = ?
    SQL
  end
  
  def followed_questions 
    QuestionsFollows.followed_questions_for_user_id(self.id)
  end
  
end 

class Questions 
  attr_accessor :title, :body, :author_id
  attr_reader :id 
  
  def self.find_by_id(id)
    raise "#{self} not in database" unless @id
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT 
        *
      FROM 
        questions 
      WHERE
        id = ? 
    SQL
    return nil unless question 
    Questions.new(question.first) 
  end 
  
  def self.find_by_author_id(author_id)
    author = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT 
        *
      FROM 
        questions 
      WHERE
        questions.author_id = ? 
    SQL
    return nil if author.empty? 
    author.map { |a| Questions.new(a) }
  end
  
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map { |datum| Questions.new(datum) }
  end
  
  def initialize(options)
    @title = options['title'] 
    @body = options['body'] 
    @author_id = options['author_id']
    @id = options['id']
  end
  
  def author
    a = QuestionsDatabase.instance.execute(<<-SQL, self.author_id)
      SELECT
        *
      FROM
        users
      WHERE
        users.id = ?  
    SQL
    return nil unless a
    a.first 
  end
  
  def replies
    reply = Replies.find_by_question_id(self.id)
    return nil unless reply
    reply
  end
  
  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id, @id)
      UPDATE
        questions 
      SET
        title = ?, body = ?, author_id = ?
      WHERE
        id = ?
    SQL
  end
  
  def followers 
    QuestionsFollows.followers_for_question_id(self.id)
  end
end 

class Replies 
  attr_accessor :user_id, :questions_id, :parent_id, :body 
  attr_reader :id  
  
  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT 
        *
      FROM 
        replies 
      WHERE
        id = ? 
    SQL
    return nil unless reply 
    Replies.new(reply.first) 
  end 
  
  def self.find_by_user_id(user_id)
    user = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT 
        *
      FROM 
        replies 
      WHERE
        user_id = ? 
    SQL
    return nil unless user 
    user.map { |u| Replies.new(u) }
  end
  
  def self.find_by_question_id(question_id)
    question = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT 
        *
      FROM 
        replies 
      WHERE
        replies.questions_id = ? 
    SQL
    return nil unless question 
    question.map { |q| Replies.new(q) } 
  end
  
  def initialize(options)
    @questions_id = options['questions_id']
    @parent_id = options['parent_id'] 
    @user_id = options['user_id']
    @body = options['body']
    @id = options['id']
  end
  
  def author
    a = QuestionsDatabase.instance.execute(<<-SQL, self.user_id)
      SELECT
        *
      FROM
        users
      WHERE
        users.id = ?  
    SQL
    return nil unless a
    Users.new(a.first) 
  end
  
  def question
    q = QuestionsDatabase.instance.execute(<<-SQL, self.questions_id)
      SELECT
        *
      FROM
        questions
      WHERE
        questions.id = ?  
    SQL
    return nil unless q
    Questions.new(q.first) 
  end
  
  def parent_reply
    pr = QuestionsDatabase.instance.execute(<<-SQL, self.parent_id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.id = ?  
    SQL
    return nil if pr.empty? 
    Replies.new(pr.first) 
  end
  
  def child_replies
    cr = QuestionsDatabase.instance.execute(<<-SQL, self.id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?  
    SQL
    return nil unless cr
    cr.map { |reply| Replies.new(reply)} 
  end
  
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    data.map { |datum| Replies.new(datum) }
  end
  
  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @questions_id, @parent_id, @user_id, @body, @id)
      UPDATE
        replies 
      SET
        questions_id = ?, parent_id = ?, user_id = ?, body = ?
      WHERE
        id = ?
    SQL
  end
end

class QuestionsFollows 
  attr_accessor :questions_id, :user_id 
  
  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM 
        questions JOIN questions_follows ON questions_follows.questions_id = questions.id 
      WHERE
        questions_follows.user_id = ?
    SQL
    return nil if questions.empty?
    questions.map {|question| Questions.new(question)}
  end
  
  def self.followers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM 
        users JOIN questions_follows ON questions_follows.user_id = users.id 
      WHERE
        questions_follows.questions_id = ?
    SQL
    return nil if users.empty?
    users.map {|user| Users.new(user)}
  end 
  
  def initialize(options)
    @questions_id = options['questions_id']
    @user_id = options['user_id']
  end 
end 

class QuestionsLikes 
  def self.find_by_id(id)
    like = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT 
        *
      FROM 
        questions_likes 
      WHERE
        id = ? 
    SQL
    return nil unless like 
    QuestionsLikes.new(like.first) 
  end 
  
  def initialize(options)
    @questions_id = options['questions_id'] 
    @user_id = options['user_id'] 
    @id = options['id']
  end
end 