-- ╔══════════════════════════════════════════════════════════════════╗
-- ║          GreenGen — Complete MySQL Database Setup               ║
-- ║  Run this file ONCE to create every table and seed all data.    ║
-- ║  Command:  mysql -u root -p < greengen_database.sql             ║
-- ║  Or paste block-by-block into MySQL Workbench.                  ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ─────────────────────────────────────────────────────────────────
--  1.  DATABASE
-- ─────────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS greengen
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE greengen;


-- ─────────────────────────────────────────────────────────────────
--  2.  USERS
--      Stores every registered account.
--      Points / level / quizzes_done update automatically via
--      the save_score route in app.py.
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id            INT           AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(100)  NOT NULL,
    username      VARCHAR(60)   NOT NULL,
    email         VARCHAR(150)  NOT NULL,
    password      VARCHAR(255)  NOT NULL,          -- bcrypt hash
    age_group     ENUM('kids','teens','adults')     DEFAULT 'teens',
    role          ENUM('student','teacher','parent',
                       'guardian','enthusiast','researcher')
                                                   DEFAULT 'student',
    avatar        VARCHAR(10)                       DEFAULT '🌿',
    points        INT                               DEFAULT 0,
    level         INT                               DEFAULT 1,
    quizzes_done  INT                               DEFAULT 0,
    best_streak   INT                               DEFAULT 0,
    current_streak INT                              DEFAULT 0,
    last_active   DATE                              DEFAULT (CURDATE()),
    created_at    DATETIME                          DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME                          DEFAULT CURRENT_TIMESTAMP
                                                   ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_username (username),
    UNIQUE KEY uq_email    (email)
);


-- ─────────────────────────────────────────────────────────────────
--  3.  SCORES
--      One row per quiz or game session completed.
--      game_type: 'quiz' | 'memory' | 'waste_sort' | 'scramble' |
--                 'myth' | 'river' | 'carbon' | 'food_chain' | 'power'
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS scores (
    id            INT           AUTO_INCREMENT PRIMARY KEY,
    user_id       INT           NOT NULL,
    topic_key     VARCHAR(30)   NOT NULL,           -- climate|waste|energy|bio|pollution|all
    game_type     VARCHAR(30)   DEFAULT 'quiz',
    score         INT           DEFAULT 0,
    correct_count INT           DEFAULT 0,
    total_count   INT           DEFAULT 0,
    streak        INT           DEFAULT 0,
    age_group     VARCHAR(20)   DEFAULT 'teens',
    played_at     DATETIME      DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user    (user_id),
    INDEX idx_topic   (topic_key),
    INDEX idx_game    (game_type)
);


-- ─────────────────────────────────────────────────────────────────
--  4.  QUESTIONS
--      Quiz questions for all 5 topics × 3 age groups.
--      age_group = 'all'  → shown to every age group.
--      correct_option is 'A','B','C', or 'D'.
--      option_d is NULL for 3-option (kids) questions.
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS questions (
    id              INT           AUTO_INCREMENT PRIMARY KEY,
    topic_key       VARCHAR(30)   NOT NULL,
    age_group       ENUM('kids','teens','adults','all') DEFAULT 'all',
    question_text   TEXT          NOT NULL,
    option_a        VARCHAR(350)  NOT NULL,
    option_b        VARCHAR(350)  NOT NULL,
    option_c        VARCHAR(350)  NOT NULL,
    option_d        VARCHAR(350)  DEFAULT NULL,
    correct_option  ENUM('A','B','C','D') NOT NULL,
    fun_fact        TEXT,
    tip             VARCHAR(300),
    difficulty      ENUM('easy','medium','hard') DEFAULT 'medium',
    active          TINYINT(1)    DEFAULT 1,
    created_at      DATETIME      DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_topic_age (topic_key, age_group)
);


-- ─────────────────────────────────────────────────────────────────
--  5.  BADGES  (definition catalogue)
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS badges (
    id            INT           AUTO_INCREMENT PRIMARY KEY,
    emoji         VARCHAR(10)   NOT NULL,
    name          VARCHAR(100)  NOT NULL,
    description   VARCHAR(255)  NOT NULL,
    badge_type    ENUM('permanent','daily','special') DEFAULT 'permanent',
    unlock_rule   VARCHAR(100),                    -- used by app.py to award
    UNIQUE KEY uq_name (name)
);


-- ─────────────────────────────────────────────────────────────────
--  6.  USER BADGES  (many-to-many)
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_badges (
    id            INT           AUTO_INCREMENT PRIMARY KEY,
    user_id       INT           NOT NULL,
    badge_id      INT           NOT NULL,
    earned_at     DATETIME      DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_user_badge (user_id, badge_id),
    FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE,
    FOREIGN KEY (badge_id) REFERENCES badges(id) ON DELETE CASCADE
);


-- ─────────────────────────────────────────────────────────────────
--  7.  FUN FACTS
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fun_facts (
    id            INT           AUTO_INCREMENT PRIMARY KEY,
    topic_key     VARCHAR(30)   NOT NULL,
    emoji         VARCHAR(10),
    title         VARCHAR(150)  NOT NULL,
    body          TEXT          NOT NULL,
    active        TINYINT(1)    DEFAULT 1,
    INDEX idx_topic (topic_key)
);


-- ─────────────────────────────────────────────────────────────────
--  8.  WASTE SORT ITEMS  (for the Waste Sorter game)
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS waste_items (
    id            INT           AUTO_INCREMENT PRIMARY KEY,
    label         VARCHAR(80)   NOT NULL,
    correct_bin   ENUM('recycle','compost','landfill','hazard') NOT NULL,
    difficulty    ENUM('easy','hard') DEFAULT 'easy'
);


-- ─────────────────────────────────────────────────────────────────
--  9.  SCRAMBLE WORDS  (for Word Scramble / Kids Word game)
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS scramble_words (
    id            INT           AUTO_INCREMENT PRIMARY KEY,
    word          VARCHAR(30)   NOT NULL,
    hint          VARCHAR(150)  NOT NULL,
    emoji         VARCHAR(10),
    age_group     ENUM('kids','teens','adults','all') DEFAULT 'all'
);


