# Quizday question pack builder.
# Q(question, correct, [three distractors], explanation, source, category, difficulty)
import json, random, sys, os

ROUNDS = []
def R(*qs):
    assert len(qs) == 10, f"round {len(ROUNDS)+1} has {len(qs)} questions"
    ROUNDS.append(list(qs))
def Q(q, correct, wrong, exp, src, cat, diff):
    assert len(wrong) == 3, q
    return dict(q=q, correct=correct, wrong=wrong, exp=exp, src=src, cat=cat, diff=diff)

# ---------------- Round 1 ----------------
R(
Q("What is the capital of Japan?","Tokyo",["Osaka","Kyoto","Nagoya"],"Tokyo became the seat of government in 1868, when the emperor moved there from Kyoto.","Britannica","Geography","easy"),
Q("How many sides does a hexagon have?","Six",["Five","Seven","Eight"],"The prefix hexa- is Greek for six.","Oxford English Dictionary","General Knowledge","easy"),
Q("Which planet is known as the Red Planet?","Mars",["Venus","Jupiter","Mercury"],"Iron oxide dust across the surface gives Mars its rusty colour.","NASA","Space","easy"),
Q("Which element has the chemical symbol Au?","Gold",["Silver","Aluminium","Argon"],"Au comes from aurum, the Latin word for gold.","Royal Society of Chemistry","Science","medium"),
Q("Who painted The Starry Night?","Vincent van Gogh",["Claude Monet","Paul Cezanne","Edvard Munch"],"Van Gogh painted it in 1889 from his room at the asylum in Saint-Remy-de-Provence.","Museum of Modern Art","Art & Literature","medium"),
Q("Which is the largest ocean on Earth?","Pacific",["Atlantic","Indian","Arctic"],"The Pacific covers about a third of the planet's surface, more than all the land combined.","NOAA","Geography","medium"),
Q("In which country were the ancient Olympic Games held?","Greece",["Italy","Egypt","Turkey"],"They were held at Olympia from 776 BC.","International Olympic Committee","History","medium"),
Q("What is the longest bone in the human body?","Femur",["Tibia","Humerus","Fibula"],"The femur, or thigh bone, is roughly a quarter of a person's height.","Gray's Anatomy","Science","hard"),
Q("Which novel opens with the line Call me Ishmael?","Moby-Dick",["Treasure Island","Robinson Crusoe","The Old Man and the Sea"],"Herman Melville opened his 1851 novel with those three words.","Britannica","Art & Literature","hard"),
Q("What is the smallest country in the world by area?","Vatican City",["Monaco","Nauru","San Marino"],"Vatican City covers about 0.44 square kilometres.","CIA World Factbook","Geography","hard"),
)

# ---------------- Round 2 ----------------
R(
Q("How many continents are there?","Seven",["Five","Six","Eight"],"Africa, Antarctica, Asia, Australia, Europe, North America and South America.","National Geographic","Geography","easy"),
Q("What colour do you get by mixing blue and yellow paint?","Green",["Purple","Orange","Brown"],"Blue and yellow pigments each absorb what the other reflects, leaving green.","Britannica","General Knowledge","easy"),
Q("Which animal is the largest living land mammal?","African elephant",["Hippopotamus","White rhinoceros","Giraffe"],"A bull African elephant can weigh over six tonnes.","World Wildlife Fund","Nature","easy"),
Q("Which country gave the Statue of Liberty to the United States?","France",["Britain","Spain","Italy"],"It was a gift marking the centenary of American independence, dedicated in 1886.","National Park Service","History","medium"),
Q("What is the hardest naturally occurring substance?","Diamond",["Quartz","Steel","Granite"],"Diamond sits at 10, the top of the Mohs scale of hardness.","US Geological Survey","Science","medium"),
Q("Which instrument has 88 keys in its standard form?","Piano",["Organ","Harpsichord","Accordion"],"A modern grand or upright piano has 52 white and 36 black keys.","Britannica","Music","medium"),
Q("In which city would you find the Colosseum?","Rome",["Athens","Istanbul","Naples"],"The amphitheatre was completed in AD 80 in the centre of Rome.","UNESCO","History","medium"),
Q("What does the acronym LASER stand for?","Light Amplification by Stimulated Emission of Radiation",["Linear Amplified Signal Emission Ray","Light Absorption by Silicon Emission Resistor","Layered Analysis of Spectral Energy Range"],"The name describes exactly how the device produces its beam.","Britannica","Science","hard"),
Q("Which sea is the saltiest large body of water on Earth's surface?","Dead Sea",["Red Sea","Mediterranean Sea","Caspian Sea"],"It is roughly ten times saltier than the ocean, which is why swimmers float so easily.","Britannica","Geography","hard"),
Q("Who wrote the play A Doll's House?","Henrik Ibsen",["Anton Chekhov","August Strindberg","Bertolt Brecht"],"Ibsen's 1879 play caused a scandal for the ending, in which Nora walks out.","Britannica","Art & Literature","hard"),
)

# ---------------- Round 3 ----------------
R(
Q("How many minutes are in a full day?","1,440",["1,200","1,600","2,400"],"24 hours times 60 minutes.","General arithmetic","General Knowledge","easy"),
Q("What is the freezing point of water in degrees Celsius?","0",["32","10","100"],"The Celsius scale sets zero at the freezing point of water at sea level.","National Institute of Standards and Technology","Science","easy"),
Q("Which bird is famous for being unable to fly and living in Antarctica?","Penguin",["Albatross","Puffin","Petrel"],"Penguin wings work as flippers for swimming rather than for flight.","British Antarctic Survey","Nature","easy"),
Q("Which river runs through Paris?","Seine",["Loire","Rhone","Garonne"],"The Seine crosses the city from south-east to south-west.","Britannica","Geography","medium"),
Q("Who was the first person to walk on the Moon?","Neil Armstrong",["Buzz Aldrin","Michael Collins","Yuri Gagarin"],"Armstrong stepped onto the surface on 20 July 1969, ahead of Buzz Aldrin.","NASA","Space","medium"),
Q("How many players are on the field per side in a football (soccer) match?","Eleven",["Nine","Ten","Twelve"],"Each team fields ten outfield players and a goalkeeper.","FIFA Laws of the Game","Sport","medium"),
Q("Which gas do plants absorb from the air for photosynthesis?","Carbon dioxide",["Oxygen","Nitrogen","Hydrogen"],"Plants take in carbon dioxide and release oxygen as a by-product.","Royal Society of Biology","Science","medium"),
Q("Which country has the most time zones?","France",["Russia","United States","China"],"Counting its overseas territories, France spans twelve.","CIA World Factbook","Geography","hard"),
Q("What is the study of fungi called?","Mycology",["Botany","Entomology","Virology"],"From the Greek mykes, meaning mushroom.","Oxford English Dictionary","Science","hard"),
Q("Which composer wrote the opera The Magic Flute?","Wolfgang Amadeus Mozart",["Ludwig van Beethoven","Joseph Haydn","Franz Schubert"],"Mozart finished it in 1791, the year he died.","Britannica","Music","hard"),
)

# ---------------- Round 4 ----------------
R(
Q("What is the largest planet in the solar system?","Jupiter",["Saturn","Neptune","Uranus"],"Jupiter is more massive than all the other planets put together.","NASA","Space","easy"),
Q("How many colours are in a rainbow as traditionally listed?","Seven",["Five","Six","Eight"],"Red, orange, yellow, green, blue, indigo and violet.","Britannica","General Knowledge","easy"),
Q("What is the main ingredient in guacamole?","Avocado",["Courgette","Pea","Cucumber"],"Guacamole comes from the Nahuatl ahuacamolli, meaning avocado sauce.","Oxford English Dictionary","Food & Drink","easy"),
Q("Which country is home to the kangaroo?","Australia",["South Africa","Brazil","India"],"All four large kangaroo species are native to Australia.","Australian Museum","Nature","medium"),
Q("In which year did the Second World War end?","1945",["1943","1944","1946"],"Germany surrendered in May and Japan in September 1945.","Imperial War Museum","History","medium"),
Q("What does CPU stand for in computing?","Central Processing Unit",["Central Power Unit","Computer Processing Unit","Core Programming Unit"],"It is the chip that carries out a program's instructions.","Britannica","Technology","medium"),
Q("Which Shakespeare play features the characters Rosencrantz and Guildenstern?","Hamlet",["Macbeth","Othello","King Lear"],"They are Hamlet's old schoolfriends, sent to spy on him.","Folger Shakespeare Library","Art & Literature","medium"),
Q("What is the capital of Canada?","Ottawa",["Toronto","Vancouver","Montreal"],"Queen Victoria chose Ottawa as the capital in 1857, ahead of the larger cities.","Government of Canada","Geography","hard"),
Q("Which metal is liquid at room temperature?","Mercury",["Lead","Tin","Zinc"],"Mercury melts at about minus 39 degrees Celsius.","Royal Society of Chemistry","Science","hard"),
Q("Who directed the 1960 film Psycho?","Alfred Hitchcock",["Orson Welles","Billy Wilder","John Huston"],"Hitchcock shot it in black and white with the crew from his television series.","British Film Institute","Film & TV","hard"),
)

