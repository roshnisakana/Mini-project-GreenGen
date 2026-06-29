from flask import Flask, render_template, request, jsonify, session
from flask_cors import CORS
import pymysql
import bcrypt
import config

app = Flask(__name__)
app.secret_key = config.SECRET_KEY
CORS(app, supports_credentials=True)

# ── Database connection ───────────────────────────────
def get_db():
    return pymysql.connect(
        host        = config.MYSQL_HOST,
        user        = config.MYSQL_USER,
        password    = config.MYSQL_PASSWORD,
        database    = config.MYSQL_DB,
        cursorclass = pymysql.cursors.DictCursor
    )

# ══════════════════════════════════════════
#  SERVE MAIN PAGE
# ══════════════════════════════════════════
@app.route('/')
def index():
    return render_template('index.html')

# ══════════════════════════════════════════
#  REGISTER
# ══════════════════════════════════════════
@app.route('/api/register', methods=['POST'])
def register():
    data      = request.get_json()
    full_name = data.get('full_name', '').strip()
    username  = data.get('username',  '').strip()
    email     = data.get('email',     '').strip()
    password  = data.get('password',  '')
    age_group = data.get('age_group', 'teens')
    role      = data.get('role',      'student')

    if not full_name or not username or not email or not password:
        return jsonify({'success': False, 'message': 'All fields are required.'}), 400
    if len(password) < 6:
        return jsonify({'success': False, 'message': 'Password must be 6+ characters.'}), 400
    if len(username) < 3:
        return jsonify({'success': False, 'message': 'Username must be 3+ characters.'}), 400

    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

    try:
        conn = get_db()
        cur  = conn.cursor()
        cur.execute("""
            INSERT INTO users (full_name, username, email, password, age_group, role)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (full_name, username, email, hashed.decode('utf-8'), age_group, role))
        conn.commit()
        conn.close()
        return jsonify({'success': True, 'message': 'Account created!'})
    except Exception as e:
        if 'Duplicate' in str(e):
            if 'username' in str(e):
                return jsonify({'success': False, 'message': 'Username already taken.'}), 400
            return jsonify({'success': False, 'message': 'Email already registered.'}), 400
        return jsonify({'success': False, 'message': str(e)}), 500

# ══════════════════════════════════════════
#  LOGIN
# ══════════════════════════════════════════
@app.route('/api/login', methods=['POST'])
def login():
    data     = request.get_json()
    email    = data.get('email',    '').strip()
    password = data.get('password', '')

    if not email or not password:
        return jsonify({'success': False, 'message': 'Email and password required.'}), 400

    try:
        conn = get_db()
        cur  = conn.cursor()
        cur.execute("SELECT * FROM users WHERE email=%s OR username=%s", (email, email))
        user = cur.fetchone()
        conn.close()

        if user and bcrypt.checkpw(password.encode('utf-8'), user['password'].encode('utf-8')):
            session['user_id'] = user['id']
            return jsonify({
                'success': True,
                'message': 'Login successful!',
                'user': {
                    'id'          : user['id'],
                    'full_name'   : user['full_name'],
                    'username'    : user['username'],
                    'email'       : user['email'],
                    'age_group'   : user['age_group'],
                    'role'        : user['role'],
                    'points'      : user['points'],
                    'level'       : user['level'],
                    'quizzes_done': user['quizzes_done'],
                    'best_streak' : user['best_streak'],
                }
            })
        else:
            return jsonify({'success': False, 'message': 'Wrong email or password.'}), 401
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

# ══════════════════════════════════════════
#  GET CURRENT SESSION USER  (/api/me)
#  Restores login state on page refresh
# ══════════════════════════════════════════
@app.route('/api/me', methods=['GET'])
def me():
    user_id = session.get('user_id')
    if not user_id:
        return jsonify({'success': False, 'message': 'Not logged in.'})
    try:
        conn = get_db()
        cur  = conn.cursor()
        cur.execute("SELECT * FROM users WHERE id=%s", (user_id,))
        user = cur.fetchone()
        conn.close()
        if user:
            return jsonify({
                'success': True,
                'user': {
                    'id'          : user['id'],
                    'full_name'   : user['full_name'],
                    'username'    : user['username'],
                    'email'       : user['email'],
                    'age_group'   : user['age_group'],
                    'role'        : user['role'],
                    'points'      : user['points'],
                    'level'       : user['level'],
                    'quizzes_done': user['quizzes_done'],
                    'best_streak' : user['best_streak'],
                }
            })
        return jsonify({'success': False, 'message': 'User not found.'})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

# ══════════════════════════════════════════
#  SAVE SCORE  (quiz + all games)
# ══════════════════════════════════════════
@app.route('/api/save_score', methods=['POST'])
def save_score():
    data      = request.get_json()
    user_id   = data.get('user_id')
    topic_key = data.get('topic_key', 'climate')
    game_type = data.get('game_type', 'quiz')
    score     = data.get('score', 0)
    age_group = data.get('age_group', 'teens')

    if not user_id:
        return jsonify({'success': False, 'message': 'User ID missing.'}), 400

    try:
        conn = get_db()
        cur  = conn.cursor()

        # Save score record
        cur.execute("""
            INSERT INTO scores (user_id, topic_key, game_type, score, age_group)
            VALUES (%s, %s, %s, %s, %s)
        """, (user_id, topic_key, game_type, score, age_group))

        # Update user total points and quiz count
        if game_type == 'quiz':
            cur.execute("""
                UPDATE users SET
                    points       = points + %s,
                    quizzes_done = quizzes_done + 1,
                    level        = FLOOR((points + %s) / 200) + 1
                WHERE id = %s
            """, (score, score, user_id))
        else:
            cur.execute("""
                UPDATE users SET
                    points = points + %s,
                    level  = FLOOR((points + %s) / 200) + 1
                WHERE id = %s
            """, (score, score, user_id))

        # Update progress table
        cur.execute("""
            INSERT INTO user_progress (user_id, topic_key, quiz_score, quizzes_completed)
            VALUES (%s, %s, %s, 1)
            ON DUPLICATE KEY UPDATE
                quiz_score         = quiz_score + %s,
                quizzes_completed  = quizzes_completed + 1
        """, (user_id, topic_key, score, score))

        conn.commit()
        conn.close()
        return jsonify({'success': True, 'message': 'Score saved!'})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

# ══════════════════════════════════════════
#  LEADERBOARD  (real users from MySQL)
# ══════════════════════════════════════════
@app.route('/api/leaderboard', methods=['GET'])
def leaderboard():
    try:
        conn = get_db()
        cur  = conn.cursor()
        cur.execute("""
            SELECT username, full_name, points, level, age_group, quizzes_done
            FROM users
            ORDER BY points DESC
            LIMIT 10
        """)
        rows = cur.fetchall()
        conn.close()
        return jsonify({'success': True, 'leaderboard': rows})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

# ══════════════════════════════════════════
#  GET QUESTIONS  (by topic + age group)
# ══════════════════════════════════════════
@app.route('/api/questions', methods=['GET'])
def get_questions():
    topic_key = request.args.get('topic', 'climate')
    age_group = request.args.get('age',   'kids')

    try:
        conn = get_db()
        cur  = conn.cursor()
        cur.execute("""
            SELECT question_text, option_a, option_b, option_c, option_d,
                   correct_option, fun_fact, tip, difficulty
            FROM questions
            WHERE topic_key = %s AND (age_group = %s OR age_group = 'all')
            ORDER BY RAND()
            LIMIT 10
        """, (topic_key, age_group))
        rows = cur.fetchall()
        conn.close()

        questions = [{
            'q'         : r['question_text'],
            'options'   : [r['option_a'], r['option_b'], r['option_c'], r['option_d']],
            'answer'    : ['A','B','C','D'].index(r['correct_option']),
            'fun_fact'  : r['fun_fact']   or '',
            'tip'       : r['tip']        or '',
            'difficulty': r['difficulty'] or 'easy',
        } for r in rows]

        return jsonify({'success': True, 'questions': questions})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

# ══════════════════════════════════════════
#  UPDATE BEST STREAK
# ══════════════════════════════════════════
@app.route('/api/update_streak', methods=['POST'])
def update_streak():
    data   = request.get_json()
    user_id = data.get('user_id')
    streak  = data.get('streak', 0)
    if not user_id:
        return jsonify({'success': False}), 400
    try:
        conn = get_db()
        cur  = conn.cursor()
        cur.execute("""
            UPDATE users SET best_streak = GREATEST(best_streak, %s)
            WHERE id = %s
        """, (streak, user_id))
        conn.commit()
        conn.close()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

# ══════════════════════════════════════════
#  USER PROFILE
# ══════════════════════════════════════════
@app.route('/api/profile', methods=['GET'])
def profile():
    user_id = request.args.get('user_id') or session.get('user_id')
    if not user_id:
        return jsonify({'success': False, 'message': 'Not logged in.'}), 401
    try:
        conn = get_db()
        cur  = conn.cursor()
        cur.execute("SELECT * FROM users WHERE id=%s", (user_id,))
        user = cur.fetchone()
        # Get scores breakdown
        cur.execute("""
            SELECT topic_key, SUM(score) as total, COUNT(*) as games
            FROM scores WHERE user_id=%s GROUP BY topic_key
        """, (user_id,))
        topic_scores = cur.fetchall()
        conn.close()
        if user:
            return jsonify({
                'success'     : True,
                'user'        : {k: user[k] for k in user if k != 'password'},
                'topic_scores': topic_scores
            })
        return jsonify({'success': False, 'message': 'User not found.'})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

# ══════════════════════════════════════════
#  LOGOUT
# ══════════════════════════════════════════
@app.route('/api/logout', methods=['POST'])
def logout():
    session.clear()
    return jsonify({'success': True, 'message': 'Logged out.'})

# ══════════════════════════════════════════
#  RUN
# ══════════════════════════════════════════
if __name__ == '__main__':
    app.run(debug=True)
