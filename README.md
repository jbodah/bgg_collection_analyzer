# BggCollectionAnalyzer

a collection analyzer for boardgamegeeks users

## Usage

This gem provides an easy to use interface for querying your collection.
For example, I can find all of the games that I own that have a medium
weight and are recommended with two, and then I can sort those by my rating
(note: `nil.to_i => 0` and represents unrated games):

```rb
bin/console
irb> pp collection.owned.board_game.recommended_with_two.medium.map { |g| [g.user_rating.to_i, g.name] }.sort_by(&:first).reverse
[[10, "Ghost Stories"],
 [9, "Freedom: The Underground Railroad"],
 [9, "Pandemic Legacy: Season 1"],
 [9, "Suburbia"],
 [8, "Race for the Galaxy"],
 [8, "Dominion"],
 [8, "Gears of War: The Board Game"],
 [7, "Seasons"],
 [7, "Hive"],
 [7, "Hawaii"],
 [7, "Ristorante Italia"],
 [7, "Epic Card Game"],
 [7, "Mottainai"],
 [7, "Innovation"],
 [6, "Thunderstone Advance: Numenera"],
 [6, "Pandemic"],
 [3, "Space Hulk: Death Angel – The Card Game"],
 [0, "Thunderstone Advance: Towers of Ruin"],
 [0, "Targi"],
 [0, "Sherlock Holmes Consulting Detective"],
 [0, "Seeland"],
 [0, "Poseidon's Kingdom"],
 [0, "Legacy: Gears of Time"],
 [0, "Istanbul"],
 [0, "Horse Fever"],
 [0, "Glory to Rome"],
 [0, "Empire Builder"],
 [0, "Copycat"]]
```

Take a peek at `BggCollectionAnalyzer`, `Bgg::Result::Collection::Item`, and
`Bgg::Game` for more options
