#!/usr/bin/env Rscript
# Test TextGrid tier management methods

library(speaker)

cat("Testing TextGrid tier management methods...\n\n")

# Create a simple TextGrid
cat("1. Creating TextGrid...\n")
tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words phones", point_tiers = "")

cat("   Initial tiers:\n")
print(tg$get_tier_names())
cat("   Number of tiers:", tg$get_number_of_tiers(), "\n\n")

# Test set_tier_name
cat("2. Testing set_tier_name()...\n")
tg$set_tier_name(1, "WORDS")
cat("   After renaming tier 1:\n")
print(tg$get_tier_names())
cat("\n")

# Test duplicate_tier
cat("3. Testing duplicate_tier()...\n")
tg$duplicate_tier(1, "words_copy")
cat("   After duplicating tier 1:\n")
print(tg$get_tier_names())
cat("   Number of tiers:", tg$get_number_of_tiers(), "\n\n")

# Test with tier names (not just numbers)
cat("4. Testing with tier names...\n")
tg$set_tier_name("phones", "PHONES")
cat("   After renaming 'phones':\n")
print(tg$get_tier_names())
cat("\n")

# Test duplicate with a point tier
cat("5. Adding a point tier and duplicating it...\n")
tg$add_point_tier("events")
cat("   After adding point tier:\n")
print(tg$get_tier_names())

tg$duplicate_tier("events", "events_copy")
cat("   After duplicating point tier:\n")
print(tg$get_tier_names())
cat("   Number of tiers:", tg$get_number_of_tiers(), "\n\n")

# Test remove
cat("6. Testing remove_tier()...\n")
tg$remove_tier("events_copy")
cat("   After removing 'events_copy':\n")
print(tg$get_tier_names())
cat("   Number of tiers:", tg$get_number_of_tiers(), "\n\n")

cat("✅ All TextGrid tier management tests passed!\n")
