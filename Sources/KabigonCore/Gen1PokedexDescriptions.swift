import Foundation

extension Gen1Pokedex {
    /// Short, original species summaries for the complete Kanto Pokédex.
    public static let descriptions: [String] = [
        // 001-009
        "A seed planted on its back at birth grows by absorbing sunlight.",
        "The bud on its back swells with stored energy and releases a sweet aroma before blooming.",
        "Its broad flower converts sunlight into energy and can soothe others with its fragrance.",
        "The flame on its tail reflects its health and emotions, burning brighter when it is excited.",
        "A fiery and aggressive Pokémon that fights with sharp claws and a blazing tail.",
        "It crosses the sky on powerful wings and breathes fire hot enough to melt rock.",
        "Its rounded shell protects it in battle and helps it swim with precise water jets.",
        "Its furry ears and tail are signs of longevity, while its shell provides excellent defense.",
        "Pressurized water cannons built into its shell can punch through thick steel.",

        // 010-019
        "Its short feet have suction pads that let it climb trees while searching for leaves.",
        "A hardened shell protects the soft body inside as it prepares for evolution.",
        "The scales on its wings repel water, letting it fly even in heavy rain.",
        "A sharp stinger on its head helps defend the leaves it eats in forests and fields.",
        "It remains almost motionless inside a sturdy cocoon while its body transforms.",
        "It attacks in swarms, striking rapidly with the large venomous stingers on its forelegs and tail.",
        "A common woodland bird that uses its keen sense of direction to return home from far away.",
        "It fiercely defends a wide territory and carries prey with its powerful talons.",
        "Its glossy wings and exceptional vision let it hunt at high speed from great altitude.",
        "Small but extremely cautious, it gnaws constantly to keep its fast-growing incisors short.",

        // 020-029
        "Its strong teeth can chew through concrete, and its webbed hind feet help it cross rivers.",
        "A hot-tempered bird that flaps through tall grass to flush out insects.",
        "Its long neck and broad wings support swift, tireless flight across large territories.",
        "It silently moves through grass, unhinging its jaw to swallow prey much larger than itself.",
        "The markings on its hood can intimidate foes, and its coils are strong enough to crush metal.",
        "It stores electricity in red cheek pouches and releases it when threatened.",
        "Its long tail acts as a ground for powerful electrical charges that can knock out large foes.",
        "It curls into a ball when threatened and digs through dry ground with sharp claws.",
        "Its tough hide and long claws let it climb trees and tear through hard earth.",
        "Small and cautious, the female Nidoran uses sensitive ears and venomous barbs for protection.",

        // 030-039
        "Its poison grows stronger as it matures, and its horn develops slowly.",
        "Covered in tough scales, it protects its young with powerful tackles and poisonous spines.",
        "The male Nidoran raises its large ears to detect danger and strikes with a venomous horn.",
        "Quick to anger, it charges enemies with a horn potent enough to pierce stone.",
        "Its muscular body, heavy tail, and sturdy horn make it exceptionally powerful in close combat.",
        "A shy Pokémon associated with moonlight that stores energy in its wing-shaped ears.",
        "It skips lightly across the ground and is said to gather where moonlight is especially bright.",
        "It controls six growing flames and can release fire hot enough to manipulate its surroundings.",
        "Its nine mystical tails are associated with extraordinary intelligence and a very long lifespan.",
        "Its large eyes can lull opponents to sleep before it sings a gentle melody.",

        // 040-049
        "Its soft, elastic body can inflate dramatically, and its fine fur feels exceptionally smooth.",
        "Unable to see, it navigates caves by emitting ultrasonic cries from its mouth.",
        "Its huge mouth and powerful fangs help it drain energy, though bright sunlight weakens it.",
        "It hides underground during the day and spreads seeds as it wanders under moonlight.",
        "A foul-smelling nectar drips from its mouth, attracting prey while discouraging predators.",
        "Its enormous flower scatters clouds of toxic pollen with every heavy step.",
        "Mushrooms on its back draw nutrients from the host and release spores when threatened.",
        "A giant mushroom controls its insect host and prefers damp, dark places.",
        "Fine hair covering its body acts like radar and helps it detect movement in darkness.",
        "Powdery scales from its wings can be poisonous, paralyzing, or sleep-inducing.",

        // 050-059
        "It lives just beneath the soil, leaving only its head visible while feeding on plant roots.",
        "Three Diglett work together underground, causing small earthquakes as they tunnel.",
        "It loves round, shiny objects and collects coins using the charm on its forehead.",
        "A graceful but temperamental hunter whose flexible body allows silent movement.",
        "A constant headache disrupts its psychic power, which bursts out when the pain becomes severe.",
        "A skilled swimmer with webbed limbs and strong psychic abilities focused through its forehead gem.",
        "It becomes furious with little warning and attacks until it has exhausted itself.",
        "Its anger is so intense that it may continue fighting even after losing sight of its target.",
        "Loyal and courageous, it uses an excellent sense of smell to recognize people and territory.",
        "Celebrated for its speed and majesty, it can cover vast distances in a single day.",

        // 060-069
        "Its thin skin reveals a spiral-shaped organ, and its newly grown legs are still poor on land.",
        "It can live on land but prefers water, where its powerful tail helps it swim.",
        "A highly trained swimmer with a muscular body capable of crossing rough seas.",
        "It sleeps most of the day and teleports away when danger approaches.",
        "The spoon it carries amplifies its psychic power, though using that power can cause headaches.",
        "Its exceptional brain performs complex calculations while it uses spoons to focus psychic energy.",
        "It trains by lifting heavy objects and gradually develops a body of solid muscle.",
        "Its powerful physique never tires, and it eagerly helps with demanding physical work.",
        "Four muscular arms let it unleash many punches while performing several tasks at once.",
        "Its slender, flexible body snaps forward quickly to catch insects and small prey.",

        // 070-079
        "It hangs from tree branches and swallows anything that ventures too close.",
        "A patient ambush predator that uses sweet-smelling nectar to lure prey into its large mouth.",
        "Mostly water by weight, it drifts in warm seas and attacks with poisonous tentacles.",
        "Its many tentacles can extend rapidly, trapping prey before delivering a powerful sting.",
        "Often mistaken for a rock, it strengthens its body by climbing steep mountain paths.",
        "It rolls down slopes for transportation, smashing through obstacles with its rocky body.",
        "Its boulder-like shell can withstand explosions, and it sheds the shell once each year.",
        "Its fiery mane appears soon after birth, and its legs become stronger as it learns to run.",
        "It races across fields at tremendous speed while flames stream from its mane and tail.",
        "Slow and carefree, it often forgets what it was doing but has a surprisingly powerful bite.",

        // 080-089
        "A Shellder attached to its tail triggers stronger psychic power and provides sturdy defense.",
        "It floats by manipulating magnetic fields and feeds on electricity from nearby equipment.",
        "Three linked Magnemite generate a strong magnetic field that can disrupt electronics.",
        "It carries a plant stalk like a weapon and bravely protects the plants where it lives.",
        "Its two heads think independently, but both cooperate when running at high speed.",
        "Three distinct heads express joy, sorrow, and anger while coordinating rapid attacks.",
        "Its thick layer of fat and warm fur let it swim comfortably in frigid seas.",
        "It glides through icy water using streamlined fins and stores thermal energy in its body.",
        "Living sludge formed by pollution, it leaves poisonous residue wherever it travels.",
        "Its toxic body grows as it absorbs waste and can overwhelm areas with a terrible stench.",

        // 090-099
        "It closes its hard shell to withstand attacks, then fires sharp spikes at approaching foes.",
        "Layers of shell become harder than diamond, protecting it from almost any physical attack.",
        "A gaseous Pokémon that surrounds targets and weakens them with poisonous vapor.",
        "It slips through walls, hides in shadows, and enjoys startling unsuspecting people.",
        "A mischievous shadow-dweller that absorbs warmth and imitates people to frighten them.",
        "Its immense stone body tunnels underground and grows larger by consuming mineral deposits.",
        "It remembers dreams by their scent and can put opponents to sleep with rhythmic motions.",
        "It swings a pendulum to hypnotize others and is especially skilled at sensing dreams.",
        "Its powerful pincers are useful weapons, though one may grow larger than the other.",
        "Its oversized claw can crush hard shells but is so heavy that it affects balance.",

        // 100-109
        "Often mistaken for a Poké Ball, it discharges electricity or explodes when disturbed.",
        "It stores enormous electrical energy and may explode from even a small shock.",
        "Six seed-like bodies communicate telepathically and gather tightly when threatened.",
        "Its heads think independently and grow best in strong tropical sunlight.",
        "It wears its mother's skull for protection and expresses sadness through mournful cries.",
        "A hardened skull helmet and bone club make it a resilient and disciplined fighter.",
        "Its extendable legs deliver rapid kicks, while its flexible body maintains perfect balance.",
        "It specializes in lightning-fast punches and can twist its arms like drills.",
        "Its long tongue is twice its body length and can wrap around almost anything.",
        "Its thin body contains volatile gases that expand in dirty air and may suddenly explode.",

        // 110-119
        "Two Koffing can fuse into a larger body that mixes gases into powerful toxins.",
        "It charges in a straight line with little concern for obstacles, relying on its armored hide.",
        "Its drill-like horn and immense strength let it smash through boulders and buildings.",
        "A gentle Pokémon that carries a nutritious egg and readily shares it with injured companions.",
        "Blue vines cover its entire body and continue moving even when it stands still.",
        "A protective parent that raises its young in a belly pouch and fights fiercely when necessary.",
        "It swims backward by rapidly firing water from its mouth and uses ink to escape danger.",
        "Sharp fins and a venomous body make it dangerous to touch as it moves through rough currents.",
        "Its elegant fins resemble a dress, but its horn can deliver a forceful attack.",
        "It swims upstream during breeding season, using its horn to clear rocks from its path.",

        // 120-129
        "A star-shaped Pokémon that can regenerate damaged limbs as long as its central core remains.",
        "Its geometric core pulses with energy and sends mysterious signals into the night sky.",
        "A gifted performer that creates invisible walls by carefully controlling its fingertips.",
        "Its blade-like forearms cut through thick objects, and its wings support quick bursts of speed.",
        "It communicates through dance-like movements and can create intense cold around its body.",
        "It thrives near power plants and releases strong currents from its antenna-like horns.",
        "Its body produces intense heat, and flames escape whenever it exhales.",
        "Its powerful horns can lift and crush opponents while its tough body resists attacks.",
        "A restless herd Pokémon that charges using three tails to whip itself into greater speed.",
        "Although physically weak and a poor swimmer, it can survive in almost any body of water.",

        // 130-139
        "Once enraged, it becomes a destructive sea serpent capable of leveling its surroundings.",
        "A gentle sea traveler that understands human speech and carries passengers across the water.",
        "It rearranges its cells to copy another creature's appearance, though imperfect copies can occur.",
        "Its unstable genetic structure allows it to adapt and evolve in several different ways.",
        "Its cells resemble water molecules, allowing it to melt into clean water and become nearly invisible.",
        "Its needle-like fur becomes electrically charged and launches outward when it is threatened.",
        "It stores inhaled air in a flame sac, heating it before releasing scorching fire.",
        "A virtual Pokémon created from programming code that can travel through digital environments.",
        "Revived from a fossil, it uses tentacles and a hard spiral shell to move and hunt in ancient seas.",
        "Its heavy shell and sharp tentacles made it a formidable predator in prehistoric oceans.",

        // 140-149
        "An ancient Pokémon protected by a hard shell, with small eyes adapted to the seafloor.",
        "A swift prehistoric hunter that slashes prey with long, scythe-shaped forelimbs.",
        "A fierce fossil Pokémon that once ruled the skies using broad wings and serrated jaws.",
        "It spends most of its time sleeping and wakes mainly to eat enormous amounts of food.",
        "A legendary bird whose long tail and icy wings are said to bring snowfall.",
        "A legendary bird that lives among storm clouds and gains strength when struck by lightning.",
        "A legendary bird surrounded by flames whose glowing wings can brighten the night sky.",
        "Rare and shy, it grows steadily by shedding its skin and hiding near fast-moving water.",
        "Its crystalline orbs radiate a gentle energy said to influence weather and the surrounding sea.",
        "Despite its large body, it flies with remarkable speed and is known for rescuing people at sea.",

        // 150-151
        "Created through genetic research, it possesses overwhelming psychic power and a guarded nature.",
        "An extremely rare Pokémon whose DNA is said to contain the genetic traits of every Pokémon.",
    ]

    /// Species summary for a national-dex number, or nil when outside Gen 1.
    public static func description(for dex: Int) -> String? {
        guard dexRange.contains(dex) else { return nil }
        return descriptions[dex - 1]
    }
}
