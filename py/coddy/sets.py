# Read input for the three matches
match1 = eval(input())
match2 = eval(input())
match3 = eval(input())

# 1. Find players who participated in all three matches
all_matches= match1 & match2 & match3
# 2. Find players who participated in exactly two matches
in_two_matches =   ((match1 & match3) | (match1 & match2) | (match2 & match3)) - all_matches 
# 3. Find players who participated in only one match
only_one_match= (
    (match1 - match2 - match3)
    | (match2 - match1 - match3)
    | (match3 - match1 - match2)
)

# 4. Count total unique players
total_participant=len(match1 | match2 | match3)
# 5. Find players in Match 1 only
layers_in_match1_only = match1 - match2 - match3
# Print results in the specified format
print(
f'''
Players in all matches: {sorted(list(all_matches))}
Players in exactly two matches: {sorted(list(in_two_matches))}
Players in only one match: {sorted(list(only_one_match))}
Total unique players: {total_participant}
Players in Match 1 only: {sorted(list(layers_in_match1_only))}
'''
)