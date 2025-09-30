tup = 1, 2, 3, 2, 4, 5, 6, 2, 7, 2, 8, 9
duplicates = []

for i in range(len(tup)-1):
    if tup[i] in tup[i+1:]:
        duplicates.append(tup[i])
print(duplicates)