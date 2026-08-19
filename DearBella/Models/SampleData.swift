import Foundation

/// Hardcoded content used to populate the onboarding grids before TMDB is
/// wired up (Step 4). Genres mirror the wireframe; films are a recognizable
/// starter set. Swapping these for live data later won't touch the views.
enum SampleData {

    static let genres: [Genre] = [
        Genre(id: "horror", name: "Horror"),
        Genre(id: "comedy", name: "Comedy"),
        Genre(id: "rom-com", name: "Rom Com"),
        Genre(id: "sci-fi", name: "Sci Fi"),
        Genre(id: "indie", name: "Indie"),
        Genre(id: "drama", name: "Drama"),
        Genre(id: "superhero", name: "Superhero"),
        Genre(id: "action", name: "Action"),
        Genre(id: "thriller", name: "Thriller"),
        Genre(id: "animation", name: "Animation"),
        Genre(id: "documentary", name: "Documentary"),
        Genre(id: "fantasy", name: "Fantasy"),
        Genre(id: "mystery", name: "Mystery"),
        Genre(id: "musical", name: "Musical"),
        Genre(id: "crime", name: "Crime"),
        Genre(id: "western", name: "Western"),
    ]

    static let films: [SampleFilm] = [
        SampleFilm(id: "godfather", title: "The Godfather", year: 1972),
        SampleFilm(id: "pulp-fiction", title: "Pulp Fiction", year: 1994),
        SampleFilm(id: "moonlight", title: "Moonlight", year: 2016),
        SampleFilm(id: "truman-show", title: "The Truman Show", year: 1998),
        SampleFilm(id: "green-book", title: "Green Book", year: 2018),
        SampleFilm(id: "hamilton", title: "Hamilton", year: 2020),
        SampleFilm(id: "die-hard", title: "Die Hard", year: 1988),
        SampleFilm(id: "amelie", title: "Amélie", year: 2001),
        SampleFilm(id: "eternal-sunshine", title: "Eternal Sunshine of the Spotless Mind", year: 2004),
        SampleFilm(id: "toy-story", title: "Toy Story", year: 1995),
        SampleFilm(id: "inglourious-basterds", title: "Inglourious Basterds", year: 2009),
        SampleFilm(id: "the-shining", title: "The Shining", year: 1980),
        SampleFilm(id: "parasite", title: "Parasite", year: 2019),
        SampleFilm(id: "django", title: "Django Unchained", year: 2012),
        SampleFilm(id: "psycho", title: "Psycho", year: 1960),
        SampleFilm(id: "lady-bird", title: "Lady Bird", year: 2017),
        SampleFilm(id: "blade-runner", title: "Blade Runner 2049", year: 2017),
        SampleFilm(id: "spirited-away", title: "Spirited Away", year: 2001),
        SampleFilm(id: "whiplash", title: "Whiplash", year: 2014),
        SampleFilm(id: "get-out", title: "Get Out", year: 2017),
        SampleFilm(id: "grand-budapest", title: "The Grand Budapest Hotel", year: 2014),
        SampleFilm(id: "social-network", title: "The Social Network", year: 2010),
        SampleFilm(id: "mad-max", title: "Mad Max: Fury Road", year: 2015),
        SampleFilm(id: "la-la-land", title: "La La Land", year: 2016),
        SampleFilm(id: "the-proposal", title: "The Proposal", year: 2009),
        SampleFilm(id: "interstellar", title: "Interstellar", year: 2014),
        SampleFilm(id: "it", title: "It", year: 2017),
        SampleFilm(id: "kill-bill", title: "Kill Bill: Vol. 1", year: 2003),
    ]

    /// A starter set of directors for the onboarding pick, chosen to span eras,
    /// countries and scales — a list that's only Hollywood in the last twenty
    /// years teaches Bella that's all there is. Portraits are resolved from
    /// TMDB at runtime by `MovieCatalog`, so nothing here needs an image.
    static let directors: [Director] = [
        Director(id: "greta-gerwig", name: "Greta Gerwig", knownFor: "Lady Bird"),
        Director(id: "bong-joon-ho", name: "Bong Joon-ho", knownFor: "Parasite"),
        Director(id: "wes-anderson", name: "Wes Anderson", knownFor: "The Grand Budapest Hotel"),
        Director(id: "jordan-peele", name: "Jordan Peele", knownFor: "Get Out"),
        Director(id: "sofia-coppola", name: "Sofia Coppola", knownFor: "Lost in Translation"),
        Director(id: "denis-villeneuve", name: "Denis Villeneuve", knownFor: "Blade Runner 2049"),
        Director(id: "quentin-tarantino", name: "Quentin Tarantino", knownFor: "Pulp Fiction"),
        Director(id: "martin-scorsese", name: "Martin Scorsese", knownFor: "Goodfellas"),
        Director(id: "celine-sciamma", name: "Céline Sciamma", knownFor: "Portrait of a Lady on Fire"),
        Director(id: "christopher-nolan", name: "Christopher Nolan", knownFor: "Interstellar"),
        Director(id: "barry-jenkins", name: "Barry Jenkins", knownFor: "Moonlight"),
        Director(id: "hayao-miyazaki", name: "Hayao Miyazaki", knownFor: "Spirited Away"),
        Director(id: "ari-aster", name: "Ari Aster", knownFor: "Hereditary"),
        Director(id: "paul-thomas-anderson", name: "Paul Thomas Anderson", knownFor: "There Will Be Blood"),
        Director(id: "chloe-zhao", name: "Chloé Zhao", knownFor: "Nomadland"),
        Director(id: "spike-lee", name: "Spike Lee", knownFor: "Do the Right Thing"),
        Director(id: "yorgos-lanthimos", name: "Yorgos Lanthimos", knownFor: "The Favourite"),
        Director(id: "david-fincher", name: "David Fincher", knownFor: "The Social Network"),
        Director(id: "wong-kar-wai", name: "Wong Kar-wai", knownFor: "In the Mood for Love"),
        Director(id: "stanley-kubrick", name: "Stanley Kubrick", knownFor: "The Shining"),
        Director(id: "guillermo-del-toro", name: "Guillermo del Toro", knownFor: "Pan's Labyrinth"),
        Director(id: "jane-campion", name: "Jane Campion", knownFor: "The Power of the Dog"),
        Director(id: "luca-guadagnino", name: "Luca Guadagnino", knownFor: "Call Me by Your Name"),
        Director(id: "steven-spielberg", name: "Steven Spielberg", knownFor: "Jaws"),
        Director(id: "lynne-ramsay", name: "Lynne Ramsay", knownFor: "You Were Never Really Here"),
        Director(id: "alfonso-cuaron", name: "Alfonso Cuarón", knownFor: "Roma"),
        Director(id: "david-lynch", name: "David Lynch", knownFor: "Mulholland Drive"),
        Director(id: "agnes-varda", name: "Agnès Varda", knownFor: "Cléo from 5 to 7"),
        Director(id: "sean-baker", name: "Sean Baker", knownFor: "The Florida Project"),
        Director(id: "ryan-coogler", name: "Ryan Coogler", knownFor: "Fruitvale Station"),
        Director(id: "akira-kurosawa", name: "Akira Kurosawa", knownFor: "Seven Samurai"),
        Director(id: "pedro-almodovar", name: "Pedro Almodóvar", knownFor: "All About My Mother"),
        Director(id: "andrea-arnold", name: "Andrea Arnold", knownFor: "American Honey"),
        Director(id: "alfred-hitchcock", name: "Alfred Hitchcock", knownFor: "Psycho"),
    ]
}