-- ─────────────────────────────────────────────────────────────────
--  10.  MYTH BUSTER STATEMENTS
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS myth_statements (
    id            INT           AUTO_INCREMENT PRIMARY KEY,
    statement     TEXT          NOT NULL,
    answer        ENUM('myth','fact') NOT NULL,
    explanation   TEXT          NOT NULL,
    active        TINYINT(1)    DEFAULT 1
);


-- ─────────────────────────────────────────────────────────────────
--  11.  DAILY BADGE CLAIMS
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS daily_badge_claims (
    id            INT           AUTO_INCREMENT PRIMARY KEY,
    user_id       INT           NOT NULL,
    badge_id      INT           NOT NULL,
    claim_date    DATE          NOT NULL DEFAULT (CURDATE()),
    bonus_pts     INT           DEFAULT 50,
    UNIQUE KEY uq_daily (user_id, claim_date),
    FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE,
    FOREIGN KEY (badge_id) REFERENCES badges(id) ON DELETE CASCADE
);


-- ═════════════════════════════════════════════════════════════════
--  SEED DATA
-- ═════════════════════════════════════════════════════════════════


-- ─────────────────────────────────────────────────────────────────
--  BADGES SEED
-- ─────────────────────────────────────────────────────────────────
INSERT IGNORE INTO badges (emoji, name, description, badge_type, unlock_rule) VALUES
('🏆','Perfect Score',    'Get 100% on any quiz',                   'permanent','quiz_perfect'),
('🔥','Hot Streak',       'Answer 3+ questions correctly in a row',  'permanent','streak_3'),
('⭐','High Scorer',      'Score 100+ points in one quiz',           'permanent','score_100'),
('🌿','Eco Learner',      'Complete your very first quiz',           'permanent','first_quiz'),
('🎓','Veteran',          'Complete 5 quizzes',                      'permanent','quiz_5'),
('🧠','Memory Master',    'Match all pairs in Eco Memory',           'permanent','memory_win'),
('♻️','Sort Expert',     'Sort all waste items correctly',           'permanent','sort_perfect'),
('🔤','Word Wizard',      'Solve 5 word scrambles',                  'permanent','scramble_5'),
('🦋','Biodiversity Buff','Complete a Biodiversity quiz',            'permanent','topic_bio'),
('☀️','Energy Expert',   'Complete an Energy quiz',                 'permanent','topic_energy'),
('🌡️','Climate Champion','Complete a Climate quiz',                  'permanent','topic_climate'),
('💨','Pollution Patrol', 'Complete a Pollution quiz',               'permanent','topic_pollution'),
('🌱','Sprout',           'Register and log in for the first time', 'permanent','register'),
('🌍','Earth Guardian',   'Earn 10 or more badges',                  'permanent','badges_10'),
('💡','Fact Fanatic',     'Browse the Fun Facts page',               'permanent','facts_visited'),
('🎮','Game Master',      'Play all 8 mini games',                   'permanent','all_games'),
-- Daily badges (rotate by day-of-year in Python)
('🌟','Star of the Day',  'Be active today!',                        'daily', NULL),
('🌊','Wave Maker',       'Make waves for the planet!',              'daily', NULL),
('☀️','Sun Champion',    'Shine bright today!',                     'daily', NULL),
('🐝','Busy Bee',         'Pollinate the knowledge!',                'daily', NULL),
('🌈','Rainbow Hero',     'Spread colour and hope!',                 'daily', NULL),
('🐋','Ocean Guardian',   'Protect the seas!',                       'daily', NULL),
('⚡','Energy Ninja',     'Master renewable energy!',                'daily', NULL),
('🧬','Bio Wizard',       'Understand biodiversity!',                'daily', NULL),
('🌏','Globe Trotter',    'Explore all eco topics!',                 'daily', NULL),
('🦭','Ice Keeper',       'Fight for the Arctic!',                   'daily', NULL);


-- ─────────────────────────────────────────────────────────────────
--  QUESTIONS — KIDS (3 options, age_group='kids')
-- ─────────────────────────────────────────────────────────────────
INSERT INTO questions (topic_key,age_group,question_text,option_a,option_b,option_c,option_d,correct_option,fun_fact,tip,difficulty) VALUES

-- Climate (Kids)
('climate','kids','What do we call it when gases trap the sun\'s heat around Earth?','Greenhouse Effect','Rainbow Effect','Cloud Effect',NULL,'A','CO₂ and other gases act like a blanket, keeping Earth warm. Too much trapping causes dangerous warming!','Think of a greenhouse where plants stay warm! 🌿','easy'),
('climate','kids','Which of these helps REDUCE climate change?','Burning coal','Planting trees','Driving everywhere',NULL,'B','Trees absorb CO₂ from the air as they grow, acting as natural carbon stores!','Trees are nature\'s air cleaners! 🌳','easy'),
('climate','kids','What is the main gas causing Earth to warm up?','Carbon Dioxide (CO₂)','Oxygen (O₂)','Nitrogen (N₂)',NULL,'A','CO₂ levels have risen over 50% since 1750, mostly from burning coal and oil.','It\'s what makes fizzy drinks bubbly! 🥤','easy'),
('climate','kids','What melts when Earth gets too warm?','Rocks','Ice and glaciers','Deserts',NULL,'B','Melting ice raises sea levels, which can flood coastal towns and islands!','Think about ice in your drink on a hot day! 🧊','easy'),
('climate','kids','Which activity releases CO₂ into the air?','Planting a tree','Burning coal','Swimming',NULL,'B','Burning coal for energy releases CO₂ stored underground for millions of years.','Look for smoke from chimneys! 🏭','easy'),

