# Opportunity Dataset — Data Cleaning Documentation

## Overview
- Raw file: Copy_of__Opportunity_Data_-_Sheet1.csv
- Raw shape: 5,733 rows x 33 columns
- Cleaned shape: 5730 rows x 32 columns
- Grain: one row = one Opportunity (Internship, Course, Career, Competition, etc.)

## Issues Found and How They Were Fixed

1. **Structurally corrupted rows** (3 rows): unescaped JSON in tracking_questions
   broke the CSV column alignment. Dropped as unrecoverable.

2. **Invalid category values**: turned out to be the same 3 corrupted rows -
   resolved automatically once those rows were dropped.

3. **Location inconsistency**: casing/spelling variants (virtual/Virtual/vitrual,
   wfm/WFM/work from home) collapsed into 2 clean values. Also found and fixed
   a hidden bug where "Null" (title case) slipped past our first missing-value
   cleanup because it only checked for "NULL"/"null" exactly.

4. **Duration_type inconsistency**: 17 variants (week/weeks/yearssss/etc.)
   mapped down to 6 standard units. One ambiguous value ("da") was resolved
   using context (duration=1, event-type opportunity) rather than guessed blindly.

5. **Role inconsistency**: 429 unique values, mostly placeholder text ("role")
   and gibberish test entries. Used a whitelist strategy - mapped known real
   roles, nulled everything else, rather than trying to clean each junk value.

6. **Currency_type inconsistency**: EURO merged into EUR.

7. **Wrong data types**: created_at/modified_at/last_date_to_apply converted
   from epoch-milliseconds to real dates (one fake 1970 placeholder date fixed).
   fee/duration/microscholarship converted to numeric (one 6-trillion fake fee,
   tied to a record literally named "Testing auto approve", set to missing).
   is_archived/is_auto_approve converted to real booleans.

8. **Text quality**: HTML tags stripped from description fields (11 rows).
   Broken apostrophes repaired, e.g. "today?s" -> "today's" (7 rows).

9. **Test/QA data contamination**: 397 rows (6.9% of the dataset) identified
   as internal test entries via name pattern matching and empty-core-field
   detection. Flagged with is_likely_test_data rather than deleted, since
   deletion risks losing real data if the heuristic is imperfect.

10. **Nested JSON relationship columns**: 9 columns (Badge, Cohort, Eligibility,
    Reward, Testimonial, etc.) held raw JSON pointing to other tables - not
    usable for direct analysis. Converted to has_x boolean flags or num_x
    counts. Original JSON preserved in opportunity_raw_json_reference.csv,
    keyed by opportunity_id.

11. **Low-value columns**: pk (constant after row cleanup) and current_editor
    (96% missing, internal admin metadata) dropped.

## Known Limitations
- is_likely_test_data is a heuristic, not exhaustive - some Lorem-Ipsum-style
  test rows may still be uncaught.
- is_archived is left as missing/unknown for 90% of rows rather than assumed
  False - a documented choice, not a certainty.
- Mojibake repair only targets the apostrophe pattern; other corruption types
  weren't systematically searched for.
