# SwedishPNR

Parse and verify Swedish personal identity numbers, "personnummer" in Swedish, or PNR for short in this library.

## What's in a number?

The Swedish Tax Agency ("Skatteverket" in Swedish) has a [description of the format](https://skatteverket.se/privat/folkbokforing/personnummer.4.3810a01c150939e893f18c29.html), but it basically boils down to this:

* A PNR comprises 10 digits and a separator on the form `yyMMdd-nnnc`
  where `yyMMdd` denotes the date of birth,
  `nnn` is a sequence number called "birth number",
  and `c` is a checksum of the previous nine digits.

* The date of birth of a PNR lacks its century! So, the actual date of birth has to be deduced relative a reference date. In all normal uses, that reference date is today. Right now.

* Temporary PNRs called coordination numbers ("sammordningsnummer" in Swedish) can be issued to people not listed in the Swedish Population Register. A listed person is "folkbokförd" in Swedish; an unlisted person is... not "folkbokförd"... umm, let's move on. These numbers follow the same rules as normal PNRs but have the number 60 added to the day number (`dd` in the format above).

* When a person reaches the honorable age of 100 years, a plus sign (`+`) is used for the separator in their PNR, i.e., `yyMMdd+nnnc`.

* Although the standard form of a PNR is the eleven character version described so far, other forms are also in common use. This library handles PNRs on the following forms. Note that the last two forms include the century, so no deduction is necessary, neither is the plus separator allowed; unsurprisingly these forms are popular, if not required in many apps and sites today.

    * 10 characters: `yyMMddnnnc` (standard form but lacking separator)
    * 11 characters: `yyMMdd-nnnc` (the "standard" form)
    * 11 characters: `yyMMdd+nnnc` (centennials)
    * 12 characters: `yyyyMMddnnnc`
    * 13 characters: `yyyyMMdd-nnnc`

Other curiosities:

* As there are only 999 distinct birth numbers available[^available_birth_numbers] for a given date, Skatteverket may run out of numbers! If that's the case identity numbers will apparently be selected from neighbouring dates. Thus, some people have PNRs with dates of birth that aren't their actual dates of birth.

* Because the century is not part of the PNR, it is also not included in the checksum calculation. Two PNRs of the longer form that differ only by a century (or a multiple thereof) have identical checksums. Don't skip the age check!

* Speaking of age, short form PNRs can't be used for really, _really_ old people. Sorry, [Bicentennial Man](https://en.wikipedia.org/wiki/The_Bicentennial_Man).

[^available_birth_numbers]: There may very well be fewer birth numbers available as some might be reserved or excluded. I've not found a definite list. Skatteverket may know.


## Getting started

To make use of this library, declare a dependency in your Package.swift:

```
// 🇸🇪 Swedish personal identity number validation
.package(url: "https://github.com/Oops-AB/swedish-pnr.git", from: "1.0.0"),
```

and to your target:

```
.executableTarget(name: "Smorgasbord", dependencies: [
    .product(name: "SwedishPNR", package: "swedish-pnr")
],
```

Let's get going:

```
let pnr = try! SwedishPNR.parse(input: "  20171210-0005\t")
print("\(pnr.normalized)")
```

Output

```
20171210-0005
```

The `parse()` function either returns a PNR or throws a `Parser.ParseError` .


### The `SwedishPNR` type

A successful parse returns a `SwedishPNR`. This type has a few properties:

* `input` is the original string, including leading or trailing space,
* `normalized` is the full, 13 character version of the PNR,
* `birthDateComponents` is a `DateComponents` instance holding `year`, `month` and `day`,
* `birthDate` is a `Date` instance representing the first instant of the birth date _in the Sweden time zone_.

The `SwedishPNR` also has a method `age(at:) -> Int` that calculates the age relative a reference date (which defaults to now).

Note that all date calculations (age and deducing century) are performed in the Sweden time zone.
