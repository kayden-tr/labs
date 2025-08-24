print("Welcome to the Daily Expense Tracker!")

# Display menu once
print("\nMenu:")
print("1. Add a new expense")
print("2. View all expenses")
print("3. Calculate total and average expense")
print("4. Clear all expenses")
print("5. Exit")
expenses = []
while True:
    # Get user choice
    choice = input("Enter your choice from menu: ")
    if choice == "1":
        amount = float(input())
        expenses.append(amount)
        print("Expense added successfully!")
    if choice == "2":
        if len(expenses) == 0 :
            print("No expenses recorded yet.")
        else:
            print("Your expenses: ")
            for i in range(len(expenses)):
                print(f"{i + 1}. {expenses[i]}")
    if choice == "5":
        # Exit the program
        print("Exiting the Daily Expense Tracker. Goodbye!")
        break