-- Waste (Kids)
('waste','kids','Which bin should a banana peel go in?','Recycle','Compost','Landfill',NULL,'B','Banana peels are organic — they rot and turn into healthy soil for plants!','It was once alive and returns to earth! 🍌','easy'),
('waste','kids','What does the ♻️ symbol mean?','Throw it away','It can be recycled','It is broken',NULL,'B','Materials like paper, glass and plastic can be turned into brand new products!','Look for the three arrows going in a circle! ♻️','easy'),
('waste','kids','How long does a plastic bottle take to break down?','1 year','10 years','450 years',NULL,'C','A single plastic bottle can outlast 6 human lifetimes — that\'s why we must reduce plastic!','That\'s longer than your great-great grandparents lived! 🧴','easy'),
('waste','kids','Which of these is NOT recyclable in most bins?','Glass bottle','Crisp packet','Newspaper',NULL,'B','Crisp packets are made from mixed materials that most recycling centres can\'t separate.','When in doubt, check your local recycling guide! ♻️','easy'),
('waste','kids','What is composting?','Burning rubbish','Turning food scraps into soil','Putting things in a box',NULL,'B','Compost enriches soil and helps plants grow — it turns waste into something useful!','Worms love compost! 🐛','easy'),

-- Energy (Kids)
('energy','kids','Which energy comes from the sun?','Coal Power','Solar Power','Car Engine',NULL,'B','Solar panels convert sunlight into clean electricity with zero pollution or smoke!','The sun gives us free energy every day! ☀️','easy'),
('energy','kids','What do wind turbines make?','Rain','Electricity','Food',NULL,'B','One large wind turbine can power over 500 homes for an entire year!','Think of a modern windmill! 💨','easy'),
('energy','kids','Which fuel is renewable (never runs out)?','Coal','Oil','Sunlight',NULL,'C','The sun has enough energy to last another 5 billion years — truly renewable!','Renewable means nature makes more of it! 🌱','easy'),
('energy','kids','How can you save energy at home?','Leave lights on all day','Turn off lights when you leave','Use more hot water',NULL,'B','If everyone switched off lights, we could power millions of homes with the saved energy!','Small actions add up to big changes! 💡','easy'),
('energy','kids','What colour are solar panels usually?','White','Green','Dark blue or black',NULL,'C','Dark colours absorb more sunlight, making dark-coloured panels more efficient at capturing solar energy.','Think about why dark clothes feel hotter in the sun! ☀️','easy'),

-- Biodiversity (Kids)
('bio','kids','What do bees help plants to make?','Grow taller','Seeds and fruit','Drink water',NULL,'B','Without bees pollinating flowers, we would lose apples, strawberries, almonds and hundreds of other foods!','Bees are nature\'s superheroes! 🐝','easy'),
('bio','kids','What is the Amazon Rainforest called?','The lungs of the Earth','The heart of the Earth','The brain of the Earth',NULL,'A','The Amazon produces around 20% of Earth\'s oxygen and is home to millions of species!','Lungs help you breathe — forests help Earth breathe! 🌳','easy'),
('bio','kids','How many species of animals and plants are on Earth?','About 100','About 10,000','About 8 million',NULL,'C','Scientists have discovered 1.5 million species but estimate 8 million exist — most still unknown!','Our planet is bursting with life! 🦋','easy'),
('bio','kids','What do we call all the different living things in one place?','A zoo','An ecosystem','A museum',NULL,'B','An ecosystem includes all plants, animals, water, soil and air — they all depend on each other!','Your garden is a tiny ecosystem! 🌻','easy'),
('bio','kids','Why are coral reefs important?','They look pretty','They are home to 25% of all sea life','They make the sea blue',NULL,'B','Coral reefs cover only 0.1% of the ocean floor but support a quarter of all marine species!','They\'re called the rainforests of the sea! 🐠','easy'),

-- Pollution (Kids)
('pollution','kids','What happens when too much rubbish goes into the ocean?','Fish eat it and get sick','Oceans become cleaner','More fish appear',NULL,'A','Over 8 million tonnes of plastic enter oceans each year — fish, turtles and seabirds mistake it for food!','Litter belongs in the bin, not the sea! 🌊','easy'),
('pollution','kids','Which travel is best for the environment?','Airplane','Car alone','Train',NULL,'C','Trains produce up to 75% fewer emissions per passenger than aeroplanes — fast AND eco-friendly!','Trains are the greenest way to travel long distances! 🚆','easy'),
('pollution','kids','Which type of car produces zero exhaust fumes?','Petrol car','Diesel car','Electric car',NULL,'C','Electric cars produce no exhaust emissions, especially clean when charged from renewable energy!','Electric cars are quiet AND clean! ⚡','easy'),
('pollution','kids','What causes smog over big cities?','Too much rain','Gases from cars and factories','Clouds coming down',NULL,'B','Smog forms when vehicle exhaust reacts with sunlight, causing breathing problems.','You can often see brown haze from above the city! ✈️','easy'),
('pollution','kids','What simple thing can you do to reduce plastic pollution?','Buy more plastic bags','Use a reusable water bottle','Throw plastic in the ocean',NULL,'B','One reusable bottle saves hundreds of plastic bottles per year from ending up in landfill!','Small swaps make a big difference! 🌿','easy');


-- ─────────────────────────────────────────────────────────────────
--  QUESTIONS — TEENS (4 options, age_group='teens')
-- ─────────────────────────────────────────────────────────────────
INSERT INTO questions (topic_key,age_group,question_text,option_a,option_b,option_c,option_d,correct_option,fun_fact,tip,difficulty) VALUES

