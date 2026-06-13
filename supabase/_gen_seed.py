# Generates supabase/seed.sql — 10 courses, 20 verified public-domain book PDFs,
# and 100 quizzes (multiple_choice, true_false, fill_blank, enumeration).
import json, io

courses = [
    ('subj-math', 'Mathematics'),
    ('subj-sci', 'Science'),
    ('subj-eng', 'English'),
    ('subj-ict', 'ICT / Computer'),
    ('subj-hist', 'History'),
    ('subj-geo', 'Geography'),
    ('subj-fil', 'Filipino'),
    ('subj-values', 'Values Education'),
    ('subj-pe', 'PE & Health'),
    ('subj-arts', 'Arts'),
]

def dl(i, f): return f'https://archive.org/download/{i}/{f}'
def cover(i): return f'https://archive.org/services/img/{i}'

# (course_id, title, identifier, filename)
_books = [
    ('subj-math', 'Elements of Geometry & Plane Trigonometry', 'elementsgeometr02loomgoog', 'elementsgeometr02loomgoog.pdf'),
    ('subj-math', 'A Course of Pure Mathematics', 'coursepuremath00hardrich', 'coursepuremath00hardrich_bw.pdf'),
    ('subj-sci', 'A First Course in Physics', 'AFirstCourseInPhysics', 'AFirstCourseInPhysics.pdf'),
    ('subj-sci', 'A Text-book of Inorganic Chemistry', 'atextbookinorga03newtgoog', 'atextbookinorga03newtgoog.pdf'),
    ('subj-eng', 'Manual of English Grammar and Composition', 'manualofenglishg00nesfuoft', 'manualofenglishg00nesfuoft_bw.pdf'),
    ('subj-eng', 'Composition and Rhetoric', 'compositionrheto00hitcuoft', 'compositionrheto00hitcuoft.pdf'),
    ('subj-ict', 'An Investigation of the Laws of Thought (Boole)', 'investigationofl00boolrich', 'investigationofl00boolrich_bw.pdf'),
    ('subj-ict', 'Principia Mathematica', 'cu31924001575244', 'cu31924001575244.pdf'),
    ('subj-hist', 'The Outline of History (H. G. Wells)', 'cu31924028328759', 'cu31924028328759.pdf'),
    ('subj-hist', 'The Story of Mankind', 'storyofmankind00vanl', 'storyofmankind00vanl.pdf'),
    ('subj-geo', 'Physical Geography (Geikie)', 'physicalgeograph00geik_0', 'physicalgeograph00geik_0.pdf'),
    ('subj-geo', 'Maritime Geography and Statistics', 'maritimegeograp01tuckgoog', 'maritimegeograp01tuckgoog.pdf'),
    ('subj-fil', 'Ang Filibusterismo (Jose Rizal)', 'angfilibusterism00riza', 'angfilibusterism00riza.pdf'),
    ('subj-fil', 'Noli Me Tangere (Jose Rizal)', 'nolimetngereelp00rizagoog', 'nolimetngereelp00rizagoog.pdf'),
    ('subj-values', 'The Nicomachean Ethics of Aristotle', 'petersethics00arisrich', 'petersethics00arisrich_bw.pdf'),
    ('subj-values', 'The Republic of Plato', 'a604578400platuoft', 'a604578400platuoft.pdf'),
    ('subj-pe', 'Physical Culture: First Book of Exercises', 'physicalcul91west00houg', 'physicalcul91west00houg_bw.pdf'),
    ('subj-pe', 'Gymnastics for Youth', 'gymnasticsforyou00gutsuoft', 'gymnasticsforyou00gutsuoft_bw.pdf'),
    ('subj-arts', 'Outlines of the History of Painting', 'outlinesofhistor00machuoft', 'outlinesofhistor00machuoft.pdf'),
    ('subj-arts', 'A Text-book of the History of Painting', 'cu31924015249968', 'cu31924015249968.pdf'),
]
books = [(c, t, dl(i, f), cover(i)) for (c, t, i, f) in _books]