# ---------------- Round 5 ----------------
R(
Q("How many legs does a spider have?","Eight",["Six","Ten","Twelve"],"Eight legs separate spiders from insects, which have six.","Natural History Museum","Nature","easy"),
Q("What is the currency of the United Kingdom?","Pound sterling",["Euro","Krona","Franc"],"Sterling is one of the oldest currencies still in use.","Bank of England","General Knowledge","easy"),
Q("Which sport is played at Wimbledon?","Tennis",["Cricket","Golf","Rugby"],"The championships have been played on grass in south-west London since 1877.","All England Lawn Tennis Club","Sport","easy"),
Q("What is the chemical formula for water?","H2O",["CO2","H2O2","NaCl"],"Two hydrogen atoms bonded to one oxygen atom.","Royal Society of Chemistry","Science","medium"),
Q("Which country built the Great Wall?","China",["Japan","Mongolia","Korea"],"Successive dynasties built and rebuilt it over roughly two thousand years.","UNESCO","History","medium"),
Q("What is the longest river in Africa?","Nile",["Congo","Niger","Zambezi"],"The Nile runs about 6,650 kilometres to the Mediterranean.","Britannica","Geography","medium"),
Q("Which artist cut off part of his own ear?","Vincent van Gogh",["Pablo Picasso","Salvador Dali","Henri Matisse"],"Van Gogh injured his left ear in Arles in December 1888.","Van Gogh Museum","Art & Literature","medium"),
Q("What is the largest organ of the human body?","Skin",["Liver","Lung","Intestine"],"An adult's skin covers roughly two square metres.","National Institutes of Health","Science","hard"),
Q("Which language has the most native speakers worldwide?","Mandarin Chinese",["English","Spanish","Hindi"],"Mandarin has more first-language speakers than any other language.","Ethnologue","Language","hard"),
Q("In Greek myth, who flew too close to the Sun?","Icarus",["Perseus","Theseus","Orpheus"],"The heat melted the wax in his wings and he fell into the sea.","Britannica","Art & Literature","hard"),
)

# ---------------- Round 6 ----------------
R(
Q("What do bees collect to make honey?","Nectar",["Pollen","Sap","Dew"],"Bees gather nectar and reduce its water content inside the hive.","Royal Entomological Society","Nature","easy"),
Q("How many strings does a standard guitar have?","Six",["Four","Five","Seven"],"Standard tuning runs E, A, D, G, B, E.","Britannica","Music","easy"),
Q("Which shape has three sides?","Triangle",["Square","Pentagon","Rhombus"],"Tri- means three in both Latin and Greek.","Oxford English Dictionary","General Knowledge","easy"),
Q("What is the capital of Australia?","Canberra",["Sydney","Melbourne","Perth"],"Canberra was built as a compromise between rivals Sydney and Melbourne.","Parliament of Australia","Geography","medium"),
Q("Who wrote the theory of general relativity?","Albert Einstein",["Isaac Newton","Niels Bohr","Max Planck"],"Einstein published it in 1915, describing gravity as curved spacetime.","Nobel Prize","Science","medium"),
Q("Which country hosted the first modern Olympic Games in 1896?","Greece",["France","Britain","United States"],"They were held in Athens, reviving the ancient games.","International Olympic Committee","Sport","medium"),
Q("What is the main gas in Earth's atmosphere?","Nitrogen",["Oxygen","Carbon dioxide","Argon"],"Nitrogen makes up about 78 per cent of the air.","NOAA","Science","medium"),
Q("Which city is home to the Hermitage Museum?","Saint Petersburg",["Moscow","Vienna","Prague"],"The museum grew from Catherine the Great's private collection.","UNESCO","Art & Literature","hard"),
Q("What is the deepest point in the ocean?","Mariana Trench",["Puerto Rico Trench","Java Trench","Tonga Trench"],"Challenger Deep in the Mariana Trench is about 11 kilometres down.","NOAA","Geography","hard"),
Q("Which vitamin is produced by the skin in sunlight?","Vitamin D",["Vitamin A","Vitamin C","Vitamin K"],"Ultraviolet B light triggers vitamin D synthesis in the skin.","National Institutes of Health","Science","hard"),
)

# ---------------- Round 7 ----------------
R(
Q("What is the opposite of nocturnal?","Diurnal",["Aquatic","Arboreal","Migratory"],"Diurnal animals are active in daylight.","Oxford English Dictionary","Language","easy"),
Q("Which fruit is traditionally used to make cider?","Apple",["Pear","Grape","Cherry"],"Cider is fermented apple juice; the pear version is called perry.","Britannica","Food & Drink","easy"),
Q("How many wheels does a standard bicycle have?","Two",["One","Three","Four"],"Bi- means two, as in bicycle.","Oxford English Dictionary","General Knowledge","easy"),
Q("Which planet has the most prominent ring system?","Saturn",["Jupiter","Uranus","Neptune"],"Saturn's rings are mostly water ice and span hundreds of thousands of kilometres.","NASA","Space","medium"),
Q("In which country is Machu Picchu?","Peru",["Bolivia","Ecuador","Chile"],"The Inca site sits high in the Andes above the Urubamba valley.","UNESCO","Geography","medium"),
Q("Who wrote Pride and Prejudice?","Jane Austen",["Charlotte Bronte","George Eliot","Elizabeth Gaskell"],"Austen published it anonymously in 1813.","British Library","Art & Literature","medium"),
Q("What does DNA stand for?","Deoxyribonucleic acid",["Dinucleic acid","Deoxyribose nucleotide array","Double nucleic acid"],"The molecule carries the genetic instructions of living things.","National Human Genome Research Institute","Science","medium"),
Q("Which empire was ruled by Genghis Khan?","Mongol Empire",["Ottoman Empire","Persian Empire","Byzantine Empire"],"He united the Mongol tribes and began the largest contiguous land empire in history.","Britannica","History","hard"),
Q("What is the term for a word that reads the same forwards and backwards?","Palindrome",["Anagram","Homonym","Acronym"],"Level and racecar are examples.","Oxford English Dictionary","Language","hard"),
Q("Which animal has the longest recorded lifespan?","Ocean quahog clam",["Galapagos tortoise","Bowhead whale","Greenland shark"],"One ocean quahog was dated at over 500 years by its shell rings.","Bangor University","Nature","hard"),
)

# ---------------- Round 8 ----------------
R(
Q("What is the capital of Italy?","Rome",["Milan","Venice","Florence"],"Rome has been the capital of unified Italy since 1871.","Britannica","Geography","easy"),
Q("How many days are in a leap year?","366",["364","365","367"],"A leap year adds 29 February to keep the calendar in step with the seasons.","US Naval Observatory","General Knowledge","easy"),
Q("Which large cat is known for its mane?","Lion",["Tiger","Leopard","Jaguar"],"Only male lions grow the mane, and it thickens with age.","World Wildlife Fund","Nature","easy"),
Q("What is the speed of light in a vacuum, to the nearest thousand kilometres per second?","300,000 km/s",["150,000 km/s","500,000 km/s","1,000,000 km/s"],"The exact figure is 299,792 kilometres per second.","National Institute of Standards and Technology","Science","medium"),
Q("Which country is the largest by land area?","Russia",["Canada","China","United States"],"Russia covers about 17 million square kilometres across two continents.","CIA World Factbook","Geography","medium"),
Q("Who composed the Ninth Symphony that ends with the Ode to Joy?","Ludwig van Beethoven",["Johannes Brahms","Franz Schubert","Gustav Mahler"],"Beethoven finished it in 1824, when he was almost totally deaf.","Britannica","Music","medium"),
Q("What is the largest species of shark?","Whale shark",["Great white shark","Basking shark","Tiger shark"],"Whale sharks reach about 18 metres and feed on plankton.","Marine Conservation Society","Nature","medium"),
Q("Which two elements make up common table salt?","Sodium and chlorine",["Potassium and chlorine","Sodium and sulphur","Calcium and chlorine"],"Table salt is sodium chloride, NaCl.","Royal Society of Chemistry","Science","hard"),
Q("In which century did the French Revolution begin?","18th",["16th","17th","19th"],"It began in 1789, near the end of the eighteenth century.","Britannica","History","hard"),
Q("What is the collective noun for a group of crows?","A murder",["A parliament","A gaggle","A pride"],"The term dates from late medieval lists of hunting nouns.","Oxford English Dictionary","Language","hard"),
)