-- Climate (Teens)
('climate','teens','What gas is the primary driver of the greenhouse effect?','Carbon Dioxide (CO₂)','Oxygen (O₂)','Nitrogen (N₂)','Helium (He)','A','CO₂ levels have risen over 50% since 1750 due to burning fossil fuels, trapping heat like a car window.','Think car exhaust or factory chimneys! 🚗','medium'),
('climate','teens','The Paris Agreement aims to limit warming to below…?','4°C','1.5–2°C','3°C','5°C','B','196 countries signed the 2015 Paris Agreement. Even 0.5°C extra causes far greater damage globally.','A small number with a huge impact! 🌐','medium'),
('climate','teens','What percentage of global greenhouse gas emissions does energy production cause?','About 25%','About 50%','About 73%','About 90%','C','Energy production from coal, oil and gas for electricity and heat generates 73% of all GHG emissions.','Think about everything powered by electricity! ⚡','medium'),
('climate','teens','What is a "carbon footprint"?','The mark fossil fuels leave on roads','Total greenhouse gas emissions caused by an activity','Carbon stored underground by trees','CO₂ absorbed by footpaths in cities','B','The average person produces about 4 tonnes of CO₂ per year — aviation and diet have the biggest impact.','Every purchase, journey and meal adds to it! ✈️','medium'),
('climate','teens','Which sector is the largest single source of methane emissions globally?','Oil and gas','Coal mining','Agriculture and livestock','Landfills','C','Cows and rice farming produce huge amounts of methane, which is 80× more potent than CO₂ over 20 years.','Methane from livestock is a huge hidden climate driver! 🐄','medium'),

-- Waste (Teens)
('waste','teens','How long does a plastic bottle take to decompose in a landfill?','10 years','100 years','450 years','5 years','C','A single plastic bottle can outlast 6 human generations. Choosing reusable saves hundreds per year.','Way longer than you think! 🧴','medium'),
('waste','teens','What percentage of all plastic ever made has been recycled?','About 50%','About 30%','About 9%','About 70%','C','Of 9.2 billion tonnes produced since 1950, 9% was recycled, 12% incinerated, 79% in landfills or nature.','The number is shockingly small! 😮','medium'),
('waste','teens','What is "fast fashion" and its environmental impact?','Clothes that dry quickly','Cheap clothing with massive waste and water use','Celebrity-branded clothing lines','Eco-certified garment brands','B','The fashion industry produces 10% of global CO₂ emissions and uses 79 trillion litres of water annually.','Your wardrobe has an eco footprint! 👗','medium'),
('waste','teens','What is "upcycling"?','Recycling on a bicycle','Turning waste into something of higher value','Sending waste to be recycled abroad','Incineration of household waste','B','Upcycling creates new products of higher quality from discarded materials — like turning tyres into furniture!','Upcycling is more energy-efficient than recycling! ♻️','medium'),
('waste','teens','How much food is wasted globally every year?','100 million tonnes','500 million tonnes','1.3 billion tonnes','5 billion tonnes','C','1.3 billion tonnes of food is wasted annually — enough to feed 3 billion people — generating 8–10% of GHGs.','It could feed billions of people! 🌾','medium'),

-- Energy (Teens)
('energy','teens','Which renewable source generates electricity from moving water?','Solar','Wind','Hydropower','Geothermal','C','Hydropower supplies about 16% of global electricity with no CO₂ emissions during operation.','Think dams and rushing rivers! 🌊','medium'),
('energy','teens','Which country produces the most solar energy?','USA','Germany','China','India','C','China accounts for over 30% of global solar capacity and adds more panels each year than any other nation.','World\'s most populous country! ☀️','medium'),
('energy','teens','How much cheaper has solar energy become in the last 40 years?','50% cheaper','80% cheaper','99% cheaper','30% cheaper','C','Solar PV costs have dropped 99% since 1980 — it\'s now the cheapest electricity source in history.','Technology improvements are incredible! 📉','medium'),
('energy','teens','What is the main challenge with solar and wind energy?','They produce too much electricity','They are intermittent — don\'t always produce when demand is high','They are more expensive than coal','They damage wildlife too much','B','The "duck curve" problem: solar peaks at midday but demand peaks in the evening — storage is the solution.','Battery storage is the key! 🔋','medium'),
('energy','teens','What does a wind turbine\'s capacity factor of 35% mean?','It only uses 35% of its materials','It produces 35% of its maximum rated power on average','35% of its power is wasted','It lasts 35% longer than a coal plant','B','A capacity factor of 35% means a turbine on average produces 35% of what it could if running flat out.','Wind doesn\'t blow at full speed all the time! 💨','medium'),

-- Biodiversity (Teens)
('bio','teens','Which ecosystem is called the "lungs of the Earth"?','Sahara Desert','Amazon Rainforest','Arctic Tundra','Pacific Ocean','B','The Amazon produces ~20% of Earth\'s oxygen and hosts 10% of all species on the planet.','It\'s the largest tropical rainforest! 🌳','medium'),
('bio','teens','How many species go extinct every day due to human activity?','1–5','10–20','70–150','500+','C','Scientists estimate 70–150 species vanish every day — 1,000× faster than the natural background rate.','This is happening right now, every day! 😢','medium'),
('bio','teens','What is a "keystone species"?','The largest predator in an ecosystem','A species whose removal causes dramatic ecosystem collapse','The most endangered species on Earth','Any species found across multiple continents','B','Wolves in Yellowstone are keystone species — their return changed river courses by altering elk grazing!','Losing one species can cascade through an entire ecosystem! 🐺','medium'),
('bio','teens','What percentage of Earth\'s species live in the ocean?','About 25%','About 50%','About 80%','About 10%','C','Oceans cover 71% of Earth but host about 80% of life — most of it still undiscovered by scientists!','The ocean is bigger and more alive than you imagine! 🌊','medium'),
('bio','teens','Why does biodiversity matter for humans?','It makes nature look nice','It provides medicines, food, clean water and climate stability','It reduces the need for farming','It creates tourism income','B','70% of cancer drugs are natural or nature-derived. Pollination services are worth $577 billion per year.','Nature is our life support system! 🌿','medium'),

