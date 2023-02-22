# SwedishPNR

Parse and verify Swedish personal identity numbers, "personnummer" in Swedish, or PNR for short in this library.

## What's in a number?

The Swedish Tax Agency ("Skatteverket" in Swedish) has a [description of the format](https://skatteverket.se/privat/folkbokforing/personnummer.4.3810a01c150939e893f18c29.html), but it basically boils down to this:

* A PNR comprises 10 digits and a separator on the form `yyMMdd-nnnc`
  where `yyMMdd` denotes the date of birth,
  `nnn` is a sequence number called "birth number",
  and `c` is a checksum of the previous nine digits.

* The date of birth of a PNR lacks its century! So, the actual date of birth has to be deduced relative a reference date. In all normal uses, that reference date is today. Right now.

* Temporary PNRs called coordination numbers ("sammordningsnummer" in Swedish) can be issued to people not listed in the Swedish Population Register (an unlisted person is not "folkbokförd" in Swedish). These numbers follow the same rules as normal PNRs but have the number 60 added to the day number (`dd` in the format above).

* When a person reaches the honorable age of 100 years, a plus sign (`+`) is used for the separator in their PNR, i.e., `yyMMdd+nnnc`.

* Although the standard form of a PNR is the eleven character version described so far, other forms are also in common use. This library handles PNRs on the following forms. Note that the last two forms include the century, so no deduction is necessary, neither is the plus separator allowed; unsurprisingly these forms are popular, if not required in many apps and sites today.

    * 10 characters: `yyMMddnnnc` (standard form but lacking separator)
    * 11 characters: `yyMMdd-nnnc` (the "standard" form)
    * 11 characters: `yyMMdd+nnnc` (centennials)
    * 12 characters: `yyyyMMddnnnc`
    * 13 characters: `yyyyMMdd-nnnc`

Other curiosities:

* As there are only 999 distinct birth numbers available for a given date, Skatteverket may run out of numbers! If that's the case identity numbers will apparently be selected from neighbouring dates. Thus, some people have PNRs with dates of birth that aren't their actual dates of birth.

## Usage