# ---------------- Round 9 ----------------
R(
Q("Which meal is traditionally eaten in the morning?","Breakfast",["Lunch","Dinner","Supper"],"The word means breaking the overnight fast.","Oxford English Dictionary","Food & Drink","easy"),
Q("How many sides does a cube have?","Six",["Four","Eight","Twelve"],"A cube has six square faces, twelve edges and eight corners.","Britannica","General Knowledge","easy"),
Q("What is the largest mammal on Earth?","Blue whale",["African elephant","Sperm whale","Giraffe"],"A blue whale can reach 30 metres and 150 tonnes.","World Wildlife Fund","Nature","easy"),
Q("Which country is famous for the tango?","Argentina",["Brazil","Spain","Mexico"],"The dance grew out of the working districts of Buenos Aires and Montevideo.","UNESCO","Music","medium"),
Q("What is the tallest mountain above sea level?","Mount Everest",["K2","Kangchenjunga","Denali"],"Everest reaches about 8,849 metres on the Nepal-Tibet border.","National Geographic","Geography","medium"),
Q("Who painted the ceiling of the Sistine Chapel?","Michelangelo",["Raphael","Leonardo da Vinci","Donatello"],"He worked on it between 1508 and 1512, mostly standing on scaffolding.","Vatican Museums","Art & Literature","medium"),
Q("What force keeps planets in orbit around the Sun?","Gravity",["Magnetism","Friction","Inertia"],"The Sun's gravity bends each planet's path into an orbit.","NASA","Space","medium"),
Q("Which organ produces insulin?","Pancreas",["Liver","Kidney","Thyroid"],"Beta cells in the pancreas release insulin to regulate blood sugar.","National Institutes of Health","Science","hard"),
Q("Which ancient wonder stood in the harbour of Rhodes?","Colossus of Rhodes",["Lighthouse of Alexandria","Hanging Gardens","Temple of Artemis"],"The bronze statue stood about 33 metres tall before an earthquake toppled it.","Britannica","History","hard"),
Q("What is the only letter not appearing in any US state name?","Q",["J","X","Z"],"J appears in New Jersey, X in Texas and Z in Arizona.","US Census Bureau","Language","hard"),
)

# ---------------- Round 10 ----------------
R(
Q("What colour is a ripe banana?","Yellow",["Blue","Red","Purple"],"Chlorophyll breaks down as the fruit ripens, leaving yellow pigments.","Britannica","Food & Drink","easy"),
Q("How many hours are in two days?","48",["24","36","72"],"Two days of 24 hours each.","General arithmetic","General Knowledge","easy"),
Q("Which season comes after summer?","Autumn",["Spring","Winter","Monsoon"],"Autumn follows summer and precedes winter.","Oxford English Dictionary","General Knowledge","easy"),
Q("What is the capital of Egypt?","Cairo",["Alexandria","Luxor","Giza"],"Cairo sits on the Nile and is the largest city in the Arab world.","Britannica","Geography","medium"),
Q("Which gas makes up most of the Sun?","Hydrogen",["Helium","Oxygen","Carbon"],"About three quarters of the Sun's mass is hydrogen, which it fuses into helium.","NASA","Space","medium"),
Q("Who wrote the Sherlock Holmes stories?","Arthur Conan Doyle",["Agatha Christie","Wilkie Collins","G. K. Chesterton"],"Conan Doyle introduced Holmes in A Study in Scarlet in 1887.","British Library","Art & Literature","medium"),
Q("In which sport would you perform a slam dunk?","Basketball",["Volleyball","Handball","Netball"],"A dunk is scored by pushing the ball down through the hoop.","NBA","Sport","medium"),
Q("What is the process by which a caterpillar becomes a butterfly?","Metamorphosis",["Photosynthesis","Osmosis","Regeneration"],"The insect rebuilds its body inside the pupa.","Natural History Museum","Nature","hard"),
Q("Which country has the longest coastline?","Canada",["Russia","Indonesia","Australia"],"Canada's coastline runs over 200,000 kilometres including its islands.","CIA World Factbook","Geography","hard"),
Q("What does the Richter scale measure?","Earthquake magnitude",["Wind speed","Ocean depth","Sound volume"],"It expresses the energy released by an earthquake on a logarithmic scale.","US Geological Survey","Science","hard"),
)

# ---------------- Round 11 ----------------
R(
Q("Which meal does the word brunch combine?","Breakfast and lunch",["Breakfast and dinner","Lunch and dinner","Tea and supper"],"The blended word first appeared in British student slang in the 1890s.","Oxford English Dictionary","Food & Drink","easy"),
Q("What device do you use to make a phone call?","Telephone",["Telescope","Thermometer","Telegraph"],"Tele- means far off and -phone means sound.","Oxford English Dictionary","Technology","easy"),
Q("Which sport uses a shuttlecock?","Badminton",["Squash","Table tennis","Lacrosse"],"The feathered shuttlecock slows down quickly, which shapes the whole game.","Badminton World Federation","Sport","easy"),
Q("Who played Jack Dawson in the 1997 film Titanic?","Leonardo DiCaprio",["Brad Pitt","Matt Damon","Johnny Depp"],"DiCaprio starred opposite Kate Winslet in James Cameron's film.","British Film Institute","Film & TV","medium"),
Q("Which company created the iPhone?","Apple",["Microsoft","Nokia","Samsung"],"Apple announced the first iPhone in January 2007.","Apple","Technology","medium"),
Q("In tennis, what is a score of zero called?","Love",["Nil","Duck","Blank"],"The term may come from playing for love, meaning for nothing.","Oxford English Dictionary","Sport","medium"),
Q("Which spice is the most expensive by weight?","Saffron",["Vanilla","Cardamom","Cinnamon"],"Each crocus flower yields only three stigmas, all picked by hand.","Britannica","Food & Drink","medium"),
Q("Which film won the first Academy Award for Best Picture?","Wings",["The Jazz Singer","Sunrise","Metropolis"],"The silent war film Wings won at the first ceremony in 1929.","Academy of Motion Picture Arts and Sciences","Film & TV","hard"),
Q("What does HTTP stand for?","Hypertext Transfer Protocol",["High Transfer Text Protocol","Hyperlink Text Transport Process","Host Transfer Text Protocol"],"It is the set of rules browsers use to request web pages.","Internet Engineering Task Force","Technology","hard"),
Q("Which country has won the most FIFA World Cup titles?","Brazil",["Germany","Italy","Argentina"],"Brazil has won the men's tournament five times.","FIFA","Sport","hard"),
)