-- Pollution (Teens)
('pollution','teens','Which ocean has the largest plastic garbage patch?','Atlantic','Indian','Pacific','Arctic','C','The Great Pacific Garbage Patch is twice the size of Texas, containing 80,000+ metric tonnes of plastic.','It\'s in the world\'s biggest ocean! 🐋','medium'),
('pollution','teens','What is "ocean acidification"?','The ocean becoming more salty','CO₂ dissolving in seawater to form carbonic acid','Oil spills lowering the ocean pH','Plastic pollution turning the sea acidic','B','Oceans absorb 30% of human CO₂, making them 26% more acidic since industrialisation — dissolving shells.','More acid = dissolved shells for corals and oysters! 🐚','medium'),
('pollution','teens','Air pollution kills approximately how many people per year?','70,000','700,000','7 million','70 million','C','WHO estimates 7 million premature deaths annually from air pollution — more than AIDS, TB and malaria.','Most people live in areas exceeding WHO air quality guidelines! 🌫️','medium'),
('pollution','teens','What are microplastics?','Tiny robots for cleaning water','Plastic particles smaller than 5mm found everywhere','Biodegradable alternatives to plastic','Mini recycling machines','B','Microplastics are found in human blood, breast milk, placentas, Arctic snow and the deepest ocean trenches.','They are literally everywhere now! 😱','medium'),
('pollution','teens','What causes "dead zones" in the ocean?','Too much sunlight','Oil spills from tankers','Nutrient runoff from agriculture causing algal blooms','Plastic pollution blocking oxygen','C','Agricultural nitrogen and phosphorus fuel algal blooms that deplete oxygen, killing most marine life.','There are 700+ dead zones globally! 🌊','medium');


-- ─────────────────────────────────────────────────────────────────
--  QUESTIONS — ADULTS (4 options, age_group='adults')
-- ─────────────────────────────────────────────────────────────────
INSERT INTO questions (topic_key,age_group,question_text,option_a,option_b,option_c,option_d,correct_option,fun_fact,tip,difficulty) VALUES

-- Climate (Adults)
('climate','adults','Current atmospheric CO₂ concentration (2024) is approximately:','280 ppm (pre-industrial)','350 ppm (1990 baseline)','~420 ppm','500 ppm (projected tipping point)','C','We hit 421 ppm in 2023 — highest in 3 million years. Pre-industrial was 280 ppm, a 50% increase.','We passed 400 ppm in 2013 and it\'s still rising! 📈','hard'),
('climate','adults','What does "net-zero by 2050" actually mean?','Zero CO₂ emissions globally','Balancing emitted CO₂ with carbon removed from atmosphere','100% renewable electricity worldwide','Ending all fossil fuel extraction','B','Net-zero means residual hard-to-abate emissions are offset by equivalent carbon dioxide removal (CDR).','Residual aviation and steel emissions still exist — they must be offset! ⚗️','hard'),
('climate','adults','What is "radiative forcing" in climate science?','Solar panel output efficiency','Energy imbalance in Earth\'s budget from GHGs, measured in W/m²','Rate of Arctic ice melt annually','Carbon absorption speed of forests','B','Current total anthropogenic radiative forcing is ~3 W/m² — Earth absorbs that much more than it radiates.','A forcing of +1 W/m² sounds tiny but drives enormous change over decades! 🌡️','hard'),
('climate','adults','What is the "social cost of carbon" used in US EPA policy (2023)?','$12 per tonne CO₂','$50 per tonne CO₂','$190 per tonne CO₂','$500 per tonne CO₂','C','The US EPA set the social cost of carbon at $190/tonne in 2023. Many economists argue it should be $400–$1800.','This figure drives major regulatory decisions and cost-benefit analyses! 💰','hard'),
('climate','adults','At what global temperature rise might the Amazon rainforest reach a critical tipping point?','1.5°C','2°C','3–4°C','5°C','C','At 3–4°C warming, the Amazon could convert to savanna, releasing approximately 150 gigatonnes of CO₂.','Tipping points are self-reinforcing — once crossed, very hard to reverse! 🌳','hard'),
('climate', 'all',
'Which human activity releases the most greenhouse gases globally?',
'Agriculture', 'Burning fossil fuels', 'Deforestation', 'Industrial waste',
'B', 'Burning coal, oil and gas accounts for over 75 percent of global greenhouse gas emissions.', 'Think cars, factories and power plants! 🏭', 'medium'),
('climate','all','Which city action helps lower heat during climate change?','Planting more trees','Removing parks','Using only dark roads','Keeping engines running','A','Trees give shade and cool city air, helping people stay safer during heatwaves.','Cooler streets protect people and save energy.','medium'),
('climate','all','What is one climate benefit of using public transport?','It carries many people with less fuel per person','It makes cars use more fuel','It stops all weather changes','It only works at night','A','Shared travel can lower emissions per person compared with many separate car trips.','One bus can replace many cars on the road.','medium'),
-- Waste (Adults)
('waste','adults','What is the "circular economy" concept?','Reducing consumer spending on goods','Designing out waste so products are reused in closed loops','Circular shipping routes for goods','Government recycling targets','B','The circular economy contrasts with "take-make-dispose". It could reduce global CO₂ by 9.3 Gt/year by 2050.','Ellen MacArthur Foundation pioneered this framework! ♻️','hard'),
('waste','adults','Global landfill methane is approximately how much more potent than CO₂ over 20 years?','12×','34×','80×','200×','C','Methane is 80× more potent than CO₂ over 20 years, making organic waste in landfills a major climate driver.','Short-term methane reduction has fast climate benefits! 🗑️','hard'),
('waste','adults','What does "Extended Producer Responsibility" (EPR) mean?','Consumers pay all disposal costs','Manufacturers manage end-of-life of their products by law','Extended warranty required by regulation','Exporters fund recycling in destination countries','B','The EU\'s Single-Use Plastics Directive (2021) is a landmark EPR law — producers fund collection infrastructure.','EPR shifts waste burden from taxpayers to product designers! 🏭','hard'),
('waste','adults','What is "industrial symbiosis"?','Competing factories sharing resources inefficiently','One company\'s waste becoming another\'s raw material','A certification scheme for zero-waste manufacturers','Government-mandated waste trading between regions','B','The Kalundborg Symbiosis in Denmark — 12 companies exchanging 30+ waste streams — saves 275,000 tonnes CO₂/year.','Pioneered in Denmark in the 1970s — now replicated worldwide! 🌍','hard'),
('waste','adults','E-waste generated globally in 2019 was equivalent to:','35 cruise ships','150 cruise ships','350 cruise ships','1,000 cruise ships','C','53.6 million metric tonnes of e-waste were generated in 2019 — only 17% was formally recycled.','E-waste contains $57 billion of recoverable materials annually! 💻','hard'),