# quizzes[course_id] = list of (type, question, answer, options(list), reason)
M = 'multiple_choice'; T = 'true_false'; F = 'fill_blank'; E = 'enumeration'
quizzes = {
 'subj-math': [
  (M, 'What is the value of pi to two decimal places?', '3.14', ['3.14','3.41','2.14','3.16'], 'Pi is approximately 3.14159.'),
  (M, 'What is 15% of 200?', '30', ['15','30','45','20'], '0.15 x 200 = 30.'),
  (M, 'Which of these numbers is prime?', '29', ['21','27','29','33'], '29 has no divisors other than 1 and itself.'),
  (T, 'The sum of the interior angles of a triangle is 180 degrees.', 'True', [], ''),
  (T, 'A square has four equal sides.', 'True', [], ''),
  (T, 'Zero is a positive number.', 'False', [], 'Zero is neither positive nor negative.'),
  (F, 'The perimeter of a square with a side of 5 units is ____.', '20', [], '4 x 5 = 20.'),
  (F, 'In the equation 2x = 10, x equals ____.', '5', [], ''),
  (E, 'List the first four prime numbers.', '2, 3, 5, 7', [], ''),
  (E, 'Name the three types of triangles classified by their sides.', 'equilateral, isosceles, scalene', [], ''),
 ],
 'subj-sci': [
  (M, 'What is the chemical symbol for water?', 'H2O', ['CO2','H2O','O2','NaCl'], ''),
  (M, 'Which planet is known as the Red Planet?', 'Mars', ['Venus','Mars','Jupiter','Saturn'], ''),
  (M, 'Which gas do plants absorb from the air for photosynthesis?', 'Carbon dioxide', ['Oxygen','Nitrogen','Carbon dioxide','Hydrogen'], ''),
  (T, 'The Earth revolves around the Sun.', 'True', [], ''),
  (T, 'Sound travels faster than light.', 'False', [], 'Light is far faster than sound.'),
  (T, 'At sea level, water boils at 100 degrees Celsius.', 'True', [], ''),
  (F, 'The powerhouse of the cell is the ____.', 'mitochondria', [], ''),
  (F, 'The process by which plants make food using sunlight is called ____.', 'photosynthesis', [], ''),
  (E, 'List the three states of matter.', 'solid, liquid, gas', [], ''),
  (E, 'List the first three planets from the Sun.', 'Mercury, Venus, Earth', [], ''),
 ],
 'subj-eng': [
  (M, 'Which word is a noun?', 'dog', ['run','happy','dog','quickly'], 'A noun names a person, place, or thing.'),
  (M, 'What is the past tense of "go"?', 'went', ['goed','went','gone','going'], ''),
  (M, 'Which sentence is grammatically correct?', "She doesn't like it.", ["She don't like it.","She doesn't like it.","She not like it.","She no like it."], ''),
  (T, 'A verb is an action word.', 'True', [], ''),
  (T, '"Their", "there", and "they\'re" all mean the same thing.', 'False', [], 'They are homophones with different meanings.'),
  (T, 'An adjective describes a noun.', 'True', [], ''),
  (F, 'The plural form of "child" is ____.', 'children', [], ''),
  (F, 'A sentence that asks something ends with a ____ mark.', 'question', [], ''),
  (E, 'List the four basic types of sentences.', 'declarative, interrogative, imperative, exclamatory', [], ''),
  (E, 'List the three articles in English.', 'a, an, the', [], ''),
 ],
 'subj-ict': [
  (M, 'What does "CPU" stand for?', 'Central Processing Unit', ['Central Processing Unit','Computer Personal Unit','Central Print Unit','Control Process Unit'], ''),
  (M, 'Which of these is an input device?', 'Keyboard', ['Monitor','Printer','Keyboard','Speaker'], ''),
  (M, 'What does "WWW" stand for?', 'World Wide Web', ['World Wide Web','World Web Wide','Wide World Web','Web World Wide'], ''),
  (T, 'RAM stands for Random Access Memory.', 'True', [], ''),
  (T, 'A mouse is an output device.', 'False', [], 'A mouse is an input device.'),
  (T, 'Software is the physical part of a computer.', 'False', [], 'Hardware is physical; software is the programs.'),
  (F, 'The "brain" of the computer is the ____.', 'CPU', [], ''),
  (F, 'The temporary memory that loses its data when the computer is turned off is the ____.', 'RAM', [], ''),
  (E, 'List the four steps of the basic computer cycle (IPOS).', 'input, process, output, storage', [], ''),
  (E, 'Name the three primary colors of light (RGB).', 'red, green, blue', [], ''),
 ],
 'subj-hist': [
  (M, 'Who is recognized as the national hero of the Philippines?', 'Jose Rizal', ['Andres Bonifacio','Jose Rizal','Emilio Aguinaldo','Lapu-Lapu'], ''),
  (M, 'In what year was Philippine independence from Spain declared?', '1898', ['1898','1946','1521','1872'], 'Declared on June 12, 1898.'),
  (M, 'Who was the first President of the United States?', 'George Washington', ['Abraham Lincoln','George Washington','Thomas Jefferson','John Adams'], ''),
  (T, 'World War II ended in 1945.', 'True', [], ''),
  (T, 'Ferdinand Magellan reached the Philippines in 1521.', 'True', [], ''),
  (T, 'Japan colonized the Philippines for more than 300 years.', 'False', [], 'Spain ruled ~333 years; Japan only ~3 years.'),
  (F, 'Philippine independence was proclaimed in the town of ____, Cavite.', 'Kawit', [], ''),
  (F, 'The ancient Egyptians wrote using picture symbols called ____.', 'hieroglyphics', [], ''),
  (E, 'List the three main colonizers of the Philippines.', 'Spain, United States, Japan', [], ''),
  (E, 'Name the two novels written by Jose Rizal.', 'Noli Me Tangere, El Filibusterismo', [], ''),
 ],
 'subj-geo': [
  (M, 'Which is the largest continent by land area?', 'Asia', ['Africa','Asia','Europe','Antarctica'], ''),
  (M, 'Which river is generally considered the longest in the world?', 'Nile', ['Amazon','Nile','Yangtze','Mississippi'], ''),
  (M, 'The imaginary line dividing Earth into Northern and Southern hemispheres is the ____.', 'Equator', ['Prime Meridian','Equator','Tropic of Cancer','Axis'], ''),
  (T, 'Mount Everest is the highest mountain above sea level.', 'True', [], ''),
  (T, 'The Pacific Ocean is the largest ocean.', 'True', [], ''),
  (T, 'A peninsula is surrounded by water on all sides.', 'False', [], 'That describes an island; a peninsula is surrounded on three sides.'),
  (F, 'The capital city of the Philippines is ____.', 'Manila', [], ''),
  (F, 'The imaginary line at 0 degrees longitude is called the ____ Meridian.', 'Prime', [], ''),
  (E, 'List the four cardinal directions.', 'north, south, east, west', [], ''),
  (E, 'Name the three major island groups of the Philippines.', 'Luzon, Visayas, Mindanao', [], ''),
 ],
 'subj-fil': [
  (M, 'Sino ang pambansang bayani ng Pilipinas?', 'Jose Rizal', ['Andres Bonifacio','Jose Rizal','Emilio Aguinaldo','Apolinario Mabini'], ''),
  (M, 'Ano ang pambansang wika ng Pilipinas?', 'Filipino', ['Ingles','Filipino','Espanyol','Bisaya'], ''),
  (M, 'Ilang patinig (vowels) ang mayroon sa alpabetong Filipino?', '5', ['3','5','7','8'], 'a, e, i, o, u'),
  (T, 'Ang "Lupang Hinirang" ang pambansang awit ng Pilipinas.', 'True', [], ''),
  (T, 'Ang salitang "aklat" ay nangangahulugang "book" sa Ingles.', 'True', [], ''),
  (T, 'Ang "Noli Me Tangere" ay isinulat ni Andres Bonifacio.', 'False', [], 'Isinulat ito ni Jose Rizal.'),
  (F, 'Ang pambansang bulaklak ng Pilipinas ay ang ____.', 'sampaguita', [], ''),
  (F, 'Ang may-akda ng "Noli Me Tangere" ay si Jose ____.', 'Rizal', [], ''),
  (E, 'Ibigay ang tatlong pangunahing pangkat ng mga isla sa Pilipinas.', 'Luzon, Visayas, Mindanao', [], ''),
  (E, 'Ibigay ang dalawang nobela na isinulat ni Jose Rizal.', 'Noli Me Tangere, El Filibusterismo', [], ''),
 ],
 'subj-values': [
  (M, 'Treating others the way you want to be treated is known as the ____.', 'Golden Rule', ['Golden Rule','Silver Rule','Iron Rule','Bronze Rule'], ''),
  (M, 'Which of these shows good character?', 'Honesty', ['Lying','Honesty','Cheating','Stealing'], ''),
  (M, 'Respecting your elders is an example of a ____.', 'Value', ['Bad habit','Value','Crime','Weakness'], ''),
  (T, 'Honesty means telling the truth.', 'True', [], ''),
  (T, 'It is right to bully people who are weaker than you.', 'False', [], ''),
  (T, 'Helping others in need is an act of kindness.', 'True', [], ''),
  (F, 'Being thankful for what you have is a value called ____.', 'gratitude', [], ''),
  (F, 'Giving everyone what they fairly deserve is the value of ____.', 'justice', [], ''),
  (E, 'Give the two Filipino words used to show respect to elders.', 'po, opo', [], ''),
  (E, 'Give the two "magic words" we use to be polite.', 'please, thank you', [], ''),
 ],
 'subj-pe': [
  (M, 'How many bones are there in the adult human body?', '206', ['106','206','306','150'], ''),
  (M, 'Which food group is the main source of energy?', 'Carbohydrates', ['Fruits','Carbohydrates','Vitamins','Water'], ''),
  (M, 'Which sport uses a shuttlecock?', 'Badminton', ['Tennis','Badminton','Basketball','Volleyball'], ''),
  (T, 'Drinking enough water is important for good health.', 'True', [], ''),
  (T, 'Warming up before exercise helps prevent injury.', 'True', [], ''),
  (T, 'Eating only junk food is good for your health.', 'False', [], ''),
  (F, 'The organ that pumps blood throughout the body is the ____.', 'heart', [], ''),
  (F, 'Regular brushing of teeth helps prevent ____ (tooth decay).', 'cavities', [], ''),
  (E, 'List the three food groups in the "Go, Grow, Glow" guide.', 'go, grow, glow', [], ''),
  (E, 'Name the five senses of the body.', 'sight, hearing, smell, taste, touch', [], ''),
 ],
 'subj-arts': [
  (M, 'Which of these is a primary color?', 'Blue', ['Green','Orange','Blue','Purple'], ''),
  (M, 'Who painted the Mona Lisa?', 'Leonardo da Vinci', ['Vincent van Gogh','Pablo Picasso','Leonardo da Vinci','Michelangelo'], ''),
  (M, 'Mixing blue and yellow produces which color?', 'Green', ['Purple','Green','Orange','Brown'], ''),
  (T, 'Red, yellow, and blue are the primary colors.', 'True', [], ''),
  (T, 'A sculpture is a two-dimensional artwork.', 'False', [], 'Sculpture is three-dimensional.'),
  (T, 'Melody is one of the elements of music.', 'True', [], ''),
  (F, 'The three primary colors are red, yellow, and ____.', 'blue', [], ''),
  (F, 'An artwork made of small pieces of colored glass or tile is called a ____.', 'mosaic', [], ''),
  (E, 'List the three primary colors.', 'red, yellow, blue', [], ''),
  (E, 'Name the three secondary colors.', 'green, orange, violet', [], ''),
 ],
}