# ---------------- Round 12 ----------------
R(
Q("What is the first letter of the Greek alphabet?","Alpha",["Beta","Gamma","Omega"],"Alpha gave English the first half of the word alphabet.","Oxford English Dictionary","Language","easy"),
Q("Which drink is made from crushed grapes?","Wine",["Beer","Cider","Whisky"],"Fermenting grape juice turns its sugars into alcohol.","Britannica","Food & Drink","easy"),
Q("How many players are in a basketball team on court?","Five",["Four","Six","Seven"],"Each side fields five players at a time.","NBA","Sport","easy"),
Q("Which band recorded the album Abbey Road?","The Beatles",["The Rolling Stones","The Who","Pink Floyd"],"It was the last album the four recorded together, in 1969.","British Library","Music","medium"),
Q("What is the capital of Spain?","Madrid",["Barcelona","Seville","Valencia"],"Madrid sits almost exactly in the geographic centre of the country.","Britannica","Geography","medium"),
Q("Which animated studio made Toy Story?","Pixar",["DreamWorks","Studio Ghibli","Illumination"],"Toy Story was the first feature film animated entirely by computer.","British Film Institute","Film & TV","medium"),
Q("What does WWW stand for?","World Wide Web",["World Wired Web","Wide World Web","Web World Wide"],"Tim Berners-Lee coined the name at CERN in 1989.","CERN","Technology","medium"),
Q("Which Italian city is built on a lagoon and known for canals?","Venice",["Genoa","Naples","Pisa"],"The city stands on more than a hundred small islands.","UNESCO","Geography","hard"),
Q("Who wrote the music for the ballet The Nutcracker?","Pyotr Ilyich Tchaikovsky",["Igor Stravinsky","Sergei Prokofiev","Modest Mussorgsky"],"Tchaikovsky wrote it in 1892, near the end of his life.","Britannica","Music","hard"),
Q("What is the most widely eaten staple grain in the world?","Rice",["Wheat","Maize","Barley"],"Rice feeds more people as a daily staple than any other crop.","Food and Agriculture Organization","Food & Drink","hard"),
)

# ---------------- Round 13 ----------------
R(
Q("What do you call a baby dog?","Puppy",["Kitten","Cub","Foal"],"Puppy comes from the French poupee, meaning doll.","Oxford English Dictionary","Nature","easy"),
Q("Which month has 28 days in a common year?","February",["January","April","June"],"February gains a 29th day in leap years.","US Naval Observatory","General Knowledge","easy"),
Q("What is the name of the toy cowboy in Toy Story?","Woody",["Buzz","Rex","Hamm"],"Woody is a pull-string cowboy doll voiced by Tom Hanks.","British Film Institute","Film & TV","easy"),
Q("Which planet is closest to the Sun?","Mercury",["Venus","Earth","Mars"],"Mercury orbits at about 58 million kilometres from the Sun.","NASA","Space","medium"),
Q("Who wrote the song Imagine?","John Lennon",["Paul McCartney","George Harrison","Bob Dylan"],"Lennon released it as the title track of his 1971 album.","British Library","Music","medium"),
Q("What is the largest desert in the world?","Antarctic Desert",["Sahara","Arabian Desert","Gobi"],"A desert is defined by low precipitation, and Antarctica is the driest continent.","National Geographic","Geography","medium"),
Q("Which sport is associated with the Tour de France?","Cycling",["Running","Rowing","Motor racing"],"The three-week road race has run since 1903.","Union Cycliste Internationale","Sport","medium"),
Q("Which programming pioneer is credited with the first algorithm intended for a machine?","Ada Lovelace",["Grace Hopper","Alan Turing","Charles Babbage"],"Her 1843 notes on the Analytical Engine describe a method for computing Bernoulli numbers.","Science Museum, London","Technology","hard"),
Q("What is the highest-grossing film category award at the Cannes Film Festival?","Palme d'Or",["Golden Lion","Golden Bear","Silver Ribbon"],"The Palme d'Or is Cannes' top prize; the Golden Lion and Bear belong to Venice and Berlin.","Festival de Cannes","Film & TV","hard"),
Q("Which cheese is traditionally used on a Margherita pizza?","Mozzarella",["Cheddar","Gouda","Parmesan"],"The classic Neapolitan version uses mozzarella, tomato and basil.","Associazione Verace Pizza Napoletana","Food & Drink","hard"),
)

# ---------------- Round 14 ----------------
R(
Q("How many minutes are in an hour?","60",["30","45","90"],"An hour is divided into 60 minutes, a system inherited from Babylonian counting.","Britannica","General Knowledge","easy"),
Q("Which animal says moo?","Cow",["Sheep","Goat","Horse"],"The word moo is an imitation of the sound itself.","Oxford English Dictionary","Nature","easy"),
Q("What is the main ingredient in bread?","Flour",["Sugar","Butter","Egg"],"Flour, water, salt and a raising agent make a basic loaf.","Britannica","Food & Drink","easy"),
Q("Which superhero is known as the Caped Crusader?","Batman",["Superman","Spider-Man","Iron Man"],"Batman first appeared in Detective Comics in 1939.","Britannica","Film & TV","medium"),
Q("What is the capital of Germany?","Berlin",["Munich","Hamburg","Frankfurt"],"Berlin became the capital again after reunification in 1990.","Britannica","Geography","medium"),
Q("Which instrument does a percussionist strike with mallets and has tuned metal bars?","Vibraphone",["Cello","Oboe","Clarinet"],"The vibraphone adds rotating discs that give the notes their tremolo.","Britannica","Music","medium"),
Q("In which sport do teams compete for the Ashes?","Cricket",["Rugby","Football","Hockey"],"England and Australia have played for the urn since 1882.","Marylebone Cricket Club","Sport","medium"),
Q("What was the first commercially successful video game?","Pong",["Space Invaders","Pac-Man","Asteroids"],"Atari released the table tennis game in 1972.","Computer History Museum","Technology","hard"),
Q("Which director made the films Rashomon and Seven Samurai?","Akira Kurosawa",["Yasujiro Ozu","Kenji Mizoguchi","Hayao Miyazaki"],"Kurosawa's Rashomon won at Venice in 1951 and opened Japanese cinema to the West.","British Film Institute","Film & TV","hard"),
Q("Which country produces the most coffee?","Brazil",["Colombia","Vietnam","Ethiopia"],"Brazil has led world coffee production for over a century.","International Coffee Organization","Food & Drink","hard"),
)

# ---------------- Round 15 ----------------
R(
Q("What colour is the sky on a clear day?","Blue",["Green","Red","Yellow"],"Air scatters short blue wavelengths more than longer red ones.","NOAA","Science","easy"),
Q("How many letters are in the English alphabet?","26",["24","25","28"],"Twenty-six letters, from A to Z.","Oxford English Dictionary","Language","easy"),
Q("Which sport is played with a bat, a ball and bases?","Baseball",["Golf","Tennis","Bowling"],"Batters run a diamond of four bases to score.","Major League Baseball","Sport","easy"),
Q("What is the world's most streamed music service by subscribers?","Spotify",["Apple Music","Amazon Music","Deezer"],"Spotify has led paid music streaming subscriptions since the 2010s.","International Federation of the Phonographic Industry","Music","medium"),
Q("Which continent is Egypt mainly in?","Africa",["Asia","Europe","Oceania"],"Most of Egypt lies in north-east Africa, with the Sinai in Asia.","Britannica","Geography","medium"),
Q("What does GPS stand for?","Global Positioning System",["General Position Sensor","Global Path Service","Geographic Point Signal"],"A network of satellites lets a receiver work out where it is.","US Space Force","Technology","medium"),
Q("Which television series features the fictional Iron Throne?","Game of Thrones",["The Crown","Vikings","Rome"],"The HBO series adapted George R. R. Martin's novels.","British Film Institute","Film & TV","medium"),
Q("Which musical instrument family does the saxophone belong to?","Woodwind",["Brass","Percussion","String"],"Though made of brass, it uses a single reed, which makes it a woodwind.","Britannica","Music","hard"),
Q("What is the oldest continuously inhabited city commonly cited by historians?","Damascus",["Athens","Cairo","Jerusalem"],"Damascus is frequently named as the oldest city continuously lived in.","UNESCO","History","hard"),
Q("Which fruit contains the most seeds on its outside rather than inside?","Strawberry",["Blueberry","Raspberry","Grape"],"The tiny specks on a strawberry are the actual fruits, each holding a seed.","Royal Horticultural Society","Nature","hard"),
)

