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
    ]
}