-- Energy (Adults)
('energy','adults','What is the "duck curve" problem in grid management?','Energy waste from duck farms','Mismatch between solar production peaks and evening demand peaks','Inefficiency of curved solar panel arrays','Wind patterns reducing turbine output in coastal areas','B','Solar overproduces at midday but demand peaks at evening, requiring rapid fossil-fuel backup or storage.','Grid storage is the key solution to the duck curve! ⚡','hard'),
('energy','adults','Green hydrogen is produced by:','Steam reforming of natural gas','Electrolysis powered by renewable electricity','Nuclear-powered water splitting','Coal gasification with carbon capture','B','Electrolysis splits water using renewable electricity — zero-emission hydrogen for hard-to-decarbonise sectors.','Green H₂ currently costs $4–8/kg vs $1–2/kg for grey hydrogen from gas! ⚗️','hard'),
('energy','adults','What share of global electricity came from renewables in 2023?','About 15%','About 30%','About 50%','About 70%','B','Renewables provided ~30% of global electricity in 2023 (IEA), with solar and wind dominating new additions.','Electricity is only 20% of total energy — heat and transport are harder to decarbonise! ⚡','hard'),
('energy','adults','What is the EROI (Energy Return on Investment) of modern solar PV?','Less than 1:1','About 3:1','About 10–30:1','About 100:1','C','Modern solar panels have an EROI of 10–30:1, producing 10–30× more energy than used in manufacturing.','Break-even time for modern panels is just 1–3 years! ☀️','hard'),
('energy','adults','Small Modular Reactors (SMRs) in nuclear energy aim to:','Replace all coal plants by 2030','Reduce nuclear capital costs and allow factory manufacturing','Generate power from nuclear fusion','Eliminate nuclear waste completely','B','SMRs are factory-built modular units (under 300 MW) aiming to cut costs vs large conventional nuclear plants.','First commercial SMRs expected to operate in the late 2020s! ⚛️','hard'),

-- Biodiversity (Adults)
('bio','adults','What does the Kunming-Montreal Global Biodiversity Framework (2022) target?','100% marine protection by 2050','Protecting 30% of land and oceans by 2030','Ending deforestation by 2025','Restoring 1 trillion trees by 2030','B','The "30×30" target from COP15 — currently only ~17% of land and 8% of ocean are formally protected.','Also known as the Paris Agreement for nature! 🌿','hard'),
('bio','adults','What is the "planetary boundaries" framework?','International space exploration limits','Nine Earth system processes with scientifically defined safe operating limits','Marine fishing quotas set by the FAO','Carbon budget allocations for nations','B','Developed by Rockström et al. 2009, updated 2023: 6 of 9 planetary boundaries have now been transgressed.','Biosphere integrity is already in the HIGH RISK zone — breached by 10×! 🌍','hard'),
('bio','adults','What is "bioprospecting" and why does it matter for medicine?','Ocean floor mineral extraction','Searching nature for useful compounds, especially for drug development','GPS tracking of wildlife populations','Genetic modification of crop species','B','70% of cancer drugs are natural or nature-derived. Each extinction permanently erases potential medicines.','The cone snail peptide ziconotide is 1,000× stronger than morphine! 💊','hard'),
('bio','adults','The ecosystem services provided by nature are estimated at:','$10 trillion per year','$50 trillion per year','$125–145 trillion per year','$500 trillion per year','C','Natural ecosystem services exceed global GDP — yet they don\'t appear on national balance sheets.','This is why "natural capital accounting" is gaining policy traction! 💡','hard'),
('bio','adults','What percentage of Earth\'s approximately 8.7 million species have been formally described by science?','About 10%','About 25%','About 50%','About 80%','A','Only around 10% of species have been formally described. Each undiscovered species could hold unknowns.','The ocean contains the most undiscovered life — especially deep-sea organisms! 🔬','hard'),

-- Pollution (Adults)
('pollution','adults','The WHO revised 2021 annual mean PM2.5 guideline is:','35 µg/m³','15 µg/m³','5 µg/m³','25 µg/m³','C','99% of the world\'s population breathes air exceeding 5 µg/m³, causing 7 million premature deaths annually.','Most cities globally still far exceed this standard! 🌫️','hard'),
('pollution','adults','PFAS chemicals are called "forever chemicals" because:','They are manufactured continuously','They do not break down in the environment or human body','They persist for exactly 1 million years','They are only found in deep ocean sediment','B','PFAS persist indefinitely, bioaccumulate, and are found in the blood of 97%+ of Americans tested.','The EU is moving to restrict 10,000+ PFAS compounds! ☣️','hard'),
('pollution','adults','What is "chemical trespass" in environmental health?','Companies crossing borders to dump waste illegally','Non-consensual entry of synthetic chemicals into human bodies','Illegal disposal of hazardous materials','Pesticide drift across property boundaries','B','Industrial chemicals now contaminate human blood, fat tissue and breast milk globally without consent.','Over 350 industrial chemicals are found in human blood — many without tested health effects! ⚗️','hard'),
('pollution','adults','What is the primary source of the Gulf of Mexico dead zone?','Oil and gas extraction','Mississippi River agricultural nitrogen and phosphorus runoff','Industrial effluents from New Orleans','Shipping traffic pollutants','B','Agricultural runoff down the Mississippi fuels algal blooms that create a dead zone the size of New Jersey each summer.','Only 50% of applied nitrogen is taken up by crops — the rest pollutes waterways! 🌊','hard'),
('pollution','adults','Microplastics have been discovered in:','Only ocean fish','Only the Pacific Ocean','Human blood, placentas, Arctic snow and deep ocean trenches','Only developing countries\' water supplies','C','Microplastics are now ubiquitous — found in human blood, breast milk, placentas, Arctic snow and the deepest trenches.','A 2024 NEJM study found microplastics in heart disease patients\' arterial plaque! 🔬','hard');


