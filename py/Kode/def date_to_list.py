# def date_to_list(date_str):
#     year, month, day = map(int, date_str.split("-"))
#     return [year, month, day]

# # Example usage# input_date = input()
# print(type(date_to_list(input_date)))

#-----------------------------

def date2list(date):
    datelist = []
    d = " "
    for i in range(len(date)):
        # Do not add the '-', append d to list and reset var d
        if date[i] == "-":
            datelist.append(d)
            d = " "
        # Check if last element of date input
        elif i == len(date)-1:
            d += date[i]
            datelist.append(d)
        # Else concatenate chars for YYYY, MM, and DD
        else:
            d += date[i]
    return datelist

date = input("Enter a date in the format of YYYY-MM-DD: ")
my_list = date2list(date)
print(my_list)