# ---------------- Round 16 ----------------
R(
Q("What do you call frozen water?","Ice",["Steam","Fog","Mist"],"Water freezes into ice at zero degrees Celsius.","National Institute of Standards and Technology","Science","easy"),
Q("Which day comes after Friday?","Saturday",["Thursday","Sunday","Monday"],"Saturday takes its name from the Roman god Saturn.","Oxford English Dictionary","General Knowledge","easy"),
Q("What is a young cat called?","Kitten",["Puppy","Calf","Lamb"],"Kitten shares a root with the French chaton.","Oxford English Dictionary","Nature","easy"),
Q("Which country is home to the Eiffel Tower?","France",["Belgium","Switzerland","Austria"],"Gustave Eiffel's tower opened for the 1889 Paris exposition.","Britannica","Geography","medium"),
Q("Who wrote the play Romeo and Juliet?","William Shakespeare",["Christopher Marlowe","Ben Jonson","John Webster"],"Shakespeare wrote it in the mid-1590s.","Folger Shakespeare Library","Art & Literature","medium"),
Q("Which planet is famous for a great red storm?","Jupiter",["Mars","Saturn","Neptune"],"The Great Red Spot is a storm that has raged for centuries.","NASA","Space","medium"),
Q("Which country invented tea as a drink?","China",["India","Japan","Sri Lanka"],"Tea drinking is recorded in China long before it spread elsewhere.","Britannica","Food & Drink","medium"),
Q("What is the term for an animal that eats both plants and meat?","Omnivore",["Herbivore","Carnivore","Detritivore"],"Omni- means all in Latin.","Oxford English Dictionary","Nature","hard"),
Q("Which Renaissance artist designed a famous flying machine in his notebooks?","Leonardo da Vinci",["Michelangelo","Raphael","Titian"],"His notebooks include sketches for an ornithopter with flapping wings.","Britannica","Art & Literature","hard"),
Q("What is the largest island in the world?","Greenland",["New Guinea","Borneo","Madagascar"],"Australia is larger but is classed as a continent, not an island.","CIA World Factbook","Geography","hard"),
)

# ---------------- Round 17 ----------------
R(
Q("How many wheels does a car normally have?","Four",["Two","Three","Six"],"Four wheels give a car a stable rectangular footprint.","Britannica","General Knowledge","easy"),
Q("Which insect makes honey?","Bee",["Wasp","Ant","Beetle"],"Honeybees store nectar as honey to feed the colony through winter.","Royal Entomological Society","Nature","easy"),
Q("What is the opposite of hot?","Cold",["Warm","Mild","Dry"],"Hot and cold are the two ends of the temperature scale in everyday use.","Oxford English Dictionary","Language","easy"),
Q("Which US city is known as the Big Apple?","New York",["Chicago","Boston","Los Angeles"],"The nickname spread through 1920s horse racing and later jazz slang.","New York Public Library","Geography","medium"),
Q("Who directed the film Jaws?","Steven Spielberg",["George Lucas","Francis Ford Coppola","Martin Scorsese"],"The 1975 film made Spielberg's name and invented the summer blockbuster.","British Film Institute","Film & TV","medium"),
Q("Which metal is the best conductor of electricity?","Silver",["Copper","Gold","Aluminium"],"Silver conducts slightly better than copper, but costs far more.","Royal Society of Chemistry","Science","medium"),
Q("In which country did sushi originate?","Japan",["China","Korea","Thailand"],"Sushi developed in Japan from earlier methods of preserving fish in rice.","Britannica","Food & Drink","medium"),
Q("What is the study of earthquakes called?","Seismology",["Geology","Meteorology","Volcanology"],"From the Greek seismos, meaning shaking.","US Geological Survey","Science","hard"),
Q("Which composer became deaf later in life but kept writing music?","Ludwig van Beethoven",["Johann Sebastian Bach","Frederic Chopin","Antonio Vivaldi"],"Beethoven's hearing failed from his late twenties onward.","Britannica","Music","hard"),
Q("Which empire was centred on the city of Tenochtitlan?","Aztec Empire",["Inca Empire","Maya civilisation","Olmec civilisation"],"Tenochtitlan stood where Mexico City is today.","Britannica","History","hard"),
)

# ---------------- Round 18 ----------------
R(
Q("What is the name for a group of fish swimming together?","School",["Herd","Flock","Pack"],"School and shoal are both used for fish moving as a group.","Oxford English Dictionary","Nature","easy"),
Q("Which number comes after nine?","Ten",["Eight","Eleven","Twelve"],"Ten is the base of the decimal system.","Britannica","General Knowledge","easy"),
Q("What do you call a person who flies an aircraft?","Pilot",["Captain","Navigator","Engineer"],"The word comes from the Greek for a ship's steersman.","Oxford English Dictionary","Technology","easy"),
Q("Which country is shaped like a boot?","Italy",["Greece","Portugal","Croatia"],"The peninsula's outline resembles a boot kicking Sicily.","Britannica","Geography","medium"),
Q("Who is the author of the Harry Potter novels?","J. K. Rowling",["Philip Pullman","Roald Dahl","C. S. Lewis"],"The first book was published in 1997.","British Library","Art & Literature","medium"),
Q("What does the C in CPR stand for?","Cardio",["Critical","Compression","Cardiac arrest"],"CPR stands for cardiopulmonary resuscitation.","American Heart Association","Science","medium"),
Q("Which video game features a plumber named Mario?","Super Mario Bros.",["Sonic the Hedgehog","Mega Man","Donkey Kong Country"],"Nintendo released it in 1985.","Nintendo","Technology","medium"),
Q("What is the world's most spoken second language?","English",["French","Spanish","Arabic"],"English has more second-language speakers than any other language.","Ethnologue","Language","hard"),
Q("Which planet takes the longest to orbit the Sun?","Neptune",["Uranus","Saturn","Jupiter"],"Neptune takes about 165 Earth years to complete one orbit.","NASA","Space","hard"),
Q("Which dish is made from raw fish sliced without rice?","Sashimi",["Sushi","Ceviche","Tartare"],"Sashimi is fish alone; sushi is defined by the seasoned rice.","Britannica","Food & Drink","hard"),
)

# ---------------- Round 19 ----------------
R(
Q("What is the capital of France?","Paris",["Lyon","Marseille","Nice"],"Paris has been the capital since the tenth century.","Britannica","Geography","easy"),
Q("How many players are on a volleyball team on court?","Six",["Five","Seven","Eight"],"Six per side rotate positions after winning serve.","Federation Internationale de Volleyball","Sport","easy"),
Q("What is the young of a sheep called?","Lamb",["Calf","Kid","Foal"],"A kid is a young goat and a calf a young cow.","Oxford English Dictionary","Nature","easy"),
Q("Which artist is known for paintings of soup cans?","Andy Warhol",["Roy Lichtenstein","Jasper Johns","Jackson Pollock"],"Warhol exhibited his Campbell's Soup Cans in 1962.","Museum of Modern Art","Art & Literature","medium"),
Q("What is the largest bird by wingspan?","Wandering albatross",["Andean condor","Golden eagle","Great bustard"],"Its wings can span over three metres.","British Antarctic Survey","Nature","medium"),
Q("Which country hosted the 2016 Summer Olympics?","Brazil",["China","Britain","Japan"],"Rio de Janeiro was the first South American host city.","International Olympic Committee","Sport","medium"),
Q("What does the abbreviation e.g. stand for?","Exempli gratia",["Et cetera","Ergo","Et alia"],"It is Latin for for example; i.e. means that is.","Oxford English Dictionary","Language","medium"),
Q("Which element has the atomic number 1?","Hydrogen",["Helium","Carbon","Oxygen"],"One proton in the nucleus makes it the lightest element.","Royal Society of Chemistry","Science","hard"),
Q("Who wrote the novel One Hundred Years of Solitude?","Gabriel Garcia Marquez",["Jorge Luis Borges","Mario Vargas Llosa","Isabel Allende"],"The Colombian writer published it in 1967.","Nobel Prize","Art & Literature","hard"),
Q("Which sea creature has three hearts?","Octopus",["Dolphin","Jellyfish","Starfish"],"Two hearts pump blood to the gills and one to the rest of the body.","Marine Biological Association","Nature","hard"),
)