-- ─────────────────────────────────────────────────────────────────
--  FUN FACTS SEED
-- ─────────────────────────────────────────────────────────────────
INSERT INTO fun_facts (topic_key,emoji,title,body) VALUES
('climate','🌡️','Earth is warming fast','The last decade (2011–2020) was the hottest on record. Global temperatures have risen ~1.1°C since pre-industrial times, with the rate accelerating each year.'),
('climate','🧊','Arctic melts 3× faster','The Arctic warms 3–4 times faster than the global average, causing sea ice to shrink by 13% per decade since satellite records began in 1979.'),
('climate','🌊','Sea levels rising faster','Sea levels rose 3.6 mm per year in the last decade versus 1.4 mm per year in the 20th century — threatening over 1 billion coastal people by 2050.'),
('climate','🌩️','Extreme weather intensifying','Climate change makes hurricanes, floods, heatwaves and wildfires more frequent. In 2023 alone, climate disasters cost $380 billion globally.'),
('climate','🌾','Food systems under threat','By 2050, climate change could reduce crop yields by 25% in tropical regions. Wheat, rice and maize are all significantly at risk.'),
('waste','♻️','Only 9% of plastic recycled','Of 9.2 billion tonnes of plastic produced since 1950, only 9% has been recycled. 79% sits in landfills or pollutes our natural environment.'),
('waste','🍽️','One third of food is wasted','1.3 billion tonnes of food is wasted annually — enough to feed 3 billion people. Food waste generates 8–10% of global greenhouse gas emissions.'),
('waste','🗑️','E-waste growing fastest','53.6 million metric tonnes of electronic waste were generated in 2019. Only 17% was officially recycled — worth $57 billion in recoverable materials.'),
('waste','🌊','8 million tonnes of plastic enter oceans yearly','Every year, 8 million metric tonnes of plastic enters our oceans — a garbage truck every minute. It is now found in the deepest ocean trenches.'),
('energy','☀️','Solar cost dropped 99%','Solar PV costs have fallen 99% since 1980. It is now the cheapest source of electricity in history — cheaper than new coal in most of the world.'),
('energy','💨','Wind can power entire nations','Denmark regularly generates over 100% of its electricity needs from wind turbines, exporting the surplus to neighbouring European countries.'),
('energy','🌋','Geothermal heats whole cities','Iceland meets 90% of its heating needs from geothermal energy — hot water piped directly from volcanic activity deep underground.'),
('energy','⚡','Renewables create 13M+ jobs','The global renewable energy sector employed 13.7 million people in 2022, growing 3× faster than the overall energy workforce worldwide.'),
('bio','🐝','1 in 3 bites needs a bee','Bees pollinate 70% of the crops that feed 90% of the world. Without bees, supermarkets would lose roughly half their produce overnight.'),
('bio','🌳','Forests absorb 2.6 billion tonnes of CO₂','The world\'s forests absorb 2.6 billion tonnes of CO₂ per year — acting as the planet\'s lungs. Yet we still lose 10 million hectares annually.'),
('bio','🐠','Coral reefs support 25% of marine life','Covering just 0.1% of the ocean floor, coral reefs support 25% of all marine species. Half of coral reefs have been lost since 1950.'),
('bio','🦁','Wildlife declined 69% since 1970','The Living Planet Index shows an average 69% decline in monitored vertebrate populations between 1970 and 2018. We are in the sixth mass extinction.'),
('pollution','💧','2 billion lack safe water','Over 2 billion people lack access to safe drinking water. Water pollution from agriculture, industry and plastic kills 1.8 million people annually.'),
('pollution','🌬️','Air pollution kills 7 million per year','The WHO estimates air pollution causes 7 million premature deaths annually — more than AIDS, tuberculosis and malaria combined.'),
('pollution','🐟','Microplastics are everywhere','Microplastics have been found in human blood, breast milk, placentas, Arctic snow, deep ocean trenches and even in the air we breathe.');


-- ─────────────────────────────────────────────────────────────────
--  WASTE SORT ITEMS SEED
-- ─────────────────────────────────────────────────────────────────
INSERT INTO waste_items (label, correct_bin, difficulty) VALUES
('🍌 Banana peel',     'compost',  'easy'),
('📰 Newspaper',        'recycle',  'easy'),
('🥫 Tin can',         'recycle',  'easy'),
('🎈 Balloon',         'landfill', 'easy'),
('🔋 Old battery',     'hazard',   'easy'),
('🥗 Salad leaves',    'compost',  'easy'),
('💊 Old medicine',    'hazard',   'hard'),
('🥡 Takeaway box',    'landfill', 'hard'),
('📦 Cardboard',       'recycle',  'hard'),
('🖥️ Old laptop',     'hazard',   'hard'),
('☕ Coffee grounds',  'compost',  'hard'),
('🍶 Glass bottle',    'recycle',  'hard'),
('🧴 Shampoo bottle',  'recycle',  'hard'),
('🍕 Pizza box',       'compost',  'hard'),
('🧪 Chemical bottle', 'hazard',   'hard'),
('🥚 Egg shells',      'compost',  'easy'),
('🗞️ Magazine',        'recycle',  'easy'),
('🍎 Apple core',      'compost',  'easy');