def q(s): return "'" + str(s).replace("'", "''") + "'"

out = io.StringIO()
out.write("-- ════════════════════════════════════════════════════════════════════\n")
out.write("--  TDLF-Educ · Built-in example content (10 subjects, 20 books, 100 quizzes)\n")
out.write("--  Safe to re-run: it replaces only the seeded subjects' content.\n")
out.write("--  Run AFTER schema.sql.  Paste into Supabase SQL Editor and Run.\n")
out.write("-- ════════════════════════════════════════════════════════════════════\n\n")
out.write("alter table public.quizzes add column if not exists options jsonb;\n\n")

ids = ",".join(q(c) for c, _ in courses)
out.write(f"delete from public.quizzes where course_id in ({ids});\n")
out.write(f"delete from public.books   where course_id in ({ids});\n\n")

out.write("insert into public.courses (id, title) values\n")
out.write(",\n".join(f"  ({q(c)}, {q(t)})" for c, t in courses))
out.write("\non conflict (id) do update set title = excluded.title;\n\n")

out.write("insert into public.books (book_name, link, book_picture, course_id) values\n")
out.write(",\n".join(f"  ({q(t)}, {q(l)}, {q(p)}, {q(c)})" for c, t, l, p in books))
out.write(";\n\n")

rows = []
for cid, items in quizzes.items():
    for (typ, question, ans, opts, reason) in items:
        opts_json = json.dumps(opts)
        rows.append(f"  ({q(question)}, {q(typ)}, {q(ans)}, {q(reason)}, {q(cid)}, {q(opts_json)}::jsonb)")
out.write("insert into public.quizzes (question, quiz_type, correct_answer, reason, course_id, options) values\n")
out.write(",\n".join(rows))
out.write(";\n")

total_q = sum(len(v) for v in quizzes.values())
with open('supabase/seed.sql', 'w', encoding='utf-8') as fh:
    fh.write(out.getvalue())
print(f"Wrote supabase/seed.sql : {len(courses)} courses, {len(books)} books, {total_q} quizzes")
# quick sanity: every MC answer must be in its options
bad = 0
for cid, items in quizzes.items():
    for (typ, ques, ans, opts, _) in items:
        if typ == 'multiple_choice' and ans not in opts:
            print('  !! MC answer not in options:', cid, ques); bad += 1
print('MC integrity issues:', bad)