# ---------------- Round 20 ----------------
R(
Q("What do you use to write on a blackboard?","Chalk",["Ink","Paint","Graphite"],"Chalk is a soft form of limestone that leaves a mark on slate.","US Geological Survey","General Knowledge","easy"),
Q("Which meal is eaten in the evening?","Dinner",["Breakfast","Brunch","Elevenses"],"Dinner is the main evening meal in most English-speaking usage.","Oxford English Dictionary","Food & Drink","easy"),
Q("How many days are in a week?","Seven",["Five","Six","Eight"],"The seven-day week spread from Babylonian and Jewish practice.","Britannica","General Knowledge","easy"),
Q("Which film features the line Here's looking at you, kid?","Casablanca",["Gone with the Wind","Citizen Kane","The Maltese Falcon"],"Humphrey Bogart says it to Ingrid Bergman in the 1942 film.","British Film Institute","Film & TV","medium"),
Q("What is the capital of Brazil?","Brasilia",["Rio de Janeiro","Sao Paulo","Salvador"],"Brasilia was purpose-built inland and became capital in 1960.","Britannica","Geography","medium"),
Q("Which vitamin is found in high amounts in citrus fruit?","Vitamin C",["Vitamin D","Vitamin B12","Vitamin E"],"A lack of vitamin C causes scurvy, once common among sailors.","National Institutes of Health","Science","medium"),
Q("Which instrument is played by pressing keys that open holes and is held sideways?","Flute",["Trumpet","Violin","Harp"],"The player blows across the mouth hole rather than into a reed.","Britannica","Music","medium"),
Q("Which ancient civilisation built the pyramids at Giza?","Ancient Egyptians",["Romans","Sumerians","Phoenicians"],"They were built as royal tombs during the Old Kingdom.","UNESCO","History","hard"),
Q("What is the fastest land animal over a short distance?","Cheetah",["Pronghorn","Lion","Greyhound"],"A cheetah can reach about 100 kilometres per hour in short bursts.","World Wildlife Fund","Nature","hard"),
Q("Which programming language was named after a British comedy troupe?","Python",["Java","Ruby","Perl"],"Guido van Rossum named it after Monty Python's Flying Circus.","Python Software Foundation","Technology","hard"),
)

# ---------------- Round 21 ----------------
R(
Q("What shape is a standard football (soccer) pitch?","Rectangle",["Circle","Triangle","Hexagon"],"The laws set a rectangular field of play with touchlines longer than the goal lines.","FIFA Laws of the Game","Sport","easy"),
Q("Which animal is known for its black and white stripes?","Zebra",["Leopard","Cheetah","Hyena"],"No two zebras have the same stripe pattern.","World Wildlife Fund","Nature","easy"),
Q("What do you call the person who leads an orchestra?","Conductor",["Composer","Soloist","Producer"],"The conductor sets tempo and balance for the players.","Britannica","Music","easy"),
Q("Which US president appears on the one dollar bill?","George Washington",["Abraham Lincoln","Thomas Jefferson","Benjamin Franklin"],"Washington has appeared on the one dollar note since 1869.","US Bureau of Engraving and Printing","History","medium"),
Q("What is the hottest planet in the solar system?","Venus",["Mercury","Mars","Jupiter"],"A thick carbon dioxide atmosphere traps heat, making Venus hotter than Mercury.","NASA","Space","medium"),
Q("Which sea separates Europe from Africa?","Mediterranean Sea",["Baltic Sea","North Sea","Black Sea"],"The Strait of Gibraltar links it to the Atlantic.","Britannica","Geography","medium"),
Q("Who wrote the dystopian novel Nineteen Eighty-Four?","George Orwell",["Aldous Huxley","Ray Bradbury","H. G. Wells"],"Orwell published it in 1949, the year before he died.","British Library","Art & Literature","medium"),
Q("What is the medical term for the kneecap?","Patella",["Scapula","Clavicle","Sternum"],"The patella is a small bone that protects the knee joint.","Gray's Anatomy","Science","hard"),
Q("Which country was the first to give women the vote in national elections?","New Zealand",["United States","Britain","Finland"],"New Zealand granted women the vote in 1893.","New Zealand Parliament","History","hard"),
Q("What is the name for a shape with ten sides?","Decagon",["Nonagon","Octagon","Dodecagon"],"Deca- is Greek for ten.","Oxford English Dictionary","General Knowledge","hard"),
)

# ---------------- Round 22 ----------------
R(
Q("Which utensil is used to eat soup?","Spoon",["Fork","Knife","Chopsticks"],"A spoon's bowl holds liquid, which a fork cannot.","Oxford English Dictionary","Food & Drink","easy"),
Q("What is the colour of an emerald?","Green",["Blue","Red","Yellow"],"Traces of chromium give emerald its green colour.","US Geological Survey","General Knowledge","easy"),
Q("Which animal is the tallest in the world?","Giraffe",["Elephant","Camel","Ostrich"],"An adult male giraffe can stand over five metres tall.","World Wildlife Fund","Nature","easy"),
Q("In which country is the city of Marrakesh?","Morocco",["Algeria","Tunisia","Egypt"],"Marrakesh lies at the foot of the Atlas Mountains.","UNESCO","Geography","medium"),
Q("Which film series features a wizard school called Hogwarts?","Harry Potter",["The Lord of the Rings","Narnia","His Dark Materials"],"Eight films were adapted from the seven novels.","British Film Institute","Film & TV","medium"),
Q("What is the chemical symbol for iron?","Fe",["Ir","In","Fr"],"Fe comes from ferrum, the Latin for iron.","Royal Society of Chemistry","Science","medium"),
Q("Which musical term means to play softly?","Piano",["Forte","Allegro","Staccato"],"The instrument is named for its ability to play both piano and forte.","Britannica","Music","medium"),
Q("Which mountain range separates Europe from Asia?","Ural Mountains",["Alps","Caucasus","Carpathians"],"The Urals run roughly north to south through Russia.","Britannica","Geography","hard"),
Q("What is the name of the largest moon of Saturn?","Titan",["Europa","Ganymede","Io"],"Titan is the only moon known to have a dense atmosphere.","NASA","Space","hard"),
Q("Which writer created the detective Hercule Poirot?","Agatha Christie",["Arthur Conan Doyle","Dorothy L. Sayers","Georges Simenon"],"Poirot first appeared in The Mysterious Affair at Styles in 1920.","British Library","Art & Literature","hard"),
)

# ---------------- Round 23 ----------------
R(
Q("How many zeros are in one thousand?","Three",["Two","Four","Five"],"One thousand is written 1,000.","General arithmetic","General Knowledge","easy"),
Q("Which bird is a symbol of peace?","Dove",["Eagle","Owl","Raven"],"The dove with an olive branch became a peace emblem through the story of Noah.","Britannica","Nature","easy"),
Q("What do you call a doctor for animals?","Veterinarian",["Pharmacist","Surgeon","Physician"],"Vet comes from the Latin veterinae, meaning working animals.","Oxford English Dictionary","Science","easy"),
Q("Which country is the largest producer of olive oil?","Spain",["Italy","Greece","Turkey"],"Spain produces roughly half the world's olive oil.","International Olive Council","Food & Drink","medium"),
Q("Who was the first woman to win a Nobel Prize?","Marie Curie",["Rosalind Franklin","Dorothy Hodgkin","Lise Meitner"],"Curie won the physics prize in 1903 and later the chemistry prize.","Nobel Prize","Science","medium"),
Q("Which city hosted the 2012 Summer Olympics?","London",["Beijing","Athens","Sydney"],"London became the first city to host the modern Games three times.","International Olympic Committee","Sport","medium"),
Q("What is the capital of Argentina?","Buenos Aires",["Cordoba","Rosario","Mendoza"],"The name means good winds in Spanish.","Britannica","Geography","medium"),
Q("Which artist painted Guernica?","Pablo Picasso",["Joan Miro","Salvador Dali","Francisco Goya"],"Picasso painted it in 1937 in response to the bombing of the Basque town.","Museo Reina Sofia","Art & Literature","hard"),
Q("What is the smallest unit of an element that retains its properties?","Atom",["Molecule","Electron","Cell"],"Split the atom and you no longer have that element.","Royal Society of Chemistry","Science","hard"),
Q("Which sport awards the Vince Lombardi Trophy?","American football",["Ice hockey","Baseball","Basketball"],"It goes to the winner of the Super Bowl.","National Football League","Sport","hard"),
)