-- ─────────────────────────────────────────────────────────────────
--  SCRAMBLE WORDS SEED
-- ─────────────────────────────────────────────────────────────────
INSERT INTO scramble_words (word, hint, emoji, age_group) VALUES
('SOLAR',        'Energy from the sun',                 '☀️',  'kids'),
('WATER',        'Covers 71% of Earth',                 '🌊',  'kids'),
('TREE',         'Absorbs CO₂ and gives oxygen',        '🌳',  'kids'),
('WIND',         'Turns turbines to make electricity',  '💨',  'kids'),
('BEES',         'They help flowers make seeds',        '🐝',  'kids'),
('RAIN',         'Water falling from clouds',           '🌧️', 'kids'),
('LEAF',         'Part of a plant that makes food',     '🍃',  'kids'),
('FISH',         'Lives underwater in rivers and seas', '🐟',  'kids'),
('RECYCLE',      'Reprocess materials into new ones',   '♻️',  'all'),
('CLIMATE',      'Long-term weather patterns of a region','🌡️','all'),
('CARBON',       'Element in CO₂ causing warming',      '⚗️',  'all'),
('COMPOST',      'Organic waste turned into fertiliser','🌱',  'all'),
('OZONE',        'UV-shielding layer around Earth',     '🛡️',  'teens'),
('METHANE',      'Potent greenhouse gas from livestock','🐄',  'teens'),
('EROSION',      'Soil worn away by water or wind',     '🌊',  'teens'),
('TURBINE',      'Machine that spins to generate power','💨',  'teens'),
('BIODIVERSITY', 'The variety of life on Earth',        '🦋',  'teens'),
('POLLUTION',    'Contamination of air water or soil',  '💧',  'teens'),
('ANTHROPOCENE', 'Current geological epoch shaped by humans','🏭','adults'),
('SEQUESTRATION','Capturing and storing carbon',        '🌳',  'adults'),
('PHOTOVOLTAIC', 'Solar cell technology',               '☀️',  'adults'),
('PERMAFROST',   'Permanently frozen ground in polar regions','🧊','adults');


-- ─────────────────────────────────────────────────────────────────
--  MYTH BUSTER STATEMENTS SEED
-- ─────────────────────────────────────────────────────────────────
INSERT INTO myth_statements (statement, answer, explanation) VALUES
('Solar panels don\'t work on cloudy days.',
 'myth',
 'They generate 10–25% of normal output even on cloudy days — Germany, one of the cloudiest countries, is a solar power leader!'),
('Recycling aluminium saves 95% of the energy needed to make new aluminium.',
 'fact',
 'Aluminium recycling is one of the most energy-efficient recycling processes and can be repeated infinitely without quality loss.'),
('Plastic bags are the leading cause of ocean pollution.',
 'myth',
 'Plastic bottles, fishing gear and cigarette butts make up more ocean waste. Single-use packaging and fishing industry are bigger culprits.'),
('The Amazon rainforest produces about 20% of Earth\'s oxygen.',
 'fact',
 'The Amazon is often called the lungs of the Earth — it also houses 10% of all species on the planet.'),
('Electric cars have zero environmental impact.',
 'myth',
 'They have lower lifetime emissions overall but still require energy for manufacturing batteries and depend on how the electricity is generated.'),
('Bees are responsible for pollinating about one third of the world\'s food supply.',
 'fact',
 'Without bees we would lose a huge portion of our fruits, vegetables and nuts — their economic value exceeds $577 billion per year.'),
('Composting food waste increases landfill methane production.',
 'myth',
 'Composting actually REDUCES methane because it avoids anaerobic decomposition in landfills — compost improves soil instead.'),
('Wind energy is now cheaper than new coal power in most countries.',
 'fact',
 'Onshore wind is among the cheapest electricity sources globally today, even without subsidies, in most major economies.'),
('Microplastics have been found in human blood.',
 'fact',
 'Microplastics are now found everywhere — in blood, lungs, breast milk, placentas and even in heart disease patients\' arterial plaque.'),
('Trees only absorb CO₂ during daytime.',
 'fact',
 'Photosynthesis requires sunlight, so trees absorb CO₂ only during the day. At night they respire and release a small amount of CO₂.');


-- ─────────────────────────────────────────────────────────────────
--  DEMO LEADERBOARD USERS  (optional — remove for production)
--  Passwords are bcrypt hashes of "demo1234"
-- ─────────────────────────────────────────────────────────────────
INSERT IGNORE INTO users
  (full_name, username, email, password, age_group, role, points, quizzes_done, best_streak)
VALUES
  ('Eco Ninja',   'eco_ninja',   'eco_ninja@demo.com',   '$2b$12$demoHashForEcoNinja000000000000000000000000000', 'teens',  'student',    4820, 32, 12),
  ('Green Guru',  'green_guru',  'green_guru@demo.com',  '$2b$12$demoHashForGreenGuru00000000000000000000000000', 'adults', 'teacher',    4210, 28, 10),
  ('Leaf Lord',   'leaf_lord',   'leaf_lord@demo.com',   '$2b$12$demoHashForLeafLord000000000000000000000000000', 'kids',   'student',    3780, 22, 8),
  ('Solar Star',  'solar_star',  'solar_star@demo.com',  '$2b$12$demoHashForSolarStar00000000000000000000000000', 'adults', 'researcher', 3450, 18, 9),
  ('Bio Blaze',   'bio_blaze',   'bio_blaze@demo.com',   '$2b$12$demoHashForBioBlaze000000000000000000000000000', 'teens',  'student',    3100, 15, 7);


-- ─────────────────────────────────────────────────────────────────
--  VERIFICATION  — run after setup to confirm everything is there
-- ─────────────────────────────────────────────────────────────────
SELECT '=== TABLE SUMMARY ===' AS info;
SELECT TABLE_NAME, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'greengen'
ORDER BY TABLE_NAME;

SELECT '=== QUESTION COUNT BY TOPIC AND AGE ===' AS info;
SELECT topic_key, age_group, COUNT(*) AS total_questions
FROM questions
GROUP BY topic_key, age_group
ORDER BY topic_key, age_group;

SELECT '=== BADGE COUNT ===' AS info;
SELECT badge_type, COUNT(*) AS total FROM badges GROUP BY badge_type;

SELECT '=== SETUP COMPLETE ===' AS info;