# ---------------- Round 24 ----------------
R(
Q("What is the main colour of a traditional London bus?","Red",["Blue","Green","Yellow"],"London's double-deckers have been red since the early twentieth century.","Transport for London","General Knowledge","easy"),
Q("Which fruit is dried to make a raisin?","Grape",["Plum","Apricot","Fig"],"A dried plum is a prune and a dried apricot keeps its own name.","Oxford English Dictionary","Food & Drink","easy"),
Q("What is the opposite of ancient?","Modern",["Historic","Antique","Classic"],"Modern describes the present or recent times.","Oxford English Dictionary","Language","easy"),
Q("Which planet do we live on?","Earth",["Mars","Venus","Mercury"],"Earth is the third planet from the Sun.","NASA","Space","easy"),
Q("Who wrote the fairy tale The Little Mermaid?","Hans Christian Andersen",["The Brothers Grimm","Charles Perrault","Aesop"],"Andersen published the Danish story in 1837.","Royal Danish Library","Art & Literature","medium"),
Q("Which gas do humans breathe out in the greatest increase?","Carbon dioxide",["Oxygen","Nitrogen","Helium"],"Exhaled air carries far more carbon dioxide than the air breathed in.","National Institutes of Health","Science","medium"),
Q("In which country did the sauna originate?","Finland",["Sweden","Norway","Russia"],"The word sauna is Finnish and the practice is central to Finnish life.","UNESCO","Geography","medium"),
Q("Which band released the album The Dark Side of the Moon?","Pink Floyd",["Led Zeppelin","The Doors","Queen"],"The 1973 album stayed on the charts for years.","British Library","Music","hard"),
Q("What is the largest internal organ in the human body?","Liver",["Heart","Stomach","Kidney"],"The liver weighs around 1.5 kilograms in an adult.","National Institutes of Health","Science","hard"),
Q("Which war ended with the Treaty of Versailles?","First World War",["Second World War","Crimean War","Napoleonic Wars"],"The treaty was signed in 1919, the year after the fighting stopped.","Imperial War Museum","History","hard"),
)

# ---------------- Round 25 ----------------
R(
Q("How many eyes does a typical human have?","Two",["One","Three","Four"],"Two forward-facing eyes give humans depth perception.","National Institutes of Health","Science","easy"),
Q("Which animal is known as man's best friend?","Dog",["Cat","Horse","Parrot"],"Dogs were the first animals humans domesticated.","Natural History Museum","Nature","easy"),
Q("What is the first month of the year?","January",["February","March","December"],"January is named after Janus, the Roman god of beginnings.","Oxford English Dictionary","General Knowledge","easy"),
Q("Which ocean lies between Europe and North America?","Atlantic",["Pacific","Indian","Arctic"],"The Atlantic is the second largest ocean.","NOAA","Geography","medium"),
Q("Who directed the film Parasite?","Bong Joon-ho",["Park Chan-wook","Kim Ki-duk","Lee Chang-dong"],"It was the first film not in English to win Best Picture.","Academy of Motion Picture Arts and Sciences","Film & TV","medium"),
Q("Which acid is found in vinegar?","Acetic acid",["Citric acid","Lactic acid","Sulphuric acid"],"Vinegar is a dilute solution of acetic acid in water.","Royal Society of Chemistry","Science","medium"),
Q("What is the national sport of Japan often described as?","Sumo",["Judo","Karate","Kendo"],"Sumo has ceremonial roots going back centuries.","Japan Sumo Association","Sport","medium"),
Q("Which country has the most people?","India",["China","United States","Indonesia"],"India passed China as the most populous country in 2023.","United Nations Population Division","Geography","hard"),
Q("What does the term photosynthesis literally mean?","Putting together with light",["Breaking down with water","Growing towards light","Feeding on air"],"From the Greek photo, light, and synthesis, putting together.","Oxford English Dictionary","Science","hard"),
Q("Which instrument did Louis Armstrong famously play?","Trumpet",["Saxophone","Piano","Double bass"],"Armstrong reshaped jazz with his trumpet playing and his voice.","Britannica","Music","hard"),
)

# ---------------- Round 26 ----------------
R(
Q("What do caterpillars turn into?","Butterflies or moths",["Beetles","Spiders","Dragonflies"],"Both butterflies and moths begin life as caterpillars.","Natural History Museum","Nature","easy"),
Q("Which drink is known for containing caffeine and made from roasted beans?","Coffee",["Tea","Cocoa","Lemonade"],"Coffee is brewed from roasted and ground coffee beans.","International Coffee Organization","Food & Drink","easy"),
Q("How many degrees are in a right angle?","90",["45","180","360"],"Four right angles make a full turn of 360 degrees.","Britannica","General Knowledge","easy"),
Q("Which language is spoken in Brazil?","Portuguese",["Spanish","French","Italian"],"Brazil was colonised by Portugal, unlike most of South America.","Britannica","Language","medium"),
Q("What is the tallest building in the world?","Burj Khalifa",["Shanghai Tower","One World Trade Center","Taipei 101"],"The Burj Khalifa in Dubai stands about 828 metres.","Council on Tall Buildings and Urban Habitat","Technology","medium"),
Q("Which sea creature is known for changing colour to blend in?","Cuttlefish",["Tuna","Cod","Herring"],"Cuttlefish use pigment cells called chromatophores to change appearance in an instant.","Marine Biological Association","Nature","medium"),
Q("Who painted the Mona Lisa?","Leonardo da Vinci",["Michelangelo","Raphael","Botticelli"],"He worked on the portrait from about 1503.","Louvre Museum","Art & Literature","medium"),
Q("What is the deepest lake in the world?","Lake Baikal",["Lake Superior","Lake Tanganyika","Caspian Sea"],"Baikal in Siberia is over 1,600 metres deep and holds a fifth of the world's unfrozen fresh water.","UNESCO","Geography","hard"),
Q("Which scientist proposed the three laws of motion?","Isaac Newton",["Galileo Galilei","Johannes Kepler","Robert Hooke"],"Newton set them out in the Principia in 1687.","Royal Society","Science","hard"),
Q("Which country's flag is a red circle on a white background?","Japan",["Bangladesh","South Korea","Switzerland"],"The red disc represents the sun.","Britannica","Geography","hard"),
)

# ---------------- Round 27 ----------------
R(
Q("What do you call the sound a dog makes?","Bark",["Meow","Moo","Neigh"],"Bark is used for dogs, foxes and some seals.","Oxford English Dictionary","Nature","easy"),
Q("Which room is food usually cooked in?","Kitchen",["Bedroom","Bathroom","Garage"],"The word comes from the Latin coquina, meaning cooking place.","Oxford English Dictionary","General Knowledge","easy"),
Q("How many sides does a square have?","Four",["Three","Five","Six"],"All four sides of a square are equal in length.","Britannica","General Knowledge","easy"),
Q("Which country is home to the fjords?","Norway",["Denmark","Netherlands","Ireland"],"Glaciers carved Norway's deep coastal inlets.","UNESCO","Geography","medium"),
Q("What is the main language spoken in Austria?","German",["Austrian","Hungarian","Czech"],"There is no separate Austrian language; the state language is German.","Britannica","Language","medium"),
Q("Which television talent show format began in Britain in 2001 as Pop Idol?","Idol",["The Voice","X Factor","Got Talent"],"The Idol format was later exported as American Idol and many other versions.","British Film Institute","Film & TV","medium"),
Q("What is the process of water turning into vapour called?","Evaporation",["Condensation","Precipitation","Sublimation"],"Condensation is the reverse, when vapour becomes liquid.","NOAA","Science","medium"),
Q("Which mammal is capable of true sustained flight?","Bat",["Flying squirrel","Colugo","Sugar glider"],"Others glide; only bats flap their wings to fly.","Natural History Museum","Nature","hard"),
Q("Which city was the capital of the Byzantine Empire?","Constantinople",["Rome","Alexandria","Antioch"],"It is now Istanbul.","Britannica","History","hard"),
Q("Which chess piece can only move diagonally?","Bishop",["Rook","Knight","King"],"The rook moves in straight lines and the knight in an L shape.","International Chess Federation","Sport","hard"),
)

# ---------------- Round 28 ----------------
R(
Q("Which sense do you use to detect smells?","Smell",["Sight","Hearing","Touch"],"The olfactory receptors sit high inside the nose.","National Institutes of Health","Science","easy"),
Q("What is the colour of snow?","White",["Grey","Blue","Clear"],"Snow scatters all wavelengths of visible light roughly equally.","NOAA","General Knowledge","easy"),
Q("Which animal lives in a hive?","Bee",["Rabbit","Mole","Badger"],"A colony of honeybees lives together in a hive.","Royal Entomological Society","Nature","easy"),
Q("Which country is known as the Land of the Rising Sun?","Japan",["China","Thailand","Vietnam"],"The Japanese name Nippon means origin of the sun.","Britannica","Geography","medium"),
Q("Who was the first President of the United States?","George Washington",["John Adams","Thomas Jefferson","James Madison"],"He took office in 1789.","US National Archives","History","medium"),
Q("Which dance style originated in Argentina and is danced in close embrace?","Tango",["Salsa","Flamenco","Samba"],"Tango grew from the port districts of Buenos Aires.","UNESCO","Music","medium"),
Q("What is the standard unit of electrical resistance?","Ohm",["Volt","Ampere","Watt"],"It is named after Georg Ohm.","National Institute of Standards and Technology","Science","medium"),
Q("Which planet was reclassified as a dwarf planet in 2006?","Pluto",["Ceres","Eris","Makemake"],"The International Astronomical Union redefined what counts as a planet.","International Astronomical Union","Space","hard"),
Q("What is the world's most visited art museum?","The Louvre",["British Museum","Metropolitan Museum of Art","Uffizi Gallery"],"The Louvre in Paris draws more visitors than any other art museum.","Louvre Museum","Art & Literature","hard"),
Q("Which grain is used to make traditional Japanese sake?","Rice",["Barley","Wheat","Millet"],"Sake is brewed from polished rice, water and koji mould.","Britannica","Food & Drink","hard"),
)

# ---------------- Round 29 ----------------
R(
Q("How many hours are in a day?","24",["12","18","36"],"The 24-hour day comes from ancient Egyptian timekeeping.","Britannica","General Knowledge","easy"),
Q("Which body part do you hear with?","Ear",["Nose","Eye","Tongue"],"The eardrum turns sound waves into vibrations the inner ear can read.","National Institutes of Health","Science","easy"),
Q("What is a group of wolves called?","Pack",["Herd","Flock","School"],"A pack is usually a family group.","Oxford English Dictionary","Nature","easy"),
Q("Which country invented paper?","China",["Egypt","India","Greece"],"Paper making is recorded in Han dynasty China around AD 105.","Britannica","History","medium"),
Q("Which film won Best Picture at the 2020 Academy Awards?","Parasite",["1917","Joker","Once Upon a Time in Hollywood"],"It was the first film not in English to take the award.","Academy of Motion Picture Arts and Sciences","Film & TV","medium"),
Q("What is the capital of India?","New Delhi",["Mumbai","Kolkata","Chennai"],"The capital moved from Calcutta to New Delhi in 1911.","Government of India","Geography","medium"),
Q("Which instrument has pedals, strings and a soundboard and is plucked?","Harp",["Guitar","Cello","Banjo"],"Pedals on a concert harp change the pitch of the strings.","Britannica","Music","medium"),
Q("What does the acronym RADAR stand for?","Radio Detection and Ranging",["Rapid Detection and Recording","Radio Direction and Reading","Range Detection and Return"],"It measures distance by timing radio echoes.","Britannica","Technology","hard"),
Q("Which blood type is known as the universal donor for red cells?","O negative",["AB positive","A positive","B negative"],"O negative cells carry none of the main antigens that trigger rejection.","American Red Cross","Science","hard"),
Q("Which mountain is the highest in Africa?","Kilimanjaro",["Mount Kenya","Mount Stanley","Ras Dashen"],"Kilimanjaro in Tanzania rises about 5,895 metres.","National Geographic","Geography","hard"),
)

# ---------------- Round 30 ----------------
R(
Q("What do you call a story that is not true and is written to entertain?","Fiction",["Biography","Documentary","Report"],"Non-fiction covers writing that reports fact.","Oxford English Dictionary","Art & Literature","easy"),
Q("Which meal do people traditionally eat on a picnic?","Packed food",["Roast dinner","Soup course","Banquet"],"A picnic is a meal carried and eaten outdoors.","Oxford English Dictionary","Food & Drink","easy"),
Q("How many players serve at a time in a singles tennis match?","One",["Two","Three","Four"],"Singles is one player per side.","International Tennis Federation","Sport","easy"),
Q("Which continent has the fewest countries?","Antarctica",["Australia","Europe","South America"],"Antarctica has no countries at all; it is governed by treaty.","Antarctic Treaty Secretariat","Geography","medium"),
Q("Who wrote the novel Frankenstein?","Mary Shelley",["Bram Stoker","Edgar Allan Poe","Emily Bronte"],"She began it in 1816 when she was eighteen.","British Library","Art & Literature","medium"),
Q("Which layer of the atmosphere contains most of the ozone?","Stratosphere",["Troposphere","Mesosphere","Thermosphere"],"The ozone layer sits roughly 15 to 35 kilometres up.","NOAA","Science","medium"),
Q("What is the name of the galaxy that contains our solar system?","Milky Way",["Andromeda","Triangulum","Whirlpool"],"Our solar system sits in one of its spiral arms.","NASA","Space","medium"),
Q("Which composer wrote The Four Seasons?","Antonio Vivaldi",["Johann Sebastian Bach","George Frideric Handel","Arcangelo Corelli"],"Vivaldi published the four violin concertos in 1725.","Britannica","Music","hard"),
Q("What is the term for the study of word origins?","Etymology",["Entomology","Ecology","Epidemiology"],"Entomology, easily confused with it, is the study of insects.","Oxford English Dictionary","Language","hard"),
Q("Which country first launched an artificial satellite into orbit?","Soviet Union",["United States","Britain","France"],"Sputnik 1 was launched in October 1957.","NASA","Space","hard"),
)

# ------------------------------------------------------------------
def emit(path):
    rng = random.Random(20260909)
    out = []
    for ri, rnd in enumerate(ROUNDS):
        qs = []
        for qi, item in enumerate(rnd):
            opts = [item["correct"]] + list(item["wrong"])
            rng.shuffle(opts)
            qs.append({
                "id": f"r{ri+1:02d}q{qi+1:02d}",
                "question": item["q"],
                "answers": opts,
                "correct": opts.index(item["correct"]),
                "explanation": item["exp"],
                "source": item["src"],
                "category": item["cat"],
                "difficulty": item["diff"],
            })
        out.append({"round": ri + 1, "questions": qs})
    doc = {"version": 1, "rounds": out}
    json.dump(doc, open(path, "w"), indent=1, ensure_ascii=True)
    return doc

def validate(doc):
    errs, seen_q = [], {}
    order = {"easy": 0, "medium": 1, "hard": 2}
    for r in doc["rounds"]:
        qs = r["questions"]
        if len(qs) != 10: errs.append(f"round {r['round']}: {len(qs)} questions")
        diffs = [order[q["difficulty"]] for q in qs]
        if diffs != sorted(diffs): errs.append(f"round {r['round']}: difficulty not ramping: {[q['difficulty'] for q in qs]}")
        for q in qs:
            key = q["question"].strip().lower()
            if key in seen_q: errs.append(f"duplicate question: {q['question'][:50]} ({seen_q[key]} and {q['id']})")
            seen_q[key] = q["id"]
            if len(q["answers"]) != 4: errs.append(f"{q['id']}: {len(q['answers'])} answers")
            if len(set(q["answers"])) != 4: errs.append(f"{q['id']}: duplicate answer text")
            if not (0 <= q["correct"] < 4): errs.append(f"{q['id']}: bad correct index")
            for f in ("explanation", "source", "category"):
                if not q[f].strip(): errs.append(f"{q['id']}: empty {f}")
            if len(q["question"]) > 130: errs.append(f"{q['id']}: question too long ({len(q['question'])})")
            if len(q["explanation"]) > 160: errs.append(f"{q['id']}: explanation too long ({len(q['explanation'])})")
            for a in q["answers"]:
                if len(a) > 60: errs.append(f"{q['id']}: answer too long: {a[:40]}")
    return errs

if __name__ == "__main__":
    path = sys.argv[1]
    doc = emit(path)
    errs = validate(doc)
    n = sum(len(r["questions"]) for r in doc["rounds"])
    print(f"rounds={len(doc['rounds'])} questions={n} bytes={os.path.getsize(path)}")
    cats = {}
    for r in doc["rounds"]:
        for q in r["questions"]: cats[q["category"]] = cats.get(q["category"], 0) + 1
    print("categories:", dict(sorted(cats.items(), key=lambda kv: -kv[1])))
    print("ERRORS:" if errs else "no errors")
    for e in errs: print("  -", e)